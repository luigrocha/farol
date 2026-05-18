import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/models/workspace.dart';
import '../../core/providers/workspace_providers.dart';
import '../../core/repositories/workspace_repository.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../design/ds_tokens.dart';
import '../../design/branding/branding.dart';
import '../auth/presentation/auth_providers.dart';
import '../auth/domain/auth_state.dart';

/// Shown when the user opens a workspace invite link (deep link or web route).
/// Handles both authenticated and unauthenticated states.
/// Uses the Edge Function `accept-workspace-invite` which runs with service role
/// — this bypasses the RLS restriction on workspace_invites that would otherwise
/// prevent the invitee from reading the row.
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _errorMessage;
  Workspace? _joinedWorkspace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAccept());
  }

  Future<void> _tryAccept() async {
    final authState = ref.read(authStateProvider).value;
    if (authState == null || authState is AppAuthUnauthenticated) {
      // Not logged in — show login CTA
      setState(() => _state = _ScreenState.notAuthed);
      return;
    }
    await _doAccept();
  }

  Future<void> _doAccept() async {
    if (!mounted) return;
    setState(() {
      _state = _ScreenState.loading;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(workspaceRepositoryProvider);
      // Use the Edge Function — the direct DB query fails due to RLS.
      final workspace = await repo.acceptInviteViaEdgeFunction(widget.token);
      if (!mounted) return;

      _joinedWorkspace = workspace;

      // Refresh workspace list and mark the notification as read
      ref.invalidate(userWorkspacesProvider);
      ref.invalidate(activeWorkspaceProvider);

      // Mark the corresponding user_notification as read
      await _markNotificationRead();

      if (!mounted) return;
      setState(() => _state = _ScreenState.success);
    } on WorkspaceInviteException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = _mapCode(e.code, AppLocalizations.of(context));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = AppLocalizations.of(context).inviteErrorNotFound;
      });
    }
  }


  Future<void> _markNotificationRead() async {
    try {
      final notifications = ref.read(pendingInviteNotificationsProvider).valueOrNull ?? [];
      final matching = notifications.where((n) => n.inviteToken == widget.token);
      if (matching.isEmpty) return;
      final repo = ref.read(userNotificationsRepositoryProvider);
      await repo.markRead(matching.first.id);
      ref.invalidate(pendingInviteNotificationsProvider);
    } catch (_) {}
  }

  String _mapCode(String code, AppLocalizations l10n) => switch (code) {
    'invite_expired'     => l10n.inviteErrorExpired,
    'invite_already_used'=> l10n.inviteErrorUsed,
    'already_member'     => l10n.inviteErrorMember,
    'invite_not_found'   => l10n.inviteErrorNotFound,
    _                    => l10n.inviteErrorNotFound,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              tokens.FarolColors.navy,
              Color(0xFF0F2744),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo ─────────────────────────────────────────────
                    const FarolMark(
                      size: FarolBrand.markSizeAuth,
                      radius: 16,
                      variant: FarolLogoVariant.dark,
                      showGlow: true,
                    ),
                    const SizedBox(height: 32),

                    // ── State-based content ───────────────────────────────
                    AnimatedSwitcher(
                      duration: DSDuration.medium,
                      child: switch (_state) {
                        _ScreenState.notAuthed  => _buildNotAuthed(context, l10n),
                        _ScreenState.idle       => _buildLoading(l10n),
                        _ScreenState.loading    => _buildLoading(l10n),
                        _ScreenState.declining  => _buildLoading(l10n, label: 'Recusando convite...'),
                        _ScreenState.success    => _buildSuccess(context, l10n),
                        _ScreenState.declined   => _buildDeclined(context),
                        _ScreenState.error      => _buildError(context, l10n),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Not authenticated ─────────────────────────────────────────────────────

  Widget _buildNotAuthed(BuildContext context, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('not_authed'),
      children: [
        const Icon(Icons.group_add_outlined, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(
          'Você foi convidado para um workspace',
          style: GoogleFonts.manrope(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
              letterSpacing: -0.5, height: 1.1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Entre na sua conta ou crie uma para aceitar o convite.',
          style: TextStyle(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.72),
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login',
                arguments: {'pendingInviteToken': widget.token}),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.FarolColors.beam,
              foregroundColor: tokens.FarolColors.navy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            child: Text(l10n.inviteLoginToAccept),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signup',
              arguments: {'pendingInviteToken': widget.token}),
          child: Text('Criar conta',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 14)),
        ),
      ],
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading(AppLocalizations l10n, {String? label}) {
    return Column(
      key: ValueKey('loading_${label ?? ''}'),
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
              strokeWidth: 3, color: tokens.FarolColors.beam),
        ),
        const SizedBox(height: 20),
        Text(
          label ?? l10n.inviteAccepting,
          style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Success ───────────────────────────────────────────────────────────────

  Widget _buildSuccess(BuildContext context, AppLocalizations l10n) {
    final ws = _joinedWorkspace;
    return Column(
      key: const ValueKey('success'),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.green, size: 40),
        ),
        const SizedBox(height: 20),
        if (ws?.emoji != null)
          Text(ws!.emoji!, style: const TextStyle(fontSize: 32)),
        if (ws?.emoji != null) const SizedBox(height: 8),
        Text(
          'Bem-vindo ao workspace!',
          style: GoogleFonts.manrope(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
              letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        if (ws != null) ...[
          const SizedBox(height: 8),
          Text(
            ws.name,
            style: TextStyle(
                fontSize: 16, color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.FarolColors.beam,
              foregroundColor: tokens.FarolColors.navy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            child: Text(l10n.inviteGoWorkspace),
          ),
        ),
      ],
    );
  }

  // ── Declined ──────────────────────────────────────────────────────────────

  Widget _buildDeclined(BuildContext context) {
    return Column(
      key: const ValueKey('declined'),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.do_not_disturb_rounded,
              color: Colors.white.withValues(alpha: 0.60), size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Convite recusado',
          style: GoogleFonts.manrope(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
              letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'O proprietário do workspace será notificado.',
          style: TextStyle(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.65),
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Ir para o app'),
          ),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('error'),
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          _errorMessage ?? l10n.inviteErrorNotFound,
          style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Ir para o app'),
          ),
        ),
      ],
    );
  }
}

enum _ScreenState { idle, notAuthed, loading, declining, success, declined, error }
