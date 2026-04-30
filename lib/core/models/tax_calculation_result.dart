/// Represents a single row in a tax breakdown.
class TaxBreakdownRow {
  /// The label for the breakdown row (e.g., 'Bracket 1', 'Exempt').
  final String label;

  /// The formatted value for the breakdown row (e.g., 'R$ 100,00', 'Isento').
  final String value;

  const TaxBreakdownRow({
    required this.label,
    required this.value,
  });
}

/// Represents the result of a tax calculation, including the total amount
/// and a detailed breakdown of the calculation.
class TaxCalculationResult {
  /// The total calculated tax amount.
  final double total;

  /// A list of rows providing a detailed breakdown of the calculation.
  final List<TaxBreakdownRow> rows;

  const TaxCalculationResult({
    required this.total,
    required this.rows,
  });
}
