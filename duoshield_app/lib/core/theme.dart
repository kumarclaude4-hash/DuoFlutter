import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

final ThemeData dsTheme = buildAppTheme();

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: colorBackground,
    colorScheme: const ColorScheme.dark(
      surface: colorSurface,
      primary: colorAccent,
      onPrimary: colorOnAccent,
      error: colorError,
      onSurface: colorTextPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: colorTextPrimary),
      headlineMedium: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: colorTextPrimary),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: colorTextPrimary),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: colorTextPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: colorTextPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: colorTextPrimary),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: colorTextSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 10, color: colorTextMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: colorSurface,
      foregroundColor: colorTextPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorInputBg,
      hintStyle: GoogleFonts.inter(color: colorTextMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: colorAccent, width: 1.5),
      ),
    ),
    dividerColor: colorDivider,
    iconTheme: const IconThemeData(color: colorIconDefault),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: colorAccent,
      foregroundColor: Colors.white,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorAccent;
        return Colors.transparent;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorAccent;
        return colorTextMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorAccent.withOpacity(0.5);
        return colorSurfaceVariant;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorAccent;
        return colorTextMuted;
      }),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: colorSurfaceVariant,
      contentTextStyle: TextStyle(color: colorTextPrimary),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: colorSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: colorTextPrimary),
      contentTextStyle: GoogleFonts.inter(fontSize: 14, color: colorTextSecondary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: colorSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: colorAccent,
      unselectedLabelColor: colorTextSecondary,
      indicatorColor: colorAccent,
    ),
  );
}
