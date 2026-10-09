import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Class representing a complete theme preset
class AppThemePreset {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final bool isDark;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color accentPrimary;
  final Color accentLight;
  final Color accentDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successSurface;
  final Color error;
  final Color errorSurface;

  const AppThemePreset({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.isDark,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.accentPrimary,
    required this.accentLight,
    required this.accentDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successSurface,
    required this.error,
    required this.errorSurface,
  });
}

/// TUSSI Design System
/// Dynamic multi-theme manager supporting 5 rich, state-of-the-art presets.
class AppTheme {
  AppTheme._();

  /// Case-insensitive, space-ignoring, ordered subsequence/fuzzy match for fabric names.
  static bool matchesFuzzy(String query, String target) {
    final queryClean = query.replaceAll(' ', '').toLowerCase();
    final targetClean = target.replaceAll(' ', '').toLowerCase();
    if (queryClean.isEmpty) return true;

    int queryIdx = 0;
    int targetIdx = 0;
    while (queryIdx < queryClean.length && targetIdx < targetClean.length) {
      if (queryClean[queryIdx] == targetClean[targetIdx]) {
        queryIdx++;
      }
      targetIdx++;
    }
    return queryIdx == queryClean.length;
  }

  // ─── 5 Curated Theme Presets ──────────────────────────────────────────
  static final Map<String, AppThemePreset> presets = {
    'dark_obsidian': const AppThemePreset(
      id: 'dark_obsidian',
      nameAr: 'الأسود الفاخر',
      nameEn: 'Dark Obsidian',
      icon: Icons.dark_mode_rounded,
      isDark: true,
      surface: Color(0xFF000000),
      surfaceCard: Color(0xFF141414),
      surfaceElevated: Color(0xFF242424),
      borderSubtle: Color(0xFF383838),
      accentPrimary: Color(0xFFD4D4D4),
      accentLight: Color(0xFFF5F5F5),
      accentDark: Color(0xFFA3A3A3),
      textPrimary: Colors.white,
      textSecondary: Color(0xFF9E9E9E),
      textMuted: Color(0xFF616161),
      success: Color(0xFF4ADE80),
      successSurface: Color(0xFF132917),
      error: Color(0xFFF87171),
      errorSurface: Color(0xFF2D1316),
    ),
    'royal_gold': const AppThemePreset(
      id: 'royal_gold',
      nameAr: 'الذهبي الملكي',
      nameEn: 'Royal Gold',
      icon: Icons.workspace_premium_rounded,
      isDark: true,
      surface: Color(0xFF0B0F19),
      surfaceCard: Color(0xFF131B2E),
      surfaceElevated: Color(0xFF1E293B),
      borderSubtle: Color(0xFF334155),
      accentPrimary: Color(0xFFF5C842),
      accentLight: Color(0xFFFDE68A),
      accentDark: Color(0xFFD97706),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFFCBD5E1),
      textMuted: Color(0xFF64748B),
      success: Color(0xFF34D399),
      successSurface: Color(0xFF064E3B),
      error: Color(0xFFF87171),
      errorSurface: Color(0xFF451A1A),
    ),
    'sapphire_blue': const AppThemePreset(
      id: 'sapphire_blue',
      nameAr: 'الأزرق الملكي',
      nameEn: 'Sapphire Blue',
      icon: Icons.water_drop_rounded,
      isDark: true,
      surface: Color(0xFF070E1B),
      surfaceCard: Color(0xFF0F172A),
      surfaceElevated: Color(0xFF1E293B),
      borderSubtle: Color(0xFF334155),
      accentPrimary: Color(0xFF38BDF8),
      accentLight: Color(0xFF7DD3FC),
      accentDark: Color(0xFF0284C7),
      textPrimary: Color(0xFFF0F9FF),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
      success: Color(0xFF34D399),
      successSurface: Color(0xFF064E3B),
      error: Color(0xFFF87171),
      errorSurface: Color(0xFF451A1A),
    ),
    'digital_emerald': const AppThemePreset(
      id: 'digital_emerald',
      nameAr: 'الزمرد الرقمي',
      nameEn: 'Digital Emerald',
      icon: Icons.eco_rounded,
      isDark: true,
      surface: Color(0xFF041810),
      surfaceCard: Color(0xFF0B251A),
      surfaceElevated: Color(0xFF143828),
      borderSubtle: Color(0xFF1E4D37),
      accentPrimary: Color(0xFF10B981),
      accentLight: Color(0xFF6EE7B7),
      accentDark: Color(0xFF059669),
      textPrimary: Color(0xFFECFDF5),
      textSecondary: Color(0xFFA7F3D0),
      textMuted: Color(0xFF4B7C65),
      success: Color(0xFF34D399),
      successSurface: Color(0xFF064E3B),
      error: Color(0xFFF87171),
      errorSurface: Color(0xFF451A1A),
    ),
    'silver_light': const AppThemePreset(
      id: 'silver_light',
      nameAr: 'الفضي المشرق',
      nameEn: 'Platinum Light',
      icon: Icons.light_mode_rounded,
      isDark: false,
      surface: Color(0xFFF8FAFC),
      surfaceCard: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF1F5F9),
      borderSubtle: Color(0xFFE2E8F0),
      accentPrimary: Color(0xFF2563EB),
      accentLight: Color(0xFF3B82F6),
      accentDark: Color(0xFF1D4ED8),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF475569),
      textMuted: Color(0xFF94A3B8),
      success: Color(0xFF10B981),
      successSurface: Color(0xFFD1FAE5),
      error: Color(0xFFEF4444),
      errorSurface: Color(0xFFFEE2E2),
    ),
  };

  static AppThemePreset createCustomPreset({
    required Color primaryColor,
    required bool isDark,
  }) {
    final surface = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final surfaceCard = isDark ? const Color(0xFF131B2E) : const Color(0xFFFFFFFF);
    final surfaceElevated = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderSubtle = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final textMuted = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final HSLColor hsl = HSLColor.fromColor(primaryColor);
    final accentLight = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final accentDark = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    return AppThemePreset(
      id: 'custom',
      nameAr: 'ثيم مخصص',
      nameEn: 'Custom Theme',
      icon: Icons.palette_rounded,
      isDark: isDark,
      surface: surface,
      surfaceCard: surfaceCard,
      surfaceElevated: surfaceElevated,
      borderSubtle: borderSubtle,
      accentPrimary: primaryColor,
      accentLight: accentLight,
      accentDark: accentDark,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      success: const Color(0xFF34D399),
      successSurface: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
      error: const Color(0xFFF87171),
      errorSurface: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
    );
  }

  // ─── Theme State ───────────────────────────────────────────────
  static AppThemePreset activePreset = presets['dark_obsidian']!;

  static void setPreset(String themeId) {
    if (presets.containsKey(themeId)) {
      activePreset = presets[themeId]!;
    }
  }

  static bool get isDark => activePreset.isDark;
  static set isDark(bool val) {
    // Legacy toggle support
    setPreset(val ? 'dark_obsidian' : 'silver_light');
  }

  // ─── Dynamic Palette Getters ─────────────────────────────────
  static Color get surfaceDark => activePreset.surface;
  static Color get surfaceCard => activePreset.surfaceCard;
  static Color get surfaceElevated => activePreset.surfaceElevated;
  static Color get borderSubtle => activePreset.borderSubtle;

  static Color get accentAmber => activePreset.accentPrimary;
  static Color get accentAmberLight => activePreset.accentLight;
  static Color get accentAmberDark => activePreset.accentDark;

  static Color get textPrimary => activePreset.textPrimary;
  static Color get textSecondary => activePreset.textSecondary;
  static Color get textMuted => activePreset.textMuted;
  static Color get success => activePreset.success;
  static Color get successSurface => activePreset.successSurface;
  static Color get error => activePreset.error;
  static Color get errorSurface => activePreset.errorSurface;
  static Color get info => const Color(0xFF60A5FA);

  static Color get primaryGold => activePreset.accentPrimary;
  static LinearGradient get goldGradient => LinearGradient(
        colors: [activePreset.accentPrimary, activePreset.accentDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => LinearGradient(
        colors: [activePreset.accentPrimary, activePreset.accentLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get surfaceGradient => LinearGradient(
        colors: [activePreset.surface, activePreset.surfaceCard],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ─── Dynamic ThemeData Generator ─────────────────────────────
  static ThemeData get themeData {
    final p = activePreset;
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.surface,
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: p.textPrimary, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: p.textPrimary, letterSpacing: -0.3),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: p.textPrimary),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.textPrimary),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: p.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: p.textSecondary),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: p.textSecondary),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: p.textMuted),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary, letterSpacing: 0.5),
        ),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accentPrimary,
        onPrimary: p.isDark ? Colors.black : Colors.white,
        secondary: p.accentLight,
        onSecondary: p.isDark ? Colors.black : Colors.white,
        surface: p.surfaceCard,
        onSurface: p.textPrimary,
        error: p.error,
        onError: Colors.white,
        outline: p.borderSubtle,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.borderSubtle, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accentPrimary,
          foregroundColor: p.isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.accentPrimary,
          side: BorderSide(color: p.accentPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentPrimary,
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.accentPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.error)),
        hintStyle: TextStyle(color: p.textMuted, fontSize: 14),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surfaceCard,
        selectedItemColor: p.accentPrimary,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.borderSubtle)),
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: p.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: GoogleFonts.outfit(fontSize: 14, color: p.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: p.borderSubtle, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accentPrimary,
        foregroundColor: p.isDark ? Colors.black : Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme => themeData;
  static ThemeData get lightTheme => themeData;
}