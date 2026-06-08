import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6B4EFF);
  static const Color accent = Color(0xFFFF6B9D);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF4444);
  static const double radius = 12;

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE7E9F3);

  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E28);

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
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 1 : 2,
        shadowColor: primary.withValues(alpha: isDark ? 0.28 : 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: isDark ? Colors.white12 : cardBorder),
        ),
      ),
      dividerColor: isDark ? Colors.white12 : Colors.grey.shade200,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : Colors.grey.shade50,
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
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.grey,
      ),
    );
  }
}
