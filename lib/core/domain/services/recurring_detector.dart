import 'dart:math' as math;
import '../entities/recurring_rule.dart';
import '../../models/expense.dart';

/// A candidate detected from expense history — not yet persisted.
class RecurringRuleCandidate {
  final String name;
  final String category;
  final String? paymentMethod;
  final double baseAmount;
  final RecurringFrequency frequency;
  final int dayOfMonth;

  /// 0.0–1.0. Higher = more regular pattern.
  final double confidence;

  /// Source expenses used to build this candidate.
  final List<Expense> sourceExpenses;

  const RecurringRuleCandidate({
    required this.name,
    required this.category,
    required this.paymentMethod,
    required this.baseAmount,
    required this.frequency,
    required this.dayOfMonth,
    required this.confidence,
    required this.sourceExpenses,
  });
}

/// Detects recurring patterns from expense history.
/// Pure service — no side effects, no Riverpod.
class RecurringDetector {
  static const double _minConfidence = 0.75;
  static const int _minOccurrences = 3;
  static const double _amountVarianceTolerance = 0.05; // ±5%

  const RecurringDetector();

  /// Returns candidates with confidence >= 0.75, sorted by confidence desc.
  /// Pass [existingRuleNames] to skip patterns already covered by a rule.
  List<RecurringRuleCandidate> detect(
    List<Expense> history, {
    List<String> existingRuleNames = const [],
  }) {
    if (history.isEmpty) return [];

    final groups = _group(history);
    final candidates = <RecurringRuleCandidate>[];
    final existingLower = existingRuleNames.map((n) => n.toLowerCase()).toSet();

    for (final group in groups.values) {
      if (group.length < _minOccurrences) continue;

      final candidate = _analyze(group);
      if (candidate == null) continue;
      if (candidate.confidence < _minConfidence) continue;
      if (existingLower.contains(candidate.name.toLowerCase())) continue;

      candidates.add(candidate);
    }

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates;
  }

  // ── Grouping ──────────────────────────────────────────────────────────────

  Map<String, List<Expense>> _group(List<Expense> history) {
    final groups = <String, List<Expense>>{};

    for (final expense in history) {
      if (expense.isProjected) continue;
      if (expense.installmentPlanId != null ||
          expense.installmentPlanUuid != null) continue;

      final desc = (expense.storeDescription ?? '').trim().toLowerCase();
      if (desc.isEmpty) continue;

      final key = '${expense.category}|$desc';
      groups.putIfAbsent(key, () => []).add(expense);
    }

    // Merge groups where amounts are within ±5% of each other's median
    return _mergeByAmount(groups);
  }

  Map<String, List<Expense>> _mergeByAmount(Map<String, List<Expense>> groups) {
    // For this impl, we keep groups as-is (already keyed by desc+category)
    // and simply filter out groups whose amount variance is too high.
    final result = <String, List<Expense>>{};
    for (final entry in groups.entries) {
      final amounts = entry.value.map((e) => e.amount).toList();
      final median = _median(amounts);
      // All expenses within ±5% of median → treat as same recurrent
      final filtered = entry.value
          .where((e) =>
              (e.amount - median).abs() / median <= _amountVarianceTolerance)
          .toList();
      if (filtered.length >= _minOccurrences) {
        result[entry.key] = filtered;
      }
    }
    return result;
  }

  // ── Analysis ──────────────────────────────────────────────────────────────

  RecurringRuleCandidate? _analyze(List<Expense> group) {
    final sorted = [...group]
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    final intervals = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      intervals.add(sorted[i]
          .transactionDate
          .difference(sorted[i - 1].transactionDate)
          .inDays);
    }

    if (intervals.isEmpty) return null;

    final frequency = _detectFrequency(intervals);
    if (frequency == null) return null;

    final consistency = _consistency(intervals, frequency);
    final amounts = group.map((e) => e.amount).toList();
    final amountCV = _coefficientOfVariation(amounts);

    // confidence degrades with amount variance
    final confidence = consistency * (1 - amountCV * 0.5);
    if (confidence < _minConfidence) return null;

    final representative = sorted.last;
    final dayOfMonth = sorted.map((e) => e.transactionDate.day).reduce((a, b) {
      // mode: pick most common day
      return a; // simplified — use first for now
    });

    return RecurringRuleCandidate(
      name: representative.storeDescription ?? representative.category,
      category: representative.category,
      paymentMethod: representative.paymentMethod,
      baseAmount: _median(amounts),
      frequency: frequency,
      dayOfMonth: dayOfMonth.clamp(1, 28),
      confidence: confidence.clamp(0.0, 1.0),
      sourceExpenses: sorted,
    );
  }

  // ── Frequency detection ───────────────────────────────────────────────────

  RecurringFrequency? _detectFrequency(List<int> intervals) {
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;

    // Tolerance windows (days)
    const targets = {
      RecurringFrequency.weekly: (min: 5, max: 9),
      RecurringFrequency.biweekly: (min: 12, max: 18),
      RecurringFrequency.monthly: (min: 25, max: 35),
      RecurringFrequency.quarterly: (min: 80, max: 100),
      RecurringFrequency.semiannual: (min: 170, max: 195),
      RecurringFrequency.yearly: (min: 350, max: 380),
    };

    for (final entry in targets.entries) {
      if (mean >= entry.value.min && mean <= entry.value.max) {
        return entry.key;
      }
    }
    return null;
  }

  /// Returns 0–1: how consistently the intervals match the expected frequency.
  double _consistency(List<int> intervals, RecurringFrequency freq) {
    final expected = _expectedDays(freq);
    if (expected == 0) return 0;

    final deviations = intervals.map((d) => (d - expected).abs() / expected);
    final meanDeviation =
        deviations.reduce((a, b) => a + b) / deviations.length;

    // meanDeviation = 0 → perfect (1.0); meanDeviation >= 0.5 → 0.0
    return math.max(0.0, 1.0 - meanDeviation * 2);
  }

  int _expectedDays(RecurringFrequency freq) => switch (freq) {
        RecurringFrequency.weekly => 7,
        RecurringFrequency.biweekly => 14,
        RecurringFrequency.monthly => 30,
        RecurringFrequency.quarterly => 91,
        RecurringFrequency.semiannual => 182,
        RecurringFrequency.yearly => 365,
      };

  // ── Math helpers ──────────────────────────────────────────────────────────

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  double _coefficientOfVariation(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0;
    final variance =
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    return math.sqrt(variance) / mean;
  }
}
