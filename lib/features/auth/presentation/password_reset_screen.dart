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

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString())),
        );
      }
      // On success the authStateProvider stream transitions to AppAuthAuthenticated,
      // and AppEntryPoint navigates to MainShell automatically.
    });

    return Scaffold(
      backgroundColor: cs.background,
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
                      color: tokens.FarolColors.navy.withOpacity(0.08),
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
                        text: 'Nova\n',
                        style: GoogleFonts.manrope(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          height: 1.05,
                          color: colors.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'senha.',
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
                    'Escolha uma senha forte para proteger sua conta.',
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
                      labelText: 'Nova senha',
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
                        (v?.length ?? 0) >= 8 ? null : 'Mínimo 8 caracteres',
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
                      labelText: 'Confirmar nova senha',
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
                        : 'As senhas não coincidem',
                  ),
                  const SizedBox(height: 32),

                  // ── CTA ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FarolButton.primary(
                      label: 'Atualizar senha →',
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

  String _label() => switch (strength) {
        0 => '',
        1 => 'Muito fraca',
        2 => 'Fraca',
        3 => 'Boa',
        _ => 'Forte',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            _label(),
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
