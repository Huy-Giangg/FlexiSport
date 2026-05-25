import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Colors from "Authentication Screen Templates" Stitch Project
  static const Color primary = Color(0xFF7FA448); // Olive Green
  static const Color primaryContainer = Color(0xFF476811); // Lighter Green
  static const Color onPrimaryContainer = Color(0xFF213600);
  static Color backgroundLight = Color(0xFFE7E4D5);

  static Color primaryLightBg = Color(0xFFCFE5DA);

  static const Color background = Color(0xFFFAF9F4); // Off-White/Beige
  static const Color onBackground = Color(0xFF1B1C19); // Near Black

  static const Color surface = Color(0xFFFAF9F4);
  static const Color onSurface = Color(0xFF1B1C19);
  static const Color surfaceVariant = Color(0xFFE3E3DE);

  static const Color outline = Color(0xFF747969);
  static const Color outlineVariant = Color(0xFFC4C9B6);

  static const Color secondary = Color(0xFF5E5E5E);
  static const Color error = Color(0xFFBA1A1A);

  // Legacy names if needed for compatibility (mapped to new colors)
  static const Color primaryGreen = primary;
  static const Color primaryBlack = onBackground;
  static const Color textMain = onBackground;
  static const Color textSecondary = secondary;
  static const Color textLight = outline;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        background: background,
        onBackground: onBackground,
        error: error,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceVariant: surfaceVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.lexendTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lexend(
          color: onBackground,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: onBackground,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
