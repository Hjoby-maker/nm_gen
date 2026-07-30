// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Доступные темы
enum AppThemeType {
  light('Светлая'),
  dark('Темная'),
  ocean('Океан'),
  forest('Лес'),
  sunset('Закат'),
  lavender('Лаванда'),
  midnight('Полночь');

  const AppThemeType(this.displayName);
  final String displayName;
}

/// Конфигурация темы
class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return _lightTheme;
      case AppThemeType.dark:
        return _darkTheme;
      case AppThemeType.ocean:
        return _oceanTheme;
      case AppThemeType.forest:
        return _forestTheme;
      case AppThemeType.sunset:
        return _sunsetTheme;
      case AppThemeType.lavender:
        return _lavenderTheme;
      case AppThemeType.midnight:
        return _midnightTheme;
    }
  }

  // Базовые цвета
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _primaryGreenLight = Color(0xFF4CAF50);
  static const Color _primaryGreenDark = Color(0xFF1B5E20);

  // Общие настройки CardThemeData
  static CardThemeData get _cardThemeData => const CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // ========== СВЕТЛАЯ ТЕМА ==========
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryGreen,
      brightness: Brightness.light,
      primary: _primaryGreen,
      surface: Colors.white,
      background: Colors.grey.shade50,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: _cardThemeData,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _primaryGreen,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey.shade50,
  );

  // ========== ТЕМНАЯ ТЕМА ==========
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryGreenLight,
      brightness: Brightness.dark,
      primary: _primaryGreenLight,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      color: Color(0xFF2D2D2D),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryGreenLight,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _primaryGreenLight,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      backgroundColor: Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );

  // ========== ОКЕАН ==========
  static final ThemeData _oceanTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF006064),
      onPrimary: Colors.white,
      secondary: Color(0xFF00838F),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFFE0F7FA),
      onBackground: Color(0xFF004D40),
      surface: Colors.white,
      onSurface: Color(0xFF004D40),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF006064),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: _cardThemeData,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00838F),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF006064),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFFE0F7FA),
  );

  // ========== ЛЕС ==========
  static final ThemeData _forestTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF33691E),
      onPrimary: Colors.white,
      secondary: Color(0xFF558B2F),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFFF1F8E9),
      onBackground: Color(0xFF1B3A1B),
      surface: Colors.white,
      onSurface: Color(0xFF1B3A1B),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF33691E),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: _cardThemeData,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF558B2F),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF33691E),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFFF1F8E9),
  );

  // ========== ЗАКАТ ==========
  static final ThemeData _sunsetTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFD84315),
      onPrimary: Colors.white,
      secondary: Color(0xFFBF360C),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFFFFF3E0),
      onBackground: Color(0xFF4E342E),
      surface: Colors.white,
      onSurface: Color(0xFF4E342E),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFFD84315),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: _cardThemeData,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFBF360C),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFFD84315),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFFFFF3E0),
  );

  // ========== ЛАВАНДА ==========
  static final ThemeData _lavenderTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6A1B9A),
      onPrimary: Colors.white,
      secondary: Color(0xFF8E24AA),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFFF3E5F5),
      onBackground: Color(0xFF311B92),
      surface: Colors.white,
      onSurface: Color(0xFF311B92),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF6A1B9A),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: _cardThemeData,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF8E24AA),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF6A1B9A),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFFF3E5F5),
  );

  // ========== ПОЛНОЧЬ ==========
  static final ThemeData _midnightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF5C6BC0),
      onPrimary: Colors.white,
      secondary: Color(0xFF7986CB),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFF0D0D1A),
      onBackground: Color(0xFFE8EAF6),
      surface: Color(0xFF1A1A2E),
      onSurface: Color(0xFFE8EAF6),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      color: Color(0xFF2D2D44),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF5C6BC0),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF5C6BC0),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      backgroundColor: Color(0xFF1A1A2E),
    ),
    scaffoldBackgroundColor: Color(0xFF0D0D1A),
  );
}
