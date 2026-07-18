import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Provider managing the theme mode (light vs dark) for the application.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // افتراضياً المظهر الداكن الفاخر

  ThemeProvider() {
    // مزامنة حالة السمة الافتراضية
    AppTheme.isDark = _themeMode == ThemeMode.dark;
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppTheme.isDark = isDark;
    notifyListeners();
  }
}
