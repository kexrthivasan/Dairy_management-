import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF43A047); // Natural green
  static const Color lightGreen = Color(0xFFA5D6A7); // Soft background green
  static const Color creamWhite = Color(0xFFFAFAFA); // Background
  static const Color darkText = Color(0xFF212121); // High contrast text
  static const Color errorRed = Color(0xFFE53935); // Alert
  static const Color milkWhite = Color(
    0xFFFFF9C4,
  ); // Very light yellow/cream for cards

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: creamWhite,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryGreen,
        secondary: lightGreen,
        error: errorRed,
      ),
      fontFamily: 'Roboto', // Default sans-serif, easy to read
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          color: darkText,
        ), // Base text size for elders
        bodyMedium: TextStyle(fontSize: 18, color: darkText),
        labelLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
        labelStyle: const TextStyle(fontSize: 18),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: primaryGreen,
        secondary: lightGreen,
        error: errorRed,
        surface: const Color(0xFF1E1E1E),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 20, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 18, color: Colors.white70),
        labelLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
        labelStyle: const TextStyle(fontSize: 18, color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white60),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      dividerColor: Colors.white24,
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(fontSize: 18, color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
