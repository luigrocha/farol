import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Farol Colors from Design Tokens
  static const Color surface = Color(0xFFF0EEE9); // Farol Paper
  static const Color surfaceLow = Color(0xFFF3F4F6); // Farol Fog
  static const Color surfaceLowest = Color(0xFFFFFFFF); // Cards
  static const Color primaryColor = Color(0xFF1B3A5C); // Farol Navy
  static const Color primaryContainer = Color(0xFF244A72);
  static const Color primaryDeep = Color(0xFF0D2238);
  static const Color secondaryColor = Color(0xFFF5A623); // Farol Beam
  static const Color secondaryContainer = Color(0xFFFDF1DB);
  static const Color tertiaryColor = Color(0xFF1A7A4A); // Farol Tide
  static const Color errorColor = Color(0xFFE84855); // Farol Coral
  static const Color warningColor = Color(0xFFF5A623);
  
  static const Color onSurface = Color(0xFF1B2332);
  static const Color onSurfaceMuted = Color(0xFF374151);
  static const Color onSurfaceSoft = Color(0xFF6B7280);
  static const Color onSurfaceFaint = Color(0xFF9CA3AF);

  // Health Score Colors
  static const Color healthGreen = Color(0xFF1A7A4A);
  static const Color healthAmber = Color(0xFFF5A623);
  static const Color healthRed = Color(0xFFE84855);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        background: surface,
        surface: surfaceLowest,
        onBackground: onSurface,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: surface,
      cardTheme: CardTheme(
        color: surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryColor.withOpacity(0.05), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: onSurface),
        displayMedium: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: onSurface),
        displaySmall: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
        headlineLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: onSurface),
        headlineMedium: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
        headlineSmall: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
        titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
        titleMedium: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: onSurface),
        titleSmall: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        indicatorColor: primaryColor.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final color = states.contains(MaterialState.selected) ? onSurface : onSurfaceFaint;
          return TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: color,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(MaterialState.selected) ? onSurface : onSurfaceFaint,
            size: 24,
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; // For now, focus on premium light design as per mockup

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'HOUSING': return const Color(0xFF1B3A5C); // Navy
      case 'TRANSPORT': return const Color(0xFFF5A623); // Beam
      case 'FOOD_GROCERY': return const Color(0xFF1A7A4A); // Tide
      case 'HEALTH': return const Color(0xFFE84855); // Coral
      case 'LEISURE': return const Color(0xFF8FA3B8); // Slate
      default: return onSurfaceSoft;
    }
  }
}
