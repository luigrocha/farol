class FinancialPeriod {
  final DateTime start;
  final DateTime end;

  const FinancialPeriod({required this.start, required this.end});

  /// Computes the period that contains [now] given a [cutoffDay] (1–28).
  ///
  /// Example: cutoffDay=15, today=Apr 20 → start=Apr 15, end=May 14.
  /// Example: cutoffDay=15, today=Apr 10 → start=Mar 15, end=Apr 14.
  static FinancialPeriod current(int cutoffDay, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final DateTime start;

    if (today.day >= cutoffDay) {
      start = DateTime(today.year, today.month, cutoffDay);
    } else {
      start = DateTime(today.year, today.month - 1, cutoffDay);
    }

    // end = day before the NEXT cutoff tick
    final nextCutoff = DateTime(start.year, start.month + 1, cutoffDay);
    final end = nextCutoff.subtract(const Duration(days: 1));

    return FinancialPeriod(start: start, end: end);
  }

  /// Returns the period immediately before [this].
  FinancialPeriod get previous {
    final prevEnd = start.subtract(const Duration(days: 1));
    final ps = DateTime(start.year, start.month - 1, start.day);
    return FinancialPeriod(start: ps, end: prevEnd);
  }

  /// Returns the period immediately after [this].
  FinancialPeriod get next {
    final nextStart = end.add(const Duration(days: 1));
    final nextEnd = DateTime(nextStart.year, nextStart.month + 1, nextStart.day)
        .subtract(const Duration(days: 1));
    return FinancialPeriod(start: nextStart, end: nextEnd);
  }

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  String get startIso => dateStr(start);
  String get endIso => dateStr(end);

  String get label {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final s = '${start.day} ${months[start.month - 1]}';
    final e = '${end.day} ${months[end.month - 1]}';
    return '$s – $e';
  }

  static String dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is FinancialPeriod && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}
