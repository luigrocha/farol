import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/workspace_providers.dart';
import '../../design/farol_colors.dart' as tokens;
import '../auth/presentation/auth_providers.dart';
import '../auth/domain/auth_state.dart';

/// Shown when the user opens a workspace invite link (deep link or web route).
/// Handles both authenticated and unauthenticated states.
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAccept());
  }

  Future<void> _tryAccept() async {
    final authState = ref.read(authStateProvider).value;
    if (authState == null || authState is AppAuthUnauthenticated) {
      // Not logged in — show login CTA, pass token via route args after login
      return;
    }
    await _doAccept();
  }

  Future<void> _doAccept() async {
    setState(() {
      _state = _ScreenState.loading;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final success = await repo.acceptInvite(widget.token);
      if (!mounted) return;

      if (success) {
        // Refresh workspace list so the new one appears
        ref.invalidate(userWorkspacesProvider);
        setState(() => _state = _ScreenState.success);
      } else {
        setState(() {
          _state = _ScreenState.error;
          _errorMessage = AppLocalizations.of(context).inviteErrorNotFound;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final msg = _mapError(e.toString(), l10n);
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = msg;
      });
    }
  }

  String _mapError(String error, AppLocalizations l10n) {
    if (error.contains('invite_expired')) return l10n.inviteErrorExpired;
    if (error.contains('invite_already_used')) return l10n.inviteErrorUsed;
    if (error.contains('already_member')) return l10n.inviteErrorMember;
    if (error.contains('invite_not_found')) return l10n.inviteErrorNotFound;
    return l10n.inviteErrorNotFound;
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context);
    final isAuthed = authAsync.value is AppAuthAuthenticated;

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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: tokens.FarolColors.beam,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: tokens.FarolColors.beam.withValues(alpha: 0.40),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.anchor_rounded,
                        color: tokens.FarolColors.navy,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── State-based content ───────────────────────────────
                    if (!isAuthed) ...[
                      _buildNotAuthed(context, l10n),
                    ] else if (_state == _ScreenState.loading) ...[
                      _buildLoading(l10n),
                    ] else if (_state == _ScreenState.success) ...[
                      _buildSuccess(context, l10n),
                    ] else if (_state == _ScreenState.error) ...[
                      _buildError(context, l10n),
                    ] else ...[
                      _buildLoading(l10n),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotAuthed(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        const Icon(Icons.group_add_outlined, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(
          'You have been invited to join a workspace',
          style: GoogleFonts.manrope(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
              letterSpacing: -0.5, height: 1.1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Log in or create an account to accept the invite.',
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
              textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
            child: Text(l10n.inviteLoginToAccept),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signup',
              arguments: {'pendingInviteToken': widget.token}),
          child: Text('Create account',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildLoading(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
              strokeWidth: 3, color: tokens.FarolColors.beam),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.inviteAccepting,
          style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.green, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to the workspace!',
          style: GoogleFonts.manrope(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
              letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
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
              textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
            child: Text(l10n.inviteGoWorkspace),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations l10n) {
    return Column(
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
            child: const Text('Go to app'),
          ),
        ),
      ],
    );
  }
}

enum _ScreenState { idle, loading, success, error }
