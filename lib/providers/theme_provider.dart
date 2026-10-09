import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Provider managing the theme mode and active preset for the application.
/// Supports 5 curated theme presets and a custom time-based smart scheduler.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _currentPresetId = 'dark_obsidian';
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
    return AppTheme.isDark ? ThemeMode.dark : ThemeMode.light;
  }

  String get currentPresetId => _currentPresetId;

  bool get isDarkMode {
    if (_useSmartTheme) {
      return _calculateSmartIsDark();
    }
    return AppTheme.isDark;
  }

  bool get useSmartTheme => _useSmartTheme;
  TimeOfDay get lightStartTime => _lightStartTime;
  TimeOfDay get darkStartTime => _darkStartTime;

  void setPresetTheme(String presetId) {
    if (_useSmartTheme) {
      _useSmartTheme = false;
      _saveBoolToPrefs('use_smart_theme', false);
    }
    _currentPresetId = presetId;
    AppTheme.setPreset(presetId);
    _themeMode = AppTheme.isDark ? ThemeMode.dark : ThemeMode.light;
    _saveStringToPrefs('app_theme_preset', presetId);
    notifyListeners();
  }

  void setCustomTheme({required Color primaryColor, required bool isDark}) {
    if (_useSmartTheme) {
      _useSmartTheme = false;
      _saveBoolToPrefs('use_smart_theme', false);
    }
    _currentPresetId = 'custom';
    AppTheme.presets['custom'] = AppTheme.createCustomPreset(
      primaryColor: primaryColor,
      isDark: isDark,
    );
    AppTheme.activePreset = AppTheme.presets['custom']!;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    _saveStringToPrefs('app_theme_preset', 'custom');
    _saveIntToPrefs('custom_primary_color', primaryColor.toARGB32());
    _saveBoolToPrefs('custom_is_dark', isDark);
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    setPresetTheme(isDark ? 'dark_obsidian' : 'silver_light');
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
      return currentMinutes < lightMinutes || currentMinutes >= darkMinutes;
    } else {
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
      _currentPresetId = prefs.getString('app_theme_preset') ?? 'dark_obsidian';
      
      if (_currentPresetId == 'custom') {
        final customColorVal = prefs.getInt('custom_primary_color') ?? 0xFFD4D4D4;
        final customIsDark = prefs.getBool('custom_is_dark') ?? true;
        AppTheme.presets['custom'] = AppTheme.createCustomPreset(
          primaryColor: Color(customColorVal),
          isDark: customIsDark,
        );
      }
      AppTheme.setPreset(_currentPresetId);

      _themeMode = AppTheme.isDark ? ThemeMode.dark : ThemeMode.light;

      final lightHour = prefs.getInt('light_start_hour') ?? 6;
      final lightMinute = prefs.getInt('light_start_minute') ?? 0;
      _lightStartTime = TimeOfDay(hour: lightHour, minute: lightMinute);

      final darkHour = prefs.getInt('dark_start_hour') ?? 18;
      final darkMinute = prefs.getInt('dark_start_minute') ?? 0;
      _darkStartTime = TimeOfDay(hour: darkHour, minute: darkMinute);

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

  Future<void> _saveStringToPrefs(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _saveIntToPrefs(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
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
