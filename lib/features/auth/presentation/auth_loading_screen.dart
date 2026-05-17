import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/branding/branding.dart';
import '../domain/auth_state.dart';
import 'auth_providers.dart';

/// Branded transition screen shown after login while auth state propagates.
/// Watches [authStateProvider] and navigates to '/' once authenticated.
class AuthLoadingScreen extends ConsumerStatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  ConsumerState<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends ConsumerState<AuthLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final Animation<double> _pulse;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulse = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _maybeNavigate(AppAuthState state) {
    if (_navigated) return;
    if (state is AppAuthAuthenticated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppAuthState>>(authStateProvider, (_, next) {
      next.whenData(_maybeNavigate);
    });

    // Check current state immediately in case it's already authenticated.
    final current = ref.watch(authStateProvider);
    current.whenData(_maybeNavigate);

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
        child: Stack(
          children: [
            // Aurora blobs
            Positioned(
              top: -80,
              left: -80,
              child: _Aurora(color: tokens.FarolColors.beam.withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: -100,
              right: -60,
              child: _Aurora(color: tokens.FarolColors.tide.withValues(alpha: 0.12)),
            ),

            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated logo
                  ScaleTransition(
                    scale: _pulse,
                    child: FarolMark(
                      size: 72,
                      radius: 22,
                      variant: FarolLogoVariant.dark,
                      showGlow: true,
                      glowOpacity: 0.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Farol',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Spinning arc loader in brand colors
                  AnimatedBuilder(
                    animation: _rotateCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(40, 40),
                      painter: _ArcPainter(progress: _rotateCtrl.value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aurora extends StatelessWidget {
  final Color color;
  const _Aurora({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.65],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Arc (beam color)
    const sweepAngle = math.pi * 1.1;
    final startAngle = progress * 2 * math.pi - math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = tokens.FarolColors.beam
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
