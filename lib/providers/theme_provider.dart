import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Provider managing the theme mode (light vs dark) for the application.
/// Supports a custom time-based smart scheduler for automatic theme transitions.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _useSmartTheme = false;
  TimeOfDay _lightStartTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _darkStartTime = const TimeOfDay(hour: 18, minute: 0);
  Timer? _timer;

  ThemeProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode {
    if (_useSmartTheme) {
      return _calculateSmartIsDark() ? ThemeMode.dark : ThemeMode.light;
    }
    return _themeMode;
  }

  bool get isDarkMode {
    if (_useSmartTheme) {
      return _calculateSmartIsDark();
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get useSmartTheme => _useSmartTheme;
  TimeOfDay get lightStartTime => _lightStartTime;
  TimeOfDay get darkStartTime => _darkStartTime;

  void toggleTheme(bool isDark) {
    if (_useSmartTheme) {
      // Disabling smart theme if manually toggled
      _useSmartTheme = false;
      _saveBoolToPrefs('use_smart_theme', false);
    }
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppTheme.isDark = isDark;
    _saveBoolToPrefs('is_dark_theme', isDark);
    notifyListeners();
  }

  void setUseSmartTheme(bool value) {
    _useSmartTheme = value;
    AppTheme.isDark = isDarkMode;
    _saveBoolToPrefs('use_smart_theme', value);
    if (value) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
    notifyListeners();
  }

  void setLightStartTime(TimeOfDay time) {
    _lightStartTime = time;
    _saveTimeToPrefs('light_start_hour', 'light_start_minute', time);
    if (_useSmartTheme) {
      AppTheme.isDark = isDarkMode;
    }
    notifyListeners();
  }

  void setDarkStartTime(TimeOfDay time) {
    _darkStartTime = time;
    _saveTimeToPrefs('dark_start_hour', 'dark_start_minute', time);
    if (_useSmartTheme) {
      AppTheme.isDark = isDarkMode;
    }
    notifyListeners();
  }

  bool _calculateSmartIsDark() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final lightMinutes = _lightStartTime.hour * 60 + _lightStartTime.minute;
    final darkMinutes = _darkStartTime.hour * 60 + _darkStartTime.minute;

    if (darkMinutes > lightMinutes) {
      // Light mode during the day: e.g. 06:00 to 18:00
      return currentMinutes < lightMinutes || currentMinutes >= darkMinutes;
    } else {
      // Light mode overnight: e.g. 18:00 to 06:00
      return currentMinutes >= darkMinutes && currentMinutes < lightMinutes;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_useSmartTheme) {
        final currentDark = _calculateSmartIsDark();
        if (AppTheme.isDark != currentDark) {
          AppTheme.isDark = currentDark;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _useSmartTheme = prefs.getBool('use_smart_theme') ?? false;
      
      final isDarkTheme = prefs.getBool('is_dark_theme') ?? true;
      _themeMode = isDarkTheme ? ThemeMode.dark : ThemeMode.light;

      final lightHour = prefs.getInt('light_start_hour') ?? 6;
      final lightMinute = prefs.getInt('light_start_minute') ?? 0;
      _lightStartTime = TimeOfDay(hour: lightHour, minute: lightMinute);

      final darkHour = prefs.getInt('dark_start_hour') ?? 18;
      final darkMinute = prefs.getInt('dark_start_minute') ?? 0;
      _darkStartTime = TimeOfDay(hour: darkHour, minute: darkMinute);

      AppTheme.isDark = isDarkMode;
      
      if (_useSmartTheme) {
        _startTimer();
      }
      notifyListeners();
    } catch (e) {
      print('Error loading theme prefs: $e');
    }
  }

  Future<void> _saveBoolToPrefs(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _saveTimeToPrefs(String hourKey, String minuteKey, TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(hourKey, time.hour);
      await prefs.setInt(minuteKey, time.minute);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
