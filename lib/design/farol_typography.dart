import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FarolTypography {
  FarolTypography._();

  static TextStyle display({Color? color}) => GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle title({Color? color, double fontSize = 24}) =>
      GoogleFonts.manrope(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle body({Color? color, double fontSize = 14}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle label({Color? color, double fontSize = 12}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color,
      );

  static TextStyle numeric({Color? color, double fontSize = 24}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );
}
