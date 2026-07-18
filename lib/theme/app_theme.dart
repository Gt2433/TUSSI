import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fantex Design System
/// A modern, premium theme supporting Light and Dark modes.
class AppTheme {
  AppTheme._();

  // ─── Theme State ───────────────────────────────────────────────
  static bool isDark = true;

  // ─── Dark Palette ──────────────────────────────────────────────
  static const Color _surfaceDark = Colors.black; // خلفية سوداء بالكامل
  static const Color _surfaceCardDark = Color(0xFF1A1A1A); // رمادي داكن للبطاقات
  static const Color _surfaceElevatedDark = Color(0xFF2A2A2A); // رمادي معدني لحقول الإدخال
  static const Color _borderSubtleDark = Color(0xFF404040); // حواف رمادية

  static const Color _accentOrangeDark = Color(0xFFD4D4D4); // الرمادي اللامع المطلوب
  static const Color _accentOrangeLightDark = Color(0xFFF5F5F5); // رمادي فاتح
  static const Color _accentOrangeDarkDark = Color(0xFFA3A3A3); // رمادي داكن

  static const Color _textPrimaryDark = Colors.white; // نصوص بيضاء
  static const Color _textSecondaryDark = Color(0xFF9E9E9E); // رمادي معدني للنصوص الثانوية
  static const Color _textMutedDark = Color(0xFF616161);

  static const Color _successDark = Color(0xFF4ADE80);
  static const Color _successSurfaceDark = Color(0xFF132917);
  static const Color _errorDark = Color(0xFFF87171);
  static const Color _errorSurfaceDark = Color(0xFF2D1316);

  // ─── Light Palette ──────────────────────────────────────────────
  static const Color _surfaceLight = Color(0xFFF9FAFB); // رمادي فاتح جداً (تقريباً أبيض)
  static const Color _surfaceCardLight = Colors.white; // بطاقات بيضاء
  static const Color _surfaceElevatedLight = Color(0xFFF3F4F6); // حقول إدخال رمادي فاتح
  static const Color _borderSubtleLight = Color(0xFFE5E7EB); // حواف رمادية خفيفة جداً

  static const Color _accentOrangeLight = Color(0xFF37474F); // رمادي معدني داكن للوضوح والتباين في الوضع الفاتح
  static const Color _accentOrangeLightLight = Color(0xFF4B5563); // رمادي معدني متوسط
  static const Color _accentOrangeDarkLight = Color(0xFF1F2937); // رمادي معدني غامق جداً

  static const Color _textPrimaryLight = Color(0xFF111827); // نصوص داكنة جداً
  static const Color _textSecondaryLight = Color(0xFF4B5563); // نصوص ثانوية رمادي داكن
  static const Color _textMutedLight = Color(0xFF9CA3AF);

  static const Color _successLight = Color(0xFF10B981);
  static const Color _successSurfaceLight = Color(0xFFD1FAE5);
  static const Color _errorLight = Color(0xFFEF4444);
  static const Color _errorSurfaceLight = Color(0xFFFEE2E2);

  static const Color _info = Color(0xFF60A5FA);

  // ─── Gradients ─────────────────────────────────────────────────
  static LinearGradient get accentGradient => LinearGradient(
        colors: isDark
            ? [_accentOrangeDark, _accentOrangeLightDark]
            : [_accentOrangeLight, _accentOrangeLightLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get surfaceGradient => LinearGradient(
        colors: isDark
            ? [_surfaceDark, const Color(0xFF101010)]
            : [_surfaceLight, const Color(0xFFF3F4F6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ─── Dark Theme Data ───────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _surfaceDark,
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _textPrimaryDark,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: _textPrimaryDark,
            letterSpacing: -0.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textPrimaryDark,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimaryDark,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textPrimaryDark,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: _textSecondaryDark,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _textSecondaryDark,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _textMutedDark,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimaryDark,
            letterSpacing: 0.5,
          ),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: _accentOrangeDark,
        onPrimary: _surfaceDark,
        secondary: _accentOrangeLightDark,
        onSecondary: _surfaceDark,
        surface: _surfaceCardDark,
        onSurface: _textPrimaryDark,
        error: _errorDark,
        onError: Colors.white,
        outline: _borderSubtleDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: _textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: _surfaceCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderSubtleDark, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrangeDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentOrangeDark,
          side: const BorderSide(color: _accentOrangeDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentOrangeDark,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceElevatedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderSubtleDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderSubtleDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentOrangeDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorDark),
        ),
        hintStyle: const TextStyle(color: _textMutedDark, fontSize: 14),
        labelStyle: const TextStyle(color: _textSecondaryDark, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceElevatedDark,
        selectedColor: _accentOrangeDark.withValues(alpha: 0.2),
        side: const BorderSide(color: _borderSubtleDark),
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceCardDark,
        selectedItemColor: _accentOrangeDark,
        unselectedItemColor: _textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceCardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderSubtleDark),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceElevatedDark,
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: _textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: _borderSubtleDark,
        thickness: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentOrangeDark,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // ─── Light Theme Data ──────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _surfaceLight,
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _textPrimaryLight,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: _textPrimaryLight,
            letterSpacing: -0.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textPrimaryLight,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimaryLight,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textPrimaryLight,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: _textSecondaryLight,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _textSecondaryLight,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _textMutedLight,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimaryLight,
            letterSpacing: 0.5,
          ),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: _accentOrangeLight,
        onPrimary: Colors.white,
        secondary: _accentOrangeLightLight,
        onSecondary: Colors.white,
        surface: _surfaceCardLight,
        onSurface: _textPrimaryLight,
        error: _errorLight,
        onError: Colors.white,
        outline: _borderSubtleLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: _textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: _surfaceCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderSubtleLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrangeLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentOrangeLight,
          side: const BorderSide(color: _accentOrangeLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentOrangeLight,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceElevatedLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderSubtleLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderSubtleLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentOrangeLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorLight),
        ),
        hintStyle: const TextStyle(color: _textMutedLight, fontSize: 14),
        labelStyle: const TextStyle(color: _textSecondaryLight, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceElevatedLight,
        selectedColor: _accentOrangeLight.withValues(alpha: 0.15),
        side: const BorderSide(color: _borderSubtleLight),
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textPrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceCardLight,
        selectedItemColor: _accentOrangeLight,
        unselectedItemColor: _textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceCardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderSubtleLight),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryLight,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceElevatedLight,
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: _textPrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: _borderSubtleLight,
        thickness: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentOrangeLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // ─── Helper Colors (accessible by screens) ────────────────────
  static Color get surfaceDark => isDark ? _surfaceDark : _surfaceLight;
  static Color get surfaceCard => isDark ? _surfaceCardDark : _surfaceCardLight;
  static Color get surfaceElevated => isDark ? _surfaceElevatedDark : _surfaceElevatedLight;
  static Color get borderSubtle => isDark ? _borderSubtleDark : _borderSubtleLight;

  static Color get accentAmber => isDark ? _accentOrangeDark : _accentOrangeLight;
  static Color get accentAmberLight => isDark ? _accentOrangeLightDark : _accentOrangeLightLight;
  static Color get accentAmberDark => isDark ? _accentOrangeDarkDark : _accentOrangeDarkLight;

  static Color get textPrimary => isDark ? _textPrimaryDark : _textPrimaryLight;
  static Color get textSecondary => isDark ? _textSecondaryDark : _textSecondaryLight;
  static Color get textMuted => isDark ? _textMutedDark : _textMutedLight;
  static Color get success => isDark ? _successDark : _successLight;
  static Color get successSurface => isDark ? _successSurfaceDark : _successSurfaceLight;
  static Color get error => isDark ? _errorDark : _errorLight;
  static Color get errorSurface => isDark ? _errorSurfaceDark : _errorSurfaceLight;
  static Color get info => _info;
}