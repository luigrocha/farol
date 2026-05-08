enum RecurringFrequency {
  weekly,
  biweekly,
  monthly,
  quarterly,
  semiannual,
  yearly;

  static RecurringFrequency fromString(String v) =>
      RecurringFrequency.values.firstWhere((e) => e.name == v);

  String get label => switch (this) {
        weekly => 'Semanal',
        biweekly => 'Quinzenal',
        monthly => 'Mensal',
        quarterly => 'Trimestral',
        semiannual => 'Semestral',
        yearly => 'Anual',
      };
}

enum RecurringStatus {
  active,
  paused,
  cancelled;

  static RecurringStatus fromString(String v) =>
      RecurringStatus.values.firstWhere((e) => e.name == v);
}

enum AmountType {
  fixed,
  variable,
  range;

  static AmountType fromString(String v) =>
      AmountType.values.firstWhere((e) => e.name == v);
}

class RecurringRule {
  final String id;
  final String userId;
  final String? categoryId;
  final String? categorySlug;

  final String name;
  final String? description;

  final double baseAmount;
  final AmountType amountType;
  final double? amountMin;
  final double? amountMax;

  final RecurringFrequency frequency;
  final int intervalCount;
  final int? dayOfMonth;
  final List<int>? monthsOfYear;

  final DateTime startsOn;
  final DateTime? endsOn;
  final int? endsAfterN;

  final RecurringStatus status;
  final DateTime? pausedUntil;

  final String? paymentMethod;
  final bool isAutoDetected;
  final double? detectionConfidence;
  final int? legacyExpenseId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringRule({
    required this.id,
    required this.userId,
    this.categoryId,
    this.categorySlug,
    required this.name,
    this.description,
    required this.baseAmount,
    this.amountType = AmountType.fixed,
    this.amountMin,
    this.amountMax,
    required this.frequency,
    this.intervalCount = 1,
    this.dayOfMonth,
    this.monthsOfYear,
    required this.startsOn,
    this.endsOn,
    this.endsAfterN,
    this.status = RecurringStatus.active,
    this.pausedUntil,
    this.paymentMethod,
    this.isAutoDetected = false,
    this.detectionConfidence,
    this.legacyExpenseId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == RecurringStatus.active;
  bool get isPaused => status == RecurringStatus.paused;

  bool isActiveOn(DateTime date) {
    if (status == RecurringStatus.cancelled) return false;
    if (date.isBefore(startsOn)) return false;
    if (endsOn != null && date.isAfter(endsOn!)) return false;
    if (isPaused && pausedUntil != null && !date.isAfter(pausedUntil!)) {
      return false;
    }
    return true;
  }

  factory RecurringRule.fromJson(Map<String, dynamic> json) => RecurringRule(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        categoryId: json['category_id'] as String?,
        categorySlug: json['category_slug'] as String?,
        name: json['name'] as String,
        description: json['description'] as String?,
        baseAmount: (json['base_amount'] as num).toDouble(),
        amountType: AmountType.fromString(
            (json['amount_type'] as String?) ?? 'fixed'),
        amountMin: (json['amount_min'] as num?)?.toDouble(),
        amountMax: (json['amount_max'] as num?)?.toDouble(),
        frequency: RecurringFrequency.fromString(json['frequency'] as String),
        intervalCount: (json['interval_count'] as int?) ?? 1,
        dayOfMonth: json['day_of_month'] as int?,
        monthsOfYear: (json['month_of_year'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
        startsOn: DateTime.parse(json['starts_on'] as String),
        endsOn: json['ends_on'] != null
            ? DateTime.parse(json['ends_on'] as String)
            : null,
        endsAfterN: json['ends_after_n'] as int?,
        status: RecurringStatus.fromString(
            (json['status'] as String?) ?? 'active'),
        pausedUntil: json['paused_until'] != null
            ? DateTime.parse(json['paused_until'] as String)
            : null,
        paymentMethod: json['payment_method'] as String?,
        isAutoDetected: (json['is_auto_detected'] as bool?) ?? false,
        detectionConfidence:
            (json['detection_confidence'] as num?)?.toDouble(),
        legacyExpenseId: json['legacy_expense_id'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (categoryId != null) 'category_id': categoryId,
        if (categorySlug != null) 'category_slug': categorySlug,
        'name': name,
        if (description != null) 'description': description,
        'base_amount': baseAmount,
        'amount_type': amountType.name,
        if (amountMin != null) 'amount_min': amountMin,
        if (amountMax != null) 'amount_max': amountMax,
        'frequency': frequency.name,
        'interval_count': intervalCount,
        if (dayOfMonth != null) 'day_of_month': dayOfMonth,
        if (monthsOfYear != null) 'month_of_year': monthsOfYear,
        'starts_on': startsOn.toIso8601String().substring(0, 10),
        if (endsOn != null)
          'ends_on': endsOn!.toIso8601String().substring(0, 10),
        if (endsAfterN != null) 'ends_after_n': endsAfterN,
        'status': status.name,
        if (pausedUntil != null)
          'paused_until': pausedUntil!.toIso8601String().substring(0, 10),
        if (paymentMethod != null) 'payment_method': paymentMethod,
        'is_auto_detected': isAutoDetected,
        if (detectionConfidence != null)
          'detection_confidence': detectionConfidence,
        if (legacyExpenseId != null) 'legacy_expense_id': legacyExpenseId,
      };
}
