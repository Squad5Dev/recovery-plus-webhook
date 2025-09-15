import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color _lightPrimaryColor = Color(0xFF32D4C2); // Primary Button
  static const Color _lightBackgroundColor = Color(0xFFFFFFFF); // Background (main)
  static const Color _lightTextPrimaryColor = Color(0xFF1E1E2E); // Primary Text
  static const Color _lightTextSecondaryColor = Color(0xFF666666); // Secondary Text
  static const Color _lightSurfaceColor = Color(0xFFF2ECFF); // Card Background
  static const Color _lightAccentColor = Color(0xFF9B8FEF); // Accent

  // Dark Mode Colors
  static const Color _darkPrimaryColor = Color(0xFF32D4C2); // Primary Button
  static const Color _darkBackgroundColor = Color(0xFF121212); // Background (main)
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E); // Surface
  static const Color _darkTextPrimaryColor = Color(0xFFFFFFFF); // Primary Text
  static const Color _darkTextSecondaryColor = Color(0xFFB0B0B0); // Secondary Text
  static const Color _darkAccentColor = Color(0xFF9B8FEF); // Accent

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _lightPrimaryColor,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimaryColor,
        secondary: _lightAccentColor, // Using accent color for secondary
        background: _lightBackgroundColor,
        surface: _lightSurfaceColor,
        onPrimary: Colors.white, // Text on primary color
        onSecondary: _lightTextPrimaryColor, // Text on accent color
        onBackground: _lightTextPrimaryColor, // Text on background
        onSurface: _lightTextPrimaryColor, // Text on surface
        error: Colors.red, // Default error color
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _lightBackgroundColor,
      cardColor: _lightSurfaceColor,
      textTheme: baseTextTheme.copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: _lightTextPrimaryColor),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: _lightTextSecondaryColor),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: _lightTextPrimaryColor),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: _lightTextPrimaryColor),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: _lightTextPrimaryColor),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: _lightTextPrimaryColor),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: _lightTextPrimaryColor),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: _lightTextPrimaryColor),
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: _lightTextPrimaryColor),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: _lightTextPrimaryColor),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: _lightTextPrimaryColor),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: _lightTextPrimaryColor),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: _lightTextSecondaryColor),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: _lightTextSecondaryColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackgroundColor,
        foregroundColor: _lightTextPrimaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _lightAccentColor),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 22.0,
          color: Colors.white, // Assuming onPrimary is white for light theme app bar
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: baseTextTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightAccentColor,
          textStyle: baseTextTheme.labelLarge?.copyWith(color: _lightAccentColor),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightAccentColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightTextSecondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightTextSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightPrimaryColor, width: 2),
        ),
        labelStyle: baseTextTheme.labelLarge?.copyWith(color: _lightTextSecondaryColor),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: _lightTextSecondaryColor),
        fillColor: _lightSurfaceColor,
        filled: true,
      ),
      iconTheme: IconThemeData(
        color: _lightAccentColor,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _lightPrimaryColor,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _darkPrimaryColor,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: _darkAccentColor, // Using accent color for secondary
        background: _darkBackgroundColor,
        surface: _darkSurfaceColor,
        onPrimary: Colors.white, // Text on primary color
        onSecondary: _darkTextPrimaryColor, // Text on accent color
        onBackground: _darkTextPrimaryColor, // Text on background
        onSurface: _darkTextPrimaryColor, // Text on surface
        error: Colors.red, // Default error color
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _darkBackgroundColor,
      cardColor: _darkSurfaceColor,
      textTheme: baseTextTheme.copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: _darkTextPrimaryColor),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: _darkTextSecondaryColor),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: _darkTextPrimaryColor),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: _darkTextPrimaryColor),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: _darkTextPrimaryColor),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: _darkTextPrimaryColor),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: _darkTextPrimaryColor),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: _darkTextPrimaryColor),
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: _darkTextPrimaryColor),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: _darkTextPrimaryColor),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: _darkTextPrimaryColor),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: _darkTextPrimaryColor),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: _darkTextSecondaryColor),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: _darkTextSecondaryColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackgroundColor,
        foregroundColor: _darkTextPrimaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _darkAccentColor),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 22.0,
          color: Colors.white, // Assuming onPrimary is white for dark theme app bar
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: baseTextTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkAccentColor,
          textStyle: baseTextTheme.labelLarge?.copyWith(color: _darkAccentColor),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkAccentColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkTextSecondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkTextSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
        ),
        labelStyle: baseTextTheme.labelLarge?.copyWith(color: _darkTextSecondaryColor),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: _darkTextSecondaryColor),
        fillColor: _darkSurfaceColor,
        filled: true,
      ),
      iconTheme: IconThemeData(
        color: _darkAccentColor,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _darkPrimaryColor,
      ),
    );
  }

  // Exposed getters for external usage
  static Color get primaryColor => _lightPrimaryColor;
  static Color get accentColor => _lightAccentColor;
  static Color get darkPrimaryColor => _darkPrimaryColor;
  static Color get darkAccentColor => _darkAccentColor;
}
