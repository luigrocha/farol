import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'farol_colors.dart' as tokens;
import '../core/theme/farol_colors.dart';

ThemeData get farolLightTheme => _build(
      ext: FarolColors.light,
      brightness: Brightness.light,
      surface: tokens.FarolColors.lSurface,
      surfaceLow: tokens.FarolColors.lSurfaceLow,
      surfaceLowest: tokens.FarolColors.lSurfaceLowest,
      onSurface: tokens.FarolColors.lOnSurface,
      onSurfaceSoft: tokens.FarolColors.lOnSurfaceSoft,
      onSurfaceFaint: tokens.FarolColors.lOnSurfaceFaint,
      secondaryContainer: tokens.FarolColors.lSecondaryContainer,
    );

ThemeData get farolDarkTheme => _build(
      ext: FarolColors.dark,
      brightness: Brightness.dark,
      surface: tokens.FarolColors.dSurface,
      surfaceLow: tokens.FarolColors.dSurfaceLow,
      surfaceLowest: tokens.FarolColors.dSurfaceLowest,
      onSurface: tokens.FarolColors.dOnSurface,
      onSurfaceSoft: tokens.FarolColors.dOnSurfaceSoft,
      onSurfaceFaint: tokens.FarolColors.dOnSurfaceFaint,
      secondaryContainer: tokens.FarolColors.dSecondaryContainer,
    );

ThemeData _build({
  required FarolColors ext,
  required Brightness brightness,
  required Color surface,
  required Color surfaceLow,
  required Color surfaceLowest,
  required Color onSurface,
  required Color onSurfaceSoft,
  required Color onSurfaceFaint,
  required Color secondaryContainer,
}) {
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: tokens.FarolColors.navy,
      onPrimary: Colors.white,
      primaryContainer: tokens.FarolColors.lPrimaryContainer,
      onPrimaryContainer: Colors.white,
      secondary: tokens.FarolColors.beam,
      onSecondary: tokens.FarolColors.navyDeep,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer:
          isDark ? tokens.FarolColors.beam : tokens.FarolColors.navy,
      tertiary: tokens.FarolColors.tide,
      onTertiary: Colors.white,
      error: tokens.FarolColors.coral,
      onError: Colors.white,
      surface: surfaceLowest,
      onSurface: onSurface,
      outline: onSurfaceFaint,
    ),
    scaffoldBackgroundColor: surface,
    extensions: [ext],
    cardTheme: CardThemeData(
      color: surfaceLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : tokens.FarolColors.navy.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      displayLarge:
          GoogleFonts.manrope(fontWeight: FontWeight.w800, color: onSurface),
      displayMedium:
          GoogleFonts.manrope(fontWeight: FontWeight.w800, color: onSurface),
      displaySmall:
          GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
      headlineLarge:
          GoogleFonts.manrope(fontWeight: FontWeight.w800, color: onSurface),
      headlineMedium:
          GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
      headlineSmall:
          GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
      titleLarge:
          GoogleFonts.manrope(fontWeight: FontWeight.w700, color: onSurface),
      titleMedium:
          GoogleFonts.manrope(fontWeight: FontWeight.w600, color: onSurface),
      titleSmall:
          GoogleFonts.manrope(fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: GoogleFonts.inter(color: onSurface),
      bodyMedium: GoogleFonts.inter(color: onSurface),
      bodySmall: GoogleFonts.inter(color: onSurfaceSoft),
      labelLarge:
          GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(color: onSurfaceSoft),
      labelSmall: GoogleFonts.inter(color: onSurfaceSoft),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.manrope(
        color: tokens.FarolColors.navy,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark
          ? surfaceLow.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.85),
      elevation: 0,
      indicatorColor: tokens.FarolColors.navy.withValues(alpha: isDark ? 0.2 : 0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: isSelected ? onSurface : onSurfaceFaint,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? onSurface
              : onSurfaceFaint,
          size: 24,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLowest,
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
        borderSide: BorderSide(
          color: isDark ? tokens.FarolColors.beam : tokens.FarolColors.navy,
          width: 1.5,
        ),
      ),
      labelStyle: TextStyle(color: onSurfaceSoft),
      floatingLabelStyle: TextStyle(
        color: isDark ? tokens.FarolColors.beam : tokens.FarolColors.navy,
      ),
      hintStyle: TextStyle(color: onSurfaceSoft),
      prefixStyle: TextStyle(color: onSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
