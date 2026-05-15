/// InviteNotificationOverlay — persistent workspace invite banner.
///
/// Displayed as an overlay at the top of the screen when the authenticated user
/// has unread workspace_invite notifications. Stays visible until the user taps
/// "Aceitar" or "Recusar" — unlike a MaterialBanner it does not auto-dismiss.
///
/// Flow:
///   Accept → calls accept-workspace-invite Edge Function → refreshes workspaces
///            → marks notification read → shows inline ✓ confirmation → auto-closes
///   Decline → marks invite declined_at → marks notification read → shows inline message
///           → auto-closes
///
/// The owner is notified in both cases via the DB trigger on workspace_invites
/// (trg_notify_owner_invite_resolved, V41 migration).
library invite_notification_overlay;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/user_notification.dart';
import '../../core/providers/workspace_providers.dart';
import '../../core/repositories/workspace_repository.dart';
import '../../design/ds_tokens.dart';
import '../../design/farol_colors.dart' as tokens;

// ── InviteNotificationManager ─────────────────────────────────────────────────
//
// Drop this widget inside the widget tree (e.g. in MainShell above the screen
// stack). It watches pendingInviteNotificationsProvider and shows
// InviteNotificationBanner as an overlay for each new invite in sequence.

class InviteNotificationManager extends ConsumerStatefulWidget {
  const InviteNotificationManager({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InviteNotificationManager> createState() =>
      _InviteNotificationManagerState();
}

class _InviteNotificationManagerState
    extends ConsumerState<InviteNotificationManager> {
  final _shown = <String>{};

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(pendingInviteNotificationsProvider);
    final notifications = notificationsAsync.valueOrNull ?? [];

    // Only workspace_invite type shown as banner; others handled differently
    final invites = notifications
        .where((n) => n.notificationType == NotificationType.workspaceInvite)
        .toList();

    // Find the first new invite we haven't shown yet
    UserNotification? toShow;
    for (final n in invites) {
      if (!_shown.contains(n.id)) {
        toShow = n;
        break;
      }
    }

    return Stack(
      children: [
        widget.child,
        if (toShow != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _InviteBanner(
              notification: toShow,
              onDismissed: () {
                _shown.add(toShow!.id);
                setState(() {});
              },
            ),
          ),
      ],
    );
  }
}

// ── _InviteBanner ─────────────────────────────────────────────────────────────

enum _BannerState { idle, accepting, declining, accepted, declined, error }

class _InviteBanner extends ConsumerStatefulWidget {
  const _InviteBanner({
    required this.notification,
    required this.onDismissed,
  });

  final UserNotification notification;
  final VoidCallback onDismissed;

  @override
  ConsumerState<_InviteBanner> createState() => _InviteBannerState();
}

class _InviteBannerState extends ConsumerState<_InviteBanner>
    with SingleTickerProviderStateMixin {
  _BannerState _state = _BannerState.idle;
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: DSDuration.medium);
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: DSCurve.enter));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Accept ────────────────────────────────────────────────────────────────

  Future<void> _accept() async {
    if (_state != _BannerState.idle) return;
    setState(() => _state = _BannerState.accepting);

    try {
      final repo = ref.read(workspaceRepositoryProvider);
      await repo.acceptInviteViaEdgeFunction(widget.notification.inviteToken);

      // Refresh workspaces
      ref.invalidate(userWorkspacesProvider);
      ref.invalidate(activeWorkspaceProvider);

      // Mark notification as read
      await _markRead();

      if (!mounted) return;
      setState(() => _state = _BannerState.accepted);
      _scheduleDismiss();
    } on WorkspaceInviteException catch (e) {
      if (!mounted) return;
      // already_member is fine — just mark read and dismiss
      if (e.code == 'already_member') {
        await _markRead();
        if (!mounted) return;
        _dismiss();
      } else {
        setState(() => _state = _BannerState.error);
        _scheduleDismiss(delay: const Duration(seconds: 4));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _BannerState.error);
      _scheduleDismiss(delay: const Duration(seconds: 4));
    }
  }

  // ── Decline ───────────────────────────────────────────────────────────────

  Future<void> _decline() async {
    if (_state != _BannerState.idle) return;
    setState(() => _state = _BannerState.declining);

    try {
      final repo = ref.read(workspaceRepositoryProvider);
      await repo.declineInvite(widget.notification.inviteToken);
    } catch (_) {
      // Best-effort — even if decline fails server-side, dismiss for the user
    }

    await _markRead();
    if (!mounted) return;
    setState(() => _state = _BannerState.declined);
    _scheduleDismiss();
  }

  Future<void> _markRead() async {
    try {
      final repo = ref.read(userNotificationsRepositoryProvider);
      await repo.markRead(widget.notification.id);
      ref.invalidate(pendingInviteNotificationsProvider);
    } catch (_) {}
  }

  void _scheduleDismiss({Duration delay = const Duration(seconds: 2)}) {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(delay, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            borderRadius: DSRadius.lgBR,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A42),
                borderRadius: DSRadius.lgBR,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(DSSpacing.lg),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_state) {
      _BannerState.idle      => _buildIdle(),
      _BannerState.accepting => _buildBusy('Aceitando convite...'),
      _BannerState.declining => _buildBusy('Recusando convite...'),
      _BannerState.accepted  => _buildResult(
          icon: Icons.check_circle_rounded,
          color: Colors.green,
          message: 'Você entrou em "${widget.notification.workspaceName}"!',
        ),
      _BannerState.declined  => _buildResult(
          icon: Icons.do_not_disturb_rounded,
          color: Colors.white54,
          message: 'Convite recusado.',
        ),
      _BannerState.error     => _buildResult(
          icon: Icons.error_outline_rounded,
          color: tokens.FarolColors.coral,
          message: 'Não foi possível processar. Tente pelo link do convite.',
        ),
    };
  }

  Widget _buildIdle() {
    final notif = widget.notification;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Workspace avatar ──────────────────────────────────────────────
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tokens.FarolColors.beam.withValues(alpha: 0.15),
            borderRadius: DSRadius.mdBR,
            border: Border.all(
              color: tokens.FarolColors.beam.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.group_add_outlined,
            color: tokens.FarolColors.beam,
            size: 22,
          ),
        ),
        const SizedBox(width: DSSpacing.md),

        // ── Text ──────────────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${notif.invitedByName} te convidou',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '"${notif.workspaceName}" · ${_roleLabel(notif.role)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.60),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: DSSpacing.sm),

        // ── Decline button ────────────────────────────────────────────────
        _ActionBtn(
          label: 'Recusar',
          onTap: _decline,
          filled: false,
        ),
        const SizedBox(width: DSSpacing.xs),

        // ── Accept button ─────────────────────────────────────────────────
        _ActionBtn(
          label: 'Aceitar',
          onTap: _accept,
          filled: true,
        ),
      ],
    );
  }

  Widget _buildBusy(String label) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: tokens.FarolColors.beam,
          ),
        ),
        const SizedBox(width: DSSpacing.md),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }

  Widget _buildResult({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: DSSpacing.md),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) => switch (role) {
    'admin'  => 'Admin',
    'viewer' => 'Visualizador',
    _        => 'Membro',
  };
}

// ── _ActionBtn ────────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DSDuration.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: DSSpacing.md,
            vertical: DSSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.filled
                ? (_hovered
                    ? tokens.FarolColors.beam.withValues(alpha: 0.90)
                    : tokens.FarolColors.beam)
                : (_hovered
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.06)),
            borderRadius: DSRadius.smBR,
            border: widget.filled
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.filled
                  ? tokens.FarolColors.navy
                  : Colors.white.withValues(alpha: 0.80),
            ),
          ),
        ),
      ),
    );
  }
}
