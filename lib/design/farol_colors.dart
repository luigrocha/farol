import 'package:flutter/material.dart';

class FarolColors {
  // Marca (idénticos en light/dark)
  static const navy = Color(0xFF1B3A5C);
  static const navyDeep = Color(0xFF0D2238);
  static const beam = Color(0xFFF5A623);
  static const tide = Color(0xFF1A7A4A);
  static const coral = Color(0xFFE84855);

  // LIGHT
  static const lSurface = Color(0xFFF0EEE9);
  static const lSurfaceLow = Color(0xFFF3F4F6);
  static const lSurfaceLowest = Color(0xFFFFFFFF);
  static const lSurfaceDim = Color(0xFFE7E4DE);
  static const lOnSurface = Color(0xFF1B2332);
  static const lOnSurfaceMuted = Color(0xFF374151);
  static const lOnSurfaceSoft = Color(0xFF6B7280);
  static const lOnSurfaceFaint = Color(0xFF9CA3AF);
  static const lPrimary = Color(0xFF1B3A5C);
  static const lPrimaryContainer = Color(0xFF244A72);
  static const lSecondary = Color(0xFFF5A623);
  static const lSecondaryContainer = Color(0xFFFDF1DB);
  static const lTertiary = Color(0xFF1A7A4A);
  static const lError = Color(0xFFE84855);
  static const lErrorSoft = Color(0xFFFCE5E7);

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'housing':
        return navy;
      case 'transport':
        return beam;
      case 'food_grocery':
        return tide;
      case 'health':
        return coral;
      case 'leisure':
        return const Color(0xFF8FA3B8);
      case 'subscriptions':
        return const Color(0xFF6B4EAF);
      case 'education':
        return const Color(0xFF9E6B3A);
      case 'card_installments':
        return const Color(0xFFB94F82);
      case 'tesouro_selic':
        return navy;
      case 'cdb':
        return const Color(0xFF6B4EAF);
      case 'lci_lca':
        return tide;
      case 'fii':
        return beam;
      case 'stocks_br':
        return const Color(0xFF0D6E6E);
      case 'stocks_intl':
        return const Color(0xFF1A6BAA);
      case 'pension':
        return const Color(0xFF9E6B3A);
      case 'savings':
        return const Color(0xFFB94F82);
      default:
        // Deterministic color for custom categories
        final colors = [
          navy,
          beam,
          tide,
          coral,
          const Color(0xFF8FA3B8),
          const Color(0xFF6B4EAF),
          const Color(0xFF9E6B3A),
          const Color(0xFFB94F82),
          const Color(0xFF0D6E6E),
          const Color(0xFF1A6BAA),
        ];
        return colors[category.hashCode.abs() % colors.length];
    }
  }

  // DARK
  static const dSurface = Color(0xFF0E1117);
  static const dSurfaceLow = Color(0xFF161A22);
  static const dSurfaceLowest = Color(0xFF1C2029);
  static const dSurfaceDim = Color(0xFF0A0D12);
  static const dOnSurface = Color(0xFFE8EAEE);
  static const dOnSurfaceMuted = Color(0xFFB8BCC6);
  static const dOnSurfaceSoft = Color(0xFF8790A0);
  static const dOnSurfaceFaint = Color(0xFF555E6E);
  static const dPrimary = Color(0xFF3B6A9C);
  static const dPrimaryContainer = Color(0xFF2A5580);
  static const dSecondary = Color(0xFFF5A623);
  static const dSecondaryContainer = Color(0xFF3A2A0A);
  static const dTertiary = Color(0xFF2EB06A);
  static const dError = Color(0xFFF06B76);
  static const dErrorSoft = Color(0xFF3A1418);
}
