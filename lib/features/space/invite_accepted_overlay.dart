// lib/features/space/invite_accepted_overlay.dart
//
// In-app banner shown on SpaceDashboardScreen when a new member accepts a
// space invite. Triggered by a 'member_joined' entry in the space activity
// feed (received via spaceActivityRealtimeProvider).
//
// Displayed as a slide-in banner from the top, auto-dismisses after 4 seconds.
// The host widget (SpaceDashboardScreen) manages the overlay lifecycle.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
// Banner widget
// ─────────────────────────────────────────────────────────────────

/// Animated slide-in banner shown when a new member joins the space.
///
/// Wrap the dashboard Scaffold's body in a [Stack] and add this as an overlay:
///
/// ```dart
/// Stack(
///   children: [
///     // ... main dashboard content
///     if (_showInviteBanner)
///       Positioned(
///         top: MediaQuery.of(context).padding.top + 8,
///         left: 16, right: 16,
///         child: InviteAcceptedBanner(
///           memberName: _newMemberName,
///           onDismiss:  () => setState(() => _showInviteBanner = false),
///         ),
///       ),
///   ],
/// )
/// ```
class InviteAcceptedBanner extends StatefulWidget {
  /// Display name of the member who just joined.
  final String memberName;

  /// Initials for the avatar (first 2 chars of name, uppercase).
  final String? initials;

  /// Optional photo URL for the avatar.
  final String? photoUrl;

  /// Avatar background color.
  final Color? avatarColor;

  /// Called when the user dismisses the banner or after auto-dismiss.
  final VoidCallback onDismiss;

  /// How long to show the banner before auto-dismissing.
  final Duration duration;

  const InviteAcceptedBanner({
    super.key,
    required this.memberName,
    required this.onDismiss,
    this.initials,
    this.photoUrl,
    this.avatarColor,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<InviteAcceptedBanner> createState() => _InviteAcceptedBannerState();
}

class _InviteAcceptedBannerState extends State<InviteAcceptedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // Slide in
    _ctrl.forward();

    // Auto-dismiss after [duration]
    Future.delayed(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = widget.initials ??
        widget.memberName
            .substring(0, widget.memberName.length.clamp(1, 2))
            .toUpperCase();
    final bgColor = widget.avatarColor ?? cs.primary;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: cs.surface,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                // Avatar
                widget.photoUrl != null
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(widget.photoUrl!),
                      )
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: bgColor,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                const SizedBox(width: 12),

                // Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.memberName} entrou no espaço 🎉',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Agora é possível dividir os gastos juntos.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Dismiss
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _dismiss,
                  color: cs.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Mixin — wires the overlay into any ConsumerStatefulWidget
// ─────────────────────────────────────────────────────────────────

/// Mixin for screens that want to show [InviteAcceptedBanner] when a
/// `member_joined` activity event arrives via the realtime feed.
///
/// Usage:
/// ```dart
/// class _SpaceDashboardScreenState extends ConsumerState<SpaceDashboardScreen>
///     with InviteAcceptedOverlayMixin {
///
///   @override
///   void initState() {
///     super.initState();
///     listenForMemberJoins(ref, spaceId: widget.space.id);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Stack(
///       children: [
///         // ... main content
///         buildInviteOverlay(context),
///       ],
///     );
///   }
/// }
/// ```
mixin InviteAcceptedOverlayMixin<T extends StatefulWidget> on State<T> {
  String? _pendingMemberName;
  String? _pendingInitials;
  String? _pendingPhotoUrl;
  Color? _pendingAvatarColor;
  bool _showBanner = false;

  /// Call from `initState` to subscribe to member_joined events.
  ///
  /// [displayMap] is the `spaceMemberDisplayMapProvider` value — used to
  /// look up the new member's display name / photo.
  void showBannerForMember({
    required String memberName,
    String? initials,
    String? photoUrl,
    Color? avatarColor,
  }) {
    if (!mounted) return;
    setState(() {
      _pendingMemberName = memberName;
      _pendingInitials = initials;
      _pendingPhotoUrl = photoUrl;
      _pendingAvatarColor = avatarColor;
      _showBanner = true;
    });
  }

  void _hideBanner() {
    if (mounted) setState(() => _showBanner = false);
  }

  /// Returns the overlay widget. Place inside a [Stack] as the last child.
  Widget buildInviteOverlay(BuildContext context) {
    if (!_showBanner || _pendingMemberName == null)
      return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: InviteAcceptedBanner(
        memberName: _pendingMemberName!,
        initials: _pendingInitials,
        photoUrl: _pendingPhotoUrl,
        avatarColor: _pendingAvatarColor,
        onDismiss: _hideBanner,
      ),
    );
  }
}
