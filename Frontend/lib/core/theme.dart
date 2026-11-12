import 'package:flutter/material.dart';

/// Ho-Phak color palette (from the UI design sheet)
class AppColors {
  static const navy = Color(0xFF183B56); // หัวข้อหลัก / เมนู
  static const teal = Color(0xFF2A9D8F); // ปุ่มหลัก / ไฮไลต์
  static const orange = Color(0xFFF4A261); // โปรโมชั่น / ราคา
  static const background = Color(0xFFF5F7FA);
  static const text = Color(0xFF263238);
  static const muted = Color(0xFF78909C);
  static const danger = Color(0xFFE53935);
  static const success = Color(0xFF2E7D32);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    primary: AppColors.teal,
    secondary: AppColors.orange,
    surface: Colors.white,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.teal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EDF2)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.teal.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.teal.withValues(alpha: 0.15),
      side: const BorderSide(color: Color(0xFFDDE3EA)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
