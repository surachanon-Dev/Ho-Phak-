import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ค่าสี ระยะ และธีมของฝั่ง owner รวมไว้ที่เดียว หน้าจอให้อ้างจากที่นี่ ไม่เขียนค่าตรง ๆ
abstract final class OwnerColors {
  static const navy = Color(0xFF183B56);
  static const primary = Color(0xFF1F7F73);
  static const primaryText = Color(0xFF1E6B62);
  static const primaryTint = Color(0xFFE3F2EF);
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8EE);
  static const divider = Color(0xFFEEF2F5);
  static const fieldBorder = Color(0xFFC9D3DB);
  static const text = Color(0xFF263238);
  static const textBody = Color(0xFF3E4C55);
  static const textMuted = Color(0xFF5B6B76);
  static const warning = Color(0xFF8A4B0F);
  static const warningTint = Color(0xFFFDEDDF);
  static const danger = Color(0xFFA12C2C);
  static const dangerTint = Color(0xFFFBE9E9);
  static const chip = Color(0xFFEAF0F5);
  static const switchOff = Color(0xFFC3CDD5);
  static const photo = Color(0xFFD9E6F0);
}

abstract final class OwnerRadius {
  static const double card = 20;
  static const double tile = 12;
  static const double field = 12;
  static const double header = 28;
}

abstract final class OwnerGap {
  /// ขอบซ้ายขวาของหน้า
  static const double page = 20;

  /// ระยะระหว่างการ์ด
  static const double block = 12;

  /// เว้นท้ายหน้าที่มีแถบนำทางลอยทับอยู่
  static const double belowNav = 120;
}

ThemeData buildOwnerTheme() {
  final base = ThemeData(useMaterial3: true);
  final text = GoogleFonts.ibmPlexSansThaiTextTheme(base.textTheme)
      .apply(bodyColor: OwnerColors.text, displayColor: OwnerColors.text);
  final button = text.titleMedium?.copyWith(fontWeight: FontWeight.w600);

  OutlineInputBorder outline(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(OwnerRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: OwnerColors.primary).copyWith(
      primary: OwnerColors.primary,
      onPrimary: Colors.white,
      surface: OwnerColors.surface,
      onSurface: OwnerColors.text,
      error: OwnerColors.danger,
      outline: OwnerColors.fieldBorder,
    ),
    scaffoldBackgroundColor: OwnerColors.background,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: OwnerColors.navy,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: OwnerColors.navy),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OwnerColors.surface,
      contentPadding: const EdgeInsets.all(14),
      hintStyle: const TextStyle(color: OwnerColors.textMuted),
      border: outline(OwnerColors.fieldBorder),
      enabledBorder: outline(OwnerColors.fieldBorder),
      focusedBorder: outline(OwnerColors.primary, 1.5),
      errorBorder: outline(OwnerColors.danger, 1.5),
      focusedErrorBorder: outline(OwnerColors.danger, 1.5),
      disabledBorder: outline(OwnerColors.border),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: const StadiumBorder(),
        backgroundColor: OwnerColors.primary,
        textStyle: button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: const StadiumBorder(),
        foregroundColor: OwnerColors.primary,
        side: const BorderSide(color: OwnerColors.primary),
        textStyle: button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: OwnerColors.primary,
        textStyle: button,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: OwnerColors.navy,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: OwnerColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OwnerRadius.card)),
    ),
    dividerTheme: const DividerThemeData(color: OwnerColors.divider, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? OwnerColors.primary : OwnerColors.switchOff,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? OwnerColors.primary : null),
      side: const BorderSide(color: OwnerColors.textMuted, width: 1.5),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide(color: OwnerColors.fieldBorder)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? OwnerColors.primaryTint : OwnerColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? OwnerColors.primaryText : OwnerColors.text,
        ),
      ),
    ),
  );
}
