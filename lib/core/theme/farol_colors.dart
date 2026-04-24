import 'package:flutter/material.dart';

class FarolColors extends ThemeExtension<FarolColors> {
  final Color surface;
  final Color surfaceLow;
  final Color surfaceLowest;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceSoft;
  final Color onSurfaceFaint;
  final Color secondaryContainer;
  final Color iconTintBlue;
  final Color iconTintRed;

  const FarolColors({
    required this.surface,
    required this.surfaceLow,
    required this.surfaceLowest,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceSoft,
    required this.onSurfaceFaint,
    required this.secondaryContainer,
    required this.iconTintBlue,
    required this.iconTintRed,
  });

  static const light = FarolColors(
    surface: Color(0xFFF0EEE9),
    surfaceLow: Color(0xFFF3F4F6),
    surfaceLowest: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B2332),
    onSurfaceMuted: Color(0xFF374151),
    onSurfaceSoft: Color(0xFF6B7280),
    onSurfaceFaint: Color(0xFF9CA3AF),
    secondaryContainer: Color(0xFFFDF1DB),
    iconTintBlue: Color(0xFFE3ECFA),
    iconTintRed: Color(0xFFFDE7E5),
  );

  static const dark = FarolColors(
    surface: Color(0xFF0D1B2A),
    surfaceLow: Color(0xFF122234),
    surfaceLowest: Color(0xFF1C3047),
    onSurface: Color(0xFFEEF0F3),
    onSurfaceMuted: Color(0xFFC0C7D0),
    onSurfaceSoft: Color(0xFF7D8C9B),
    onSurfaceFaint: Color(0xFF4E5C6E),
    secondaryContainer: Color(0xFF2C1F05),
    iconTintBlue: Color(0xFF162637),
    iconTintRed: Color(0xFF2D1215),
  );

  @override
  FarolColors copyWith({
    Color? surface,
    Color? surfaceLow,
    Color? surfaceLowest,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? onSurfaceSoft,
    Color? onSurfaceFaint,
    Color? secondaryContainer,
    Color? iconTintBlue,
    Color? iconTintRed,
  }) {
    return FarolColors(
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceLowest: surfaceLowest ?? this.surfaceLowest,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      onSurfaceSoft: onSurfaceSoft ?? this.onSurfaceSoft,
      onSurfaceFaint: onSurfaceFaint ?? this.onSurfaceFaint,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      iconTintBlue: iconTintBlue ?? this.iconTintBlue,
      iconTintRed: iconTintRed ?? this.iconTintRed,
    );
  }

  @override
  FarolColors lerp(FarolColors? other, double t) {
    if (other == null) return this;
    return FarolColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceLowest: Color.lerp(surfaceLowest, other.surfaceLowest, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      onSurfaceSoft: Color.lerp(onSurfaceSoft, other.onSurfaceSoft, t)!,
      onSurfaceFaint: Color.lerp(onSurfaceFaint, other.onSurfaceFaint, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      iconTintBlue: Color.lerp(iconTintBlue, other.iconTintBlue, t)!,
      iconTintRed: Color.lerp(iconTintRed, other.iconTintRed, t)!,
    );
  }
}

extension FarolColorsContext on BuildContext {
  FarolColors get colors =>
      Theme.of(this).extension<FarolColors>() ?? FarolColors.light;
}
