import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colorTextPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorTextPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorTextPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorTextPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: colorTextPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: colorTextPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: colorTextSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        color: colorTextMuted,
      );
}
