// lib/presentation/widgets/theme_selector_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return AlertDialog(
      title: const Text('Выбор темы'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeTile(
              context,
              themeProvider,
              AppThemeType.light,
              currentTheme,
              Icons.wb_sunny,
              Colors.amber,
            ),
            _buildThemeTile(
              context,
              themeProvider,
              AppThemeType.dark,
              currentTheme,
              Icons.nightlight_round,
              Colors.indigo,
            ),
            const Divider(),
            _buildThemeTile(
              context,
              themeProvider,
              AppThemeType.ocean,
              currentTheme,
              Icons.water,
              Colors.cyan,
            ),
            _buildThemeTile(
              context,
              themeProvider,
              AppThemeType.forest,
              currentTheme,
              Icons.park,
              Colors.green,
            ),
            _buildThemeTile(
              context,
              themeProvider,
              AppThemeType.sunset,
              currentTheme,
              Icons.wb_twilight,
              Colors.orange,
            ),
            _buildThemeTile(
              context,
              themeProvider,
              AppThemeType.lavender,
              currentTheme,
              Icons.spa,
              Colors.purple,
            ),
            _buildThemeTile(
              context,
              themeProvider,
              AppThemeType.midnight,
              currentTheme,
              Icons.nightlife,
              Colors.deepPurple,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    ThemeProvider provider,
    AppThemeType type,
    AppThemeType current,
    IconData icon,
    Color color,
  ) {
    final isSelected = current == type;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(type.displayName),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      selected: isSelected,
      selectedTileColor: Colors.green.withOpacity(0.1),
      onTap: () {
        provider.setTheme(type);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тема изменена на "${type.displayName}"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
