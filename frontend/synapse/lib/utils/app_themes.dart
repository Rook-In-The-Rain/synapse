import 'package:flutter/material.dart';

class AppThemes {

  static const List<Color> lightPrimaryGradient = [Color(0xFF6366F1), Color(0xFF4F46E5)];
  static const List<Color> darkPrimaryGradient = [Color(0xFF8B5CF6), Color(0xFF7C3AED)];
  static const List<Color> lightSecondaryGradient = [Color(0xFF94A3B8), Color(0xFF64748B)];
  static const List<Color> darkSecondaryGradient = [Color(0xFF536976), Color(0xFF292E49)];
  static const List<Color> lightScaffoldBackgroundGradient = [Color(0xFFF0F2F5), Color(0xFFE0E2E5)];
  static const List<Color> darkScaffoldBackgroundGradient = [Color(0xFF0D0D19), Color(0xFF1A1A3A)];

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF334155), 
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Color(0x00FFFFFF),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0F172A)),
      bodyMedium: TextStyle(color: Color(0xFF334155)),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0B1220),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Color(0x00FFFFFF),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
      bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
