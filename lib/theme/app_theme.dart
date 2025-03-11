import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Kanit',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Kanit'),
      displayMedium: TextStyle(fontFamily: 'Kanit'),
      displaySmall: TextStyle(fontFamily: 'Kanit'),
      headlineLarge: TextStyle(fontFamily: 'Kanit'),
      headlineMedium: TextStyle(fontFamily: 'Kanit'),
      headlineSmall: TextStyle(fontFamily: 'Kanit'),
      titleLarge: TextStyle(fontFamily: 'Kanit'),
      titleMedium: TextStyle(fontFamily: 'Kanit'),
      titleSmall: TextStyle(fontFamily: 'Kanit'),
      bodyLarge: TextStyle(fontFamily: 'Kanit'),
      bodyMedium: TextStyle(fontFamily: 'Kanit'),
      bodySmall: TextStyle(fontFamily: 'Kanit'),
      labelLarge: TextStyle(fontFamily: 'Kanit'),
      labelMedium: TextStyle(fontFamily: 'Kanit'),
      labelSmall: TextStyle(fontFamily: 'Kanit'),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
