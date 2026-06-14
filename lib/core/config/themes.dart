import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6B4EFF);
  static const Color primaryLight = Color(0xFF8B7AFF);
  static const Color primaryDeep = Color(0xFF4A35CC);
  static const Color accent = Color(0xFFFF6B9D);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF4444);
  static const double radius = 12;

  // Ambient purple-tinted surfaces
  static const Color background = Color(0xFFF5F3FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTinted = Color(0xFFF8F6FF);
  static const Color cardBorder = Color(0xFFE2DEF0);

  static const Color darkBackground = Color(0xFF1A1625);
  static const Color darkSurface = Color(0xFF252133);

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        scaffold: background,
        surface: surface,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        scaffold: darkBackground,
        surface: darkSurface,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkSurface : primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? darkSurface : surfaceTinted,
        elevation: isDark ? 1 : 1,
        shadowColor: primary.withValues(alpha: isDark ? 0.15 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : cardBorder,
          ),
        ),
      ),
      dividerColor:
          isDark ? Colors.white10 : AppTheme.primary.withValues(alpha: 0.12),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : surfaceTinted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        headlineMedium: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(fontSize: 17, fontFamily: 'Inter'),
        bodyMedium: TextStyle(fontSize: 15, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      iconTheme: const IconThemeData(size: 28),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : surfaceTinted,
        selectedItemColor: primary,
        unselectedItemColor: primary.withValues(alpha: isDark ? 0.4 : 0.35),
      ),
    );
  }
}
