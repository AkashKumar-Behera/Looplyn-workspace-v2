import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  bool _isDark = true;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('is_dark_mode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDark);
  }
}

class AppColors {
  // Dark Mode
  static const Color darkBg = Color(0xFF070709);
  static const Color darkSidebar = Color(0xFF0A0A0E);
  static const Color darkCard = Color(0xFF0F0F13);
  static const Color darkCardHover = Color(0xFF14141A);
  static const Color darkBorder = Color(0x14FFFFFF);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF71717A);

  // Light Mode
  static const Color lightBg = Color(0xFFF3F4F6);
  static const Color lightSidebar = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF9FAFB);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF6B7280);

  // Accents
  static const Color accentRed = Color(0xFFDC2626);
  static const Color accentRedGlow = Color(0x2ADB2727);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Dynamic getters based on active mode
  static Color bg(bool isDark) => isDark ? darkBg : lightBg;
  static Color sidebar(bool isDark) => isDark ? darkSidebar : lightSidebar;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color cardHover(bool isDark) => isDark ? darkCardHover : lightCardHover;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(bool isDark) => isDark ? darkTextMuted : lightTextMuted;
}

class AppTheme {
  static const Color background = Color(0xFF070709);
  static const Color surface = Color(0xFF0F0F13);
  static const Color surfaceLight = Color(0xFF181820);
  static const Color border = Color(0x14FFFFFF);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFDC2626);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF71717A);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: Colors.white,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkCard,
        primary: Colors.white,
        secondary: AppColors.accentRed,
      ),
      fontFamily: 'Inter',
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: Colors.black,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightCard,
        primary: Colors.black,
        secondary: AppColors.accentRed,
      ),
      fontFamily: 'Inter',
    );
  }
}
