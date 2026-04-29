import 'package:flutter/material.dart';

class AppTheme {
  static const Color lightBackground = Color(0xFFF6F3FF);
  static const Color darkBackground = Color(0xFF080B16);
  static const List<Color> noteColors = [
    Color(0xFF9CCBFF),
    Color(0xFFFFAFC2),
    Color(0xFFA9F5CB),
    Color(0xFFFFD89C),
    Color(0xFFC7A5FF),
    Color(0xFF87E9F2),
  ];
  static const List<List<Color>> noteGradients = [
    [Color(0xFFEAF3FF), Color(0xFF9CCBFF)],
    [Color(0xFFFFEEF3), Color(0xFFFFAFC2)],
    [Color(0xFFEFFFF6), Color(0xFFA9F5CB)],
    [Color(0xFFFFF5DE), Color(0xFFFFD89C)],
    [Color(0xFFF5EEFF), Color(0xFFC7A5FF)],
    [Color(0xFFE9FDFF), Color(0xFF87E9F2)],
  ];

  static ThemeData light() {
    return _base(Brightness.light).copyWith(
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6554F2),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
      ),
    );
  }

  static ThemeData dark() {
    return _base(Brightness.dark).copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8BB8FF),
        brightness: Brightness.dark,
        surface: const Color(0xFF111827),
      ),
    );
  }

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF18181B),
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 74,
        backgroundColor: Colors.transparent,
        indicatorColor: isDark
            ? const Color(0xFF8BB8FF).withValues(alpha: 0.18)
            : const Color(0xFF6554F2).withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF151B2D).withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.82),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF6554F2)
              : null,
        ),
      ),
    );
  }
}
