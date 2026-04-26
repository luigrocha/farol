import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../farol_colors.dart' as tokens;

enum _FarolButtonVariant { primary, secondary, ghost }

class FarolButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final _FarolButtonVariant _variant;

  const FarolButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  }) : _variant = _FarolButtonVariant.primary;

  const FarolButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  }) : _variant = _FarolButtonVariant.secondary;

  const FarolButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  }) : _variant = _FarolButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(
            label,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          );

    switch (_variant) {
      case _FarolButtonVariant.primary:
        return SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.FarolColors.beam,
              foregroundColor: tokens.FarolColors.navyDeep,
              disabledBackgroundColor: tokens.FarolColors.beam.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: child,
          ),
        );

      case _FarolButtonVariant.secondary:
        return SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.FarolColors.navy,
              side: const BorderSide(color: Color(0xFF1B3A5C), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: child,
          ),
        );

      case _FarolButtonVariant.ghost:
        return TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: tokens.FarolColors.navy,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        );
    }
  }
}
