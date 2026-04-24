import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/financial_calculator_service.dart';

class PrivacyAmount extends ConsumerWidget {
  final double value;
  final TextStyle? style;

  const PrivacyAmount({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivate = ref.watch(privacyModeProvider);
    return Text(
      isPrivate ? '••••••' : FinancialCalculatorService.formatBRL(value),
      style: style,
    );
  }
}
