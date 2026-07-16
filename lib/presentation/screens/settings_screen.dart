import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: <_SettingsSection>[
          const _SettingsSection(
            title: 'Внешний вид',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode,
                title: 'Темная тема',
                subtitle: 'Включить темную тему',
                trailing: Switch(value: false, onChanged: null),
              ),
              _SettingsTile(
                icon: Icons.palette,
                title: 'Цветовая схема',
                subtitle: 'Выберите основной цвет приложения',
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
          const _SettingsSection(
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
              ),
            ],
          ),
          const _SettingsSection(
            title: 'О приложении',
            children: [
              _SettingsTile(
                icon: Icons.info,
                title: 'Версия',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.code,
                title: 'Разработчик',
                subtitle: 'Genealogy App Team',
              ),
            ],
          ),
        ],
      ),
    );
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
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: trailing,
      onTap: trailing != null ? () {} : null,
    );
  }
}
