import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// MemberDisplay — resolved display info for a workspace member
// ─────────────────────────────────────────────────────────────
//
// This is a view-model / value object. It is derived from the
// `profiles` table joined with `workspace_members`, and cached
// in [memberDisplayMapProvider] (keyed by userId).

@immutable
class MemberDisplay {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final Color avatarColor;

  const MemberDisplay({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.avatarColor,
  });

  /// Two-letter initials derived from displayName.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  factory MemberDisplay.fromProfile(
    Map<String, dynamic> profile, {
    required Color avatarColor,
    required String currentUserId,
  }) {
    final userId = profile['id'] as String;
    final rawName = profile['display_name'] as String?;
    final email = profile['email'] as String?;

    // Resolve best display name: profile name → email prefix → userId prefix
    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : userId == currentUserId
            ? 'Você'
            : (email != null && email.isNotEmpty)
                ? email.split('@').first
                : userId.substring(0, 6);

    return MemberDisplay(
      userId: userId,
      displayName: userId == currentUserId ? 'Você' : displayName,
      photoUrl: profile['photo_url'] as String?,
      avatarColor: avatarColor,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar color palette — assigned deterministically by userId
// ─────────────────────────────────────────────────────────────

const _kAvatarColors = [
  Color(0xFF00695C), // teal
  Color(0xFF1565C0), // blue
  Color(0xFF6A1B9A), // purple
  Color(0xFFE65100), // orange
  Color(0xFF2E7D32), // green
  Color(0xFFC62828), // red
  Color(0xFF0277BD), // light blue
  Color(0xFF558B2F), // light green
];

/// Deterministic color from userId — same user always gets same color.
Color avatarColorForUserId(String userId) {
  final hash = userId.codeUnits.fold(0, (sum, c) => sum + c);
  return _kAvatarColors[hash % _kAvatarColors.length];
}
