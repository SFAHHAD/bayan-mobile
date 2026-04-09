import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BayanColors {
  static const Color background = Color(0xFF241231);
  static const Color surface = Color(0xFF2E1A3E);
  static const Color accent = Color(0xFF5CBFAD);
  static const Color accentLight = Color(0xFF7DD4C4);
  static const Color textPrimary = Color(0xFFF5F0FA);
  static const Color textSecondary = Color(0xFFB8A9C9);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBackground = Color(0x14FFFFFF);
}

class BayanTheme {
  static ThemeData get dark {
    final cairoText = GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BayanColors.background,
      colorScheme: const ColorScheme.dark(
        primary: BayanColors.accent,
        secondary: BayanColors.accentLight,
        surface: BayanColors.surface,
      ),
      textTheme: cairoText.apply(
        bodyColor: BayanColors.textPrimary,
        displayColor: BayanColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BayanColors.glassBackground,
        hintStyle: const TextStyle(color: BayanColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BayanColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BayanColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BayanColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
