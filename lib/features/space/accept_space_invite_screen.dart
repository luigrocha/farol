// lib/features/space/accept_space_invite_screen.dart
//
// Shown when the user opens a space invite link (farol.app/join/:token).
// Handles both authenticated and unauthenticated states.
//
// Flow:
//   1. If not logged in → show login CTA, preserve token in navigation args
//   2. If logged in → call accept-space-invite Edge Function
//   3. On success → show joined space info, offer to navigate to it
//   4. On error → show localized error message

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/space.dart';
import '../../core/providers/space_providers.dart';
import '../../core/repositories/space_repository.dart' show SpaceInviteException;
import '../../design/farol_colors.dart' as tokens;
import '../../design/branding/branding.dart';
import '../auth/domain/auth_state.dart';
import '../auth/presentation/auth_providers.dart';
import 'space_dashboard_screen.dart';

class AcceptSpaceInviteScreen extends ConsumerStatefulWidget {
  const AcceptSpaceInviteScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptSpaceInviteScreen> createState() =>
      _AcceptSpaceInviteScreenState();
}

class _AcceptSpaceInviteScreenState
    extends ConsumerState<AcceptSpaceInviteScreen> {
  _ScreenState _state = _ScreenState.idle;
  String?      _errorMessage;
  Space?       _joinedSpace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAccept());
  }

  Future<void> _tryAccept() async {
    final authState = ref.read(authStateProvider).value;
    if (authState == null || authState is AppAuthUnauthenticated) {
      setState(() => _state = _ScreenState.notAuthed);
      return;
    }
    await _doAccept();
  }

  Future<void> _doAccept() async {
    if (!mounted) return;
    setState(() {
      _state        = _ScreenState.loading;
      _errorMessage = null;
    });

    try {
      final repo  = ref.read(spaceRepositoryProvider);
      final space = await repo.acceptSpaceInviteViaEdgeFunction(widget.token);

      if (!mounted) return;
      _joinedSpace = space;

      // Refresh space list and auto-select the new space
      ref.invalidate(userSpacesProvider);
      await ref.read(activeSpaceProvider.notifier).select(space);

      if (!mounted) return;
      setState(() => _state = _ScreenState.success);
    } on SpaceInviteException catch (e) {
      if (!mounted) return;
      setState(() {
        _state        = _ScreenState.error;
        _errorMessage = _mapCode(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state        = _ScreenState.error;
        _errorMessage = 'Convite não encontrado ou inválido.';
      });
    }
  }

  String _mapCode(String code) => switch (code) {
    'invite_expired'     => 'Este convite expirou. Peça um novo link ao administrador do espaço.',
    'invite_already_used'=> 'Este link já foi usado. Solicite um novo convite se necessário.',
    'already_member'     => 'Você já é membro deste espaço.',
    'invite_not_found'   => 'Convite não encontrado ou inválido.',
    _                    => 'Não foi possível aceitar o convite. Tente novamente.',
  };

  // ── Navigate to the joined space ────────────────────────────────

  void _goToSpace() {
    final space = _joinedSpace;
    if (space == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
      return;
    }
    // Remove everything up to / and push the space dashboard
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (r) => false,
    );
    // The dashboard is the root — SpaceDashboardScreen is pushed modally
    // after the main shell settles, using a post-frame callback so the
    // navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SpaceDashboardScreen.push(context, space);
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width:  double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
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
                    // ── Logo ────────────────────────────────────────────
                    FarolMark(
                      size: FarolBrand.markSizeAuth,
                      radius: 16,
                      variant: FarolLogoVariant.dark,
                      showGlow: true,
                    ),
                    const SizedBox(height: 32),

                    // ── State-based content ──────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: switch (_state) {
                        _ScreenState.notAuthed => _buildNotAuthed(context),
                        _ScreenState.idle      => _buildLoading(),
                        _ScreenState.loading   => _buildLoading(),
                        _ScreenState.success   => _buildSuccess(context),
                        _ScreenState.error     => _buildError(context),
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

  // ── Not authenticated ──────────────────────────────────────────────────────

  Widget _buildNotAuthed(BuildContext context) {
    return Column(
      key: const ValueKey('not_authed'),
      children: [
        const Icon(Icons.group_add_outlined, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(
          'Você foi convidado para um espaço',
          style: GoogleFonts.manrope(
            fontSize:      22,
            fontWeight:    FontWeight.w800,
            color:         Colors.white,
            letterSpacing: -0.5,
            height:        1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Entre na sua conta ou crie uma para aceitar o convite.',
          style: TextStyle(
            fontSize: 14,
            color:    Colors.white.withValues(alpha: 0.72),
            height:   1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width:  double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/login',
              arguments: {'pendingSpaceInviteToken': widget.token},
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.FarolColors.beam,
              foregroundColor: tokens.FarolColors.navy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize:   15,
              ),
            ),
            child: const Text('Entrar para aceitar'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pushNamed(
            context,
            '/signup',
            arguments: {'pendingSpaceInviteToken': widget.token},
          ),
          child: Text(
            'Criar conta',
            style: TextStyle(
              color:    Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading({String? label}) {
    return Column(
      key: ValueKey('loading_${label ?? ''}'),
      children: [
        const SizedBox(
          width:  48,
          height: 48,
          child:  CircularProgressIndicator(
            strokeWidth: 3,
            color:       tokens.FarolColors.beam,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          label ?? 'Aceitando convite...',
          style: TextStyle(
            fontSize:   16,
            color:      Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Success ────────────────────────────────────────────────────────────────

  Widget _buildSuccess(BuildContext context) {
    final space = _joinedSpace;
    return Column(
      key: const ValueKey('success'),
      children: [
        // Space emoji or success icon
        if (space?.emoji != null) ...[
          Text(space!.emoji!, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
        ] else ...[
          Container(
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              color:  Colors.green.withValues(alpha: 0.18),
              shape:  BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.green,
              size:  40,
            ),
          ),
          const SizedBox(height: 20),
        ],

        Text(
          'Bem-vindo ao espaço!',
          style: GoogleFonts.manrope(
            fontSize:      22,
            fontWeight:    FontWeight.w800,
            color:         Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        if (space != null) ...[
          const SizedBox(height: 8),
          Text(
            space.name,
            style: TextStyle(
              fontSize:   16,
              color:      Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            space.type.label,
            style: TextStyle(
              fontSize: 13,
              color:    Colors.white.withValues(alpha: 0.50),
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 32),

        SizedBox(
          width:  double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goToSpace,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.FarolColors.beam,
              foregroundColor: tokens.FarolColors.navy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize:   15,
              ),
            ),
            child: const Text('Ir para o espaço'),
          ),
        ),
      ],
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context) {
    return Column(
      key: const ValueKey('error'),
      children: [
        Container(
          width:  64,
          height: 64,
          decoration: BoxDecoration(
            color:  Colors.red.withValues(alpha: 0.14),
            shape:  BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size:  36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _errorMessage ?? 'Convite não encontrado ou inválido.',
          style: TextStyle(
            fontSize: 16,
            color:    Colors.white.withValues(alpha: 0.88),
            height:   1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width:  double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.30),
              ),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Ir para o app'),
          ),
        ),
      ],
    );
  }
}

enum _ScreenState { idle, notAuthed, loading, success, error }
