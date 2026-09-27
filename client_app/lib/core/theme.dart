import 'package:flutter/material.dart';

class AppTheme {
  // Looplyn Pitch Black OLED Palette
  static const Color background = Color(0xFF000000); // 100% Pure Pitch Black OLED
  static const Color surface = Color(0xFF0A0A0B);    // Pitch Dark Charcoal #0A0A0B
  static const Color surfaceLight = Color(0xFF18181B); // Subtle Dark Border #18181B
  static const Color border = Color(0xFF232328);     // Card Border #232328
  static const Color primary = Color(0xFFFFFFFF);     // Pure White
  static const Color accent = Color(0xFFDC2626);      // Looplyn Red Accent #DC2626
  static const Color rose = Color(0xFFF43F5E);        // Rose Accent for links
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color info = Color(0xFF3B82F6);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: surface,
      dividerColor: border,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.white, width: 1.2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}
