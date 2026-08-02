// lib/presentation/screens/persons_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/widgets/persons/person_form_launcher.dart';
import 'package:nm_gen/presentation/widgets/persons/persons_debug_info_dialog.dart';
import 'package:nm_gen/presentation/widgets/persons/persons_list_view.dart';

/// Экран списка людей дерева.
///
/// По аналогии с person_detail_screen.dart: этот файл владеет блоками
/// (PersonBloc/MediaBloc) и их жизненным циклом, рисует Scaffold (AppBar +
/// FAB), а вся содержательная логика - список с состояниями, действия по
/// свайпу, диалоги - вынесена в отдельные виджеты
/// (widgets/persons/*), этот файл их только связывает.
class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key, required this.treeId});
  final String treeId;

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  late final PersonBloc _personBloc;
  late final MediaBloc _mediaBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    try {
      _personBloc = getIt<PersonBloc>();
      _mediaBloc = getIt<MediaBloc>();
    } catch (e) {
      debugPrint('❌ PersonsScreen: Ошибка получения BLoC: $e');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        try {
          _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
        } catch (e) {
          debugPrint('❌ PersonsScreen: Ошибка отправки LoadPersonsEvent: $e');
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant PersonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeId != widget.treeId) {
      try {
        _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
      } catch (e) {
        debugPrint(
          '❌ PersonsScreen: Ошибка отправки LoadPersonsEvent при смене treeId: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _personBloc),
          BlocProvider.value(value: _mediaBloc),
        ],
        child: _buildScaffold(context),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ PersonsScreen: Критическая ошибка в build: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Персоны'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Поиск',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _personBloc.add(LoadPersonsEvent(treeId: widget.treeId));
            },
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => showPersonsDebugInfoDialog(
              context,
              treeId: widget.treeId,
              state: _personBloc.state,
              mounted: mounted,
              isInitialized: _isInitialized,
              onReload: () =>
                  _personBloc.add(LoadPersonsEvent(treeId: widget.treeId)),
            ),
            tooltip: 'Отладка',
          ),
        ],
      ),
      body: PersonsListView(treeId: widget.treeId),
      floatingActionButton: FloatingActionButton(
        // heroTag: null отключает Hero-обёртку для этого FAB - иначе он
        // сталкивается тегами с FAB на других экранах, которые остаются
        // смонтированными (просто невидимыми) в стеке Navigator, когда
        // поверх открывается любой другой route (в т.ч. диалог).
        heroTag: null,
        onPressed: () => showAddPersonDialog(
          context,
          personBloc: _personBloc,
          treeId: widget.treeId,
        ),
        tooltip: 'Добавить человека',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Поиск людей'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите имя или фамилию...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              _personBloc.add(
                SearchPersonsEvent(query, treeId: widget.treeId),
              );
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}