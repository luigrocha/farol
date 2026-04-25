// State preserved: _emailController, _passwordController, _confirmPasswordController,
//   _formKey, _emailRegex, _submit() → authControllerProvider.signUpWithEmail,
//   AuthActionHandler (loading overlay + nav), pop() to go back.
// New state: _obscurePassword, _obscureConfirm, _passwordStrength (0–4).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/widgets/farol_button.dart';
import '../../../core/i18n/app_localizations.dart';
import 'auth_providers.dart';
import 'widgets/auth_buttons.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _passwordStrength = 0; // 0–4

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) score++;
    setState(() => _passwordStrength = score);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cs = Theme.of(context).colorScheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.background,
      body: AuthActionHandler(
        successMessage: l10n.translate('account_created_check_email'),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Back ────────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Title ────────────────────────────────────────────
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: l10n.translate('create_your'),
                        style: GoogleFonts.manrope(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          height: 1.05,
                          color: colors.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: l10n.translate('farol_account'),
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
                    l10n.translate('start_illuminating'),
                    style: GoogleFonts.inter(
                        fontSize: 14, color: colors.onSurfaceSoft, height: 1.5),
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
                    onChanged: _onPasswordChanged,
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
                  const SizedBox(height: 8),

                  // ── Strength meter ───────────────────────────────────
                  _StrengthMeter(strength: _passwordStrength),
                  const SizedBox(height: 12),

                  // ── Confirm password ─────────────────────────────────
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: l10n.translate('confirm_password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) => v == _passwordController.text
                        ? null
                        : l10n.translate('passwords_dont_match'),
                  ),
                  const SizedBox(height: 28),

                  // ── CTA ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FarolButton.primary(
                      label: l10n.translate('create_account_arrow'),
                      onPressed: isLoading ? null : _submit,
                      loading: isLoading,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Sign-in link ─────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context, '/login'),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: l10n.translate('already_have_account'),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: colors.onSurfaceSoft),
                          ),
                          TextSpan(
                            text: l10n.translate('sign_in'),
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

class _StrengthMeter extends StatelessWidget {
  final int strength; // 0–4

  const _StrengthMeter({required this.strength});

  Color _segmentColor(int index, bool isDark) {
    if (index >= strength) {
      return isDark
          ? const Color(0xFF2A2E3A)
          : const Color(0xFFE8EBF0);
    }
    return switch (strength) {
      1 => const Color(0xFFE53935), // error red
      2 => const Color(0xFFFB8C00), // warn orange
      3 => tokens.FarolColors.beam,
      _ => tokens.FarolColors.tide,
    };
  }

  String _label(AppLocalizations l10n) => switch (strength) {
        0 => '',
        1 => l10n.translate('very_weak'),
        2 => l10n.translate('weak'),
        3 => l10n.translate('good'),
        _ => l10n.translate('strong'),
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        ...List.generate(4, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: _segmentColor(i, isDark),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        )),
        if (strength > 0) ...[
          const SizedBox(width: 10),
          Text(
            _label(l10n),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _segmentColor(0, isDark),
            ),
          ),
        ],
      ],
    );
  }
}
