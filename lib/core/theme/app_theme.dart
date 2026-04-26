import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'farol_colors.dart';

class AppTheme {
  // Brand accent colors — same in light and dark
  static const Color primaryColor = Color(0xFF1B3A5C);
  static const Color primaryContainer = Color(0xFF244A72);
  static const Color primaryDeep = Color(0xFF0D2238);
  static const Color secondaryColor = Color(0xFFF5A623);
  static const Color tertiaryColor = Color(0xFF1A7A4A);
  static const Color errorColor = Color(0xFFE84855);
  static const Color warningColor = Color(0xFFF5A623);

  // Health score colors
  static const Color healthGreen = Color(0xFF1A7A4A);
  static const Color healthAmber = Color(0xFFF5A623);
  static const Color healthRed = Color(0xFFE84855);

  // Light surface tokens — kept for backward compat in const contexts
  static const Color surface = Color(0xFFF0EEE9);
  static const Color surfaceLow = Color(0xFFF3F4F6);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B2332);
  static const Color onSurfaceMuted = Color(0xFF374151);
  static const Color onSurfaceSoft = Color(0xFF6B7280);
  static const Color onSurfaceFaint = Color(0xFF9CA3AF);

  static ThemeData get lightTheme => _buildTheme(FarolColors.light, Brightness.light);
  static ThemeData get darkTheme => _buildTheme(FarolColors.dark, Brightness.dark);

  static ThemeData _buildTheme(FarolColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: Colors.white,
        secondary: secondaryColor,
        onSecondary: primaryColor,
        secondaryContainer: c.secondaryContainer,
        onSecondaryContainer: isDark ? secondaryColor : primaryColor,
        tertiary: tertiaryColor,
        onTertiary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.onSurface,
        outline: c.onSurfaceFaint,
      ),
      scaffoldBackgroundColor: c.surface,
      extensions: [c],
      cardTheme: CardThemeData(
        color: c.surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : primaryColor.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme).copyWith(
        displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: c.onSurface),
        displayMedium: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: c.onSurface),
        displaySmall: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: c.onSurface),
        headlineLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: c.onSurface),
        headlineMedium: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: c.onSurface),
        headlineSmall: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: c.onSurface),
        titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: c.onSurface),
        titleMedium: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: c.onSurface),
        titleSmall: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: c.onSurface),
        bodyLarge: GoogleFonts.inter(color: c.onSurface),
        bodyMedium: GoogleFonts.inter(color: c.onSurface),
        bodySmall: GoogleFonts.inter(color: c.onSurfaceSoft),
        labelLarge: GoogleFonts.inter(color: c.onSurface, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: c.onSurfaceSoft),
        labelSmall: GoogleFonts.inter(color: c.onSurfaceSoft),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: c.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? c.surfaceLow.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        indicatorColor: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isSelected ? c.onSurface : c.onSurfaceFaint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? c.onSurface : c.onSurfaceFaint,
            size: 24,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? secondaryColor : primaryColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: c.onSurfaceSoft),
        floatingLabelStyle: TextStyle(color: isDark ? secondaryColor : primaryColor),
        hintStyle: TextStyle(color: c.onSurfaceSoft),
        prefixStyle: TextStyle(color: c.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      // Expense categories
      case 'HOUSING': return const Color(0xFF1B3A5C);
      case 'TRANSPORT': return const Color(0xFFF5A623);
      case 'FOOD_GROCERY': return const Color(0xFF1A7A4A);
      case 'HEALTH': return const Color(0xFFE84855);
      case 'LEISURE': return const Color(0xFF8FA3B8);
      // Investment types
      case 'TESOURO_SELIC': return const Color(0xFF1B3A5C);
      case 'CDB': return const Color(0xFF6B4EAF);
      case 'LCI_LCA': return const Color(0xFF1A7A4A);
      case 'FII': return const Color(0xFFF5A623);
      case 'STOCKS_BR': return const Color(0xFF0D6E6E);
      case 'STOCKS_INTL': return const Color(0xFF1A6BAA);
      case 'PENSION': return const Color(0xFF9E6B3A);
      case 'SAVINGS': return const Color(0xFFB94F82);
      default: return onSurfaceSoft;
    }
  }
}
