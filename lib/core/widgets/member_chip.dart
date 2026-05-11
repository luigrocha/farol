import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/member_display.dart';

// ─────────────────────────────────────────────────────────────
// MemberChip
// ─────────────────────────────────────────────────────────────
//
// Compact inline chip showing avatar + name for a workspace member.
// Used in transaction tiles, installment tiles, recurring rule tiles
// to show who created the item — but only in shared workspaces.
//
// Usage:
//   MemberChip(member: memberDisplay)
//   MemberChip.compact(member: memberDisplay)  // avatar only

class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.member,
    this.compact = false,
  });

  /// Shows avatar only (no name label).
  const MemberChip.compact({
    super.key,
    required this.member,
  }) : compact = true;

  final MemberDisplay member;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatar = _MemberAvatar(member: member, radius: 10);

    if (compact) return avatar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: 4),
        Text(
          member.displayName,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MemberAvatarGroup
// ─────────────────────────────────────────────────────────────
//
// Overlapping stack of circular avatars, max [maxVisible] shown.
// Excess members shown as "+N" chip.
//
// Usage:
//   MemberAvatarGroup(members: [alice, bob, carol])

class MemberAvatarGroup extends StatelessWidget {
  const MemberAvatarGroup({
    super.key,
    required this.members,
    this.maxVisible = 3,
    this.radius = 12,
  });

  final List<MemberDisplay> members;
  final int maxVisible;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final visible = members.take(maxVisible).toList();
    final overflow = members.length - visible.length;
    final diameter = radius * 2;
    // Each additional avatar overlaps by 1/3 of its diameter
    final overlap = diameter * 0.33;
    final totalWidth = diameter + (visible.length - 1) * (diameter - overlap) +
        (overflow > 0 ? (diameter - overlap) : 0);

    return SizedBox(
      width: totalWidth,
      height: diameter,
      child: Stack(
        children: [
          // Render in reverse so leftmost avatar is on top
          for (int i = visible.length - 1; i >= 0; i--)
            Positioned(
              left: i * (diameter - overlap),
              child: _MemberAvatar(
                member: visible[i],
                radius: radius,
                bordered: true,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (diameter - overlap),
              child: _OverflowBadge(
                count: overflow,
                radius: radius,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Internal: _MemberAvatar
// ─────────────────────────────────────────────────────────────

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.member,
    required this.radius,
    this.bordered = false,
  });

  final MemberDisplay member;
  final double radius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: member.avatarColor,
      backgroundImage: member.photoUrl != null
          ? NetworkImage(member.photoUrl!)
          : null,
      child: member.photoUrl == null
          ? Text(
              member.initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : null,
    );

    if (!bordered) return avatar;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
      child: avatar,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Internal: _OverflowBadge
// ─────────────────────────────────────────────────────────────

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({required this.count, required this.radius});

  final int count;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.surface, width: 1.5),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
