// lib/features/space/space_app_bar_chip.dart
// AppBar chip that shows the currently active Space.
//
// Mirrors WorkspaceAppBarChip's design but for Spaces:
//   • Tinted with the space's accent color (or indigo fallback)
//   • Tapping opens WorkspaceSwitcherSheet (same entry point)
//   • Hidden when no space is active (user is in Personal Ledger context)
//
// Usage: place in your scaffold's AppBar actions or title area alongside
// WorkspaceAppBarChip. Typically shown instead of WorkspaceAppBarChip when
// the user is viewing SpaceDashboardScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/space_providers.dart';
import '../workspace/workspace_switcher_sheet.dart';

class SpaceAppBarChip extends ConsumerWidget {
  const SpaceAppBarChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceAsync = ref.watch(activeSpaceProvider);
    final space = spaceAsync.valueOrNull;

    if (space == null) return const SizedBox.shrink();

    final accentColor = _parseColor(space.color) ?? const Color(0xFF6366F1);
    final bgColor = accentColor.withValues(alpha: 0.15);
    final fgColor = accentColor;

    return GestureDetector(
      onTap: () => WorkspaceSwitcherSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (space.emoji != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  space.emoji!,
                  style: const TextStyle(fontSize: 13),
                ),
              )
            else
              Icon(Icons.workspaces_outlined, size: 14, color: fgColor),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                space.name,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: fgColor),
          ],
        ),
      ),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }
}
