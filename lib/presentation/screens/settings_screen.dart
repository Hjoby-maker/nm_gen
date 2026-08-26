// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/use_cases/clear_all_data.dart';
import 'package:nm_gen/presentation/blocs/family/family_bloc.dart';
import 'package:nm_gen/presentation/blocs/family/family_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/project/project_bloc.dart';
import 'package:nm_gen/presentation/blocs/project/project_event.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_bloc.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_event.dart';
import 'package:nm_gen/presentation/widgets/theme_selector_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: const <Widget>[
          _SettingsSection(
            title: 'Внешний вид',
            children: [
              _SettingsTile(
                icon: Icons.palette,
                title: 'Цветовая схема',
                subtitle: 'Выберите цветовую схему приложения',
                trailing: Icon(Icons.chevron_right),
                isThemeSelector: true,
              ),
            ],
          ),
          _SettingsSection(
            title: 'Данные',
            children: [
              _SettingsTile(
                icon: Icons.backup,
                title: 'Экспорт данных',
                subtitle: 'Создать резервную копию',
                trailing: Icon(Icons.chevron_right),
              ),
              _SettingsTile(
                icon: Icons.restore,
                title: 'Импорт данных',
                subtitle: 'Восстановить из резервной копии',
                trailing: Icon(Icons.chevron_right),
              ),
              _SettingsTile(
                icon: Icons.delete_sweep,
                title: 'Очистить все данные',
                subtitle: 'Удалить все древа и персоны',
                trailing: Icon(Icons.chevron_right, color: Colors.red),
                isDeleteAction: true,
              ),
            ],
          ),
          _SettingsSection(
            title: 'О приложении',
            children: [
              _SettingsTile(
                icon: Icons.info,
                title: 'Версия',
                subtitle: '0.0.10',
              ),
              _SettingsTile(
                icon: Icons.code,
                title: 'Разработчик',
                subtitle: 'Hjoby Team',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Удаление всех данных'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы уверены, что хотите удалить все данные приложения?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Будут удалены:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text('• Все персоны'),
            Text('• Все семьи'),
            Text('• Все события'),
            Text('• Все проекты/древа'),
            Text('• Все фотографии и файлы'),
            SizedBox(height: 12),
            Text(
              '⚠️ Это действие необратимо!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить все'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Очистка данных...'),
          ],
        ),
      ),
    );

    try {
      final clearAllDataUseCase = getIt<ClearAllDataUseCase>();
      final result = await clearAllDataUseCase.execute();

      if (context.mounted) Navigator.pop(context);

      result.fold(
        (failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${failure.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        (_) {
          _refreshAllBlocs(context);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Все данные успешно очищены'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка при очистке данных: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _refreshAllBlocs(BuildContext context) {
    try {
      const treeId = 'default';

      final projectBloc = getIt<ProjectBloc>();
      projectBloc.add(LoadProjectsEvent());

      final personBloc = getIt<PersonBloc>();
      personBloc.add(LoadPersonsEvent(treeId: treeId));

      final familyBloc = getIt<FamilyBloc>();
      familyBloc.add(LoadAllFamiliesEvent(treeId: treeId));

      final treeBloc = getIt<TreeBloc>();
      treeBloc.add(LoadTreeEvent('', treeId: treeId));
    } catch (_) {}
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isThemeSelector = false,
    this.isDeleteAction = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isThemeSelector;
  final bool isDeleteAction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDeleteAction ? Colors.red : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDeleteAction ? Colors.red : null),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDeleteAction ? Colors.red.shade300 : Colors.grey.shade500,
        ),
      ),
      trailing: trailing,
      onTap: isThemeSelector
          ? () => showDialog(
              context: context,
              builder: (_) => const ThemeSelectorDialog(),
            )
          : isDeleteAction
          ? () {
              final settings = context
                  .findAncestorWidgetOfExactType<SettingsScreen>();
              settings?._showClearDataConfirmationDialog(context);
            }
          : trailing != null
          ? () {}
          : null,
    );
  }
}
