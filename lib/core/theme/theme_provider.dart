// lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';

  AppThemeType _currentTheme = AppThemeType.light;

  ThemeProvider() {
    _loadTheme();
  }

  AppThemeType get currentTheme => _currentTheme;

  ThemeData get themeData => AppTheme.getTheme(_currentTheme);

  /// Переключение темы
  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    await _saveTheme();
    notifyListeners();
  }

  /// Загрузка темы из SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);
      if (themeName != null) {
        _currentTheme = AppThemeType.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => AppThemeType.light,
        );
      }
    } catch (e) {
      // Если ошибка - оставляем светлую тему
    }
    notifyListeners();
  }

  /// Сохранение темы в SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _currentTheme.name);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }
}
