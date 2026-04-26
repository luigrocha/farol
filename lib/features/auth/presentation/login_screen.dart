// State preserved: _emailController, _passwordController, _formKey, _emailRegex,
//   _submit() → authControllerProvider.signInWithEmail,
//   _forgotPassword() → authControllerProvider.sendPasswordResetEmail,
//   AuthActionHandler (loading overlay + nav), signInWithGoogle, signInWithApple.
// New state: _obscurePassword for password visibility toggle.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/farol_snackbar.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/widgets/farol_button.dart';
import 'auth_providers.dart';
import 'widgets/auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _forgotPassword() {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email);
      context.showSuccessSnackBar(l10n.recoveryEmailSent);
    } else {
      context.showSuccessSnackBar(l10n.emailRequired);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cs = Theme.of(context).colorScheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: cs.background,
      body: AuthActionHandler(
        successMessage: 'Welcome back!',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ────────────────────────────────────────────
                  const SizedBox(height: 12),
                  _FarolMark(),
                  const SizedBox(height: 28),

                  // ── Title ────────────────────────────────────────────
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: l10n.translate('welcome'),
                        style: GoogleFonts.manrope(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          height: 1.05,
                          color: colors.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: l10n.translate('back'),
                        style: GoogleFonts.manrope(
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.2,
                          height: 1.05,
                          color: colors.onSurfaceSoft,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.translate('login_subtitle'),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.onSurfaceSoft,
                        height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // ── Email ────────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.translate('email'),
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (v) =>
                        _emailRegex.hasMatch(v ?? '') ? null : l10n.translate('invalid_email'),
                  ),
                  const SizedBox(height: 12),

                  // ── Password ─────────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.translate('password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) =>
                        (v?.length ?? 0) >= 6 ? null : l10n.translate('min_6_chars'),
                  ),
                  const SizedBox(height: 4),

                  // ── Remember me + Forgot password ────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(), // placeholder — no local state for remember me
                      TextButton(
                        onPressed: isLoading ? null : _forgotPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: Text(
                          l10n.forgotPassword,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.FarolColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── CTA ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FarolButton.primary(
                      label: l10n.signIn,
                      onPressed: isLoading ? null : _submit,
                      loading: isLoading,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Divider ──────────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: Divider(
                            color: tokens.FarolColors.navy.withOpacity(0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.orSignInWith,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: colors.onSurfaceSoft,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: tokens.FarolColors.navy.withOpacity(0.1))),
                  ]),
                  const SizedBox(height: 20),

                  // ── Social buttons ───────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: _SocialBtn(
                        icon: Icons.g_mobiledata,
                        label: 'Google',
                        onPressed: isLoading
                            ? null
                            : () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SocialBtn(
                        icon: Icons.apple,
                        label: 'Apple',
                        onPressed: isLoading
                            ? null
                            : () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithApple(),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // ── Sign-up link ─────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/signup'),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: l10n.translate('dont_have_account'),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: colors.onSurfaceSoft),
                          ),
                          TextSpan(
                            text: l10n.signUp,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: tokens.FarolColors.navy,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets locais ────────────────────────────────────────────────────────────

class _FarolMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: tokens.FarolColors.navy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.anchor_rounded, color: Colors.white, size: 30),
      ),
    ]);
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialBtn(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: icon == Icons.g_mobiledata ? 28 : 22),
      label: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.onSurfaceFaint),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
