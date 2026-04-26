// State preserved: _passwordController, _confirmController, _formKey,
//   _submit() → authControllerProvider.updatePassword,
//   ref.listen error snackbar (success handled by authStateProvider stream).
// New state: _obscurePassword, _obscureConfirm, _passwordStrength (0–4).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/widgets/farol_button.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/farol_snackbar.dart';
import 'auth_providers.dart';
import 'widgets/auth_buttons.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _passwordStrength = 0; // 0–4

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
      ref
          .read(authControllerProvider.notifier)
          .updatePassword(_passwordController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cs = Theme.of(context).colorScheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context);

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        context.showErrorSnackBar(state.error!);
      }
      // On success the authStateProvider stream transitions to AppAuthAuthenticated,
      // and AppEntryPoint navigates to MainShell automatically.
    });

    return Scaffold(
       backgroundColor: cs.surface,
      body: AuthActionHandler(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Icon ─────────────────────────────────────────────
                  const SizedBox(height: 24),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: tokens.FarolColors.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 32,
                      color: tokens.FarolColors.navy,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Title ────────────────────────────────────────────
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: l10n.translate('new_password_title_1'),
                        style: GoogleFonts.manrope(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          height: 1.05,
                          color: colors.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: l10n.translate('new_password_title_2'),
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
                    l10n.translate('choose_strong_password'),
                    style: GoogleFonts.inter(
                        fontSize: 14, color: colors.onSurfaceSoft, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // ── New password ──────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: _onPasswordChanged,
                    decoration: InputDecoration(
                      labelText: l10n.translate('new_password'),
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
                        (v?.length ?? 0) >= 8 ? null : l10n.translate('min_8_chars'),
                  ),
                  const SizedBox(height: 8),

                  // ── Strength meter ───────────────────────────────────
                  _StrengthMeter(strength: _passwordStrength),
                  const SizedBox(height: 12),

                  // ── Confirm password ──────────────────────────────────
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: l10n.translate('confirm_new_password'),
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
                  const SizedBox(height: 32),

                  // ── CTA ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FarolButton.primary(
                      label: l10n.translate('update_password_arrow'),
                      onPressed: isLoading ? null : _submit,
                      loading: isLoading,
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
      1 => const Color(0xFFE53935),
      2 => const Color(0xFFFB8C00),
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
