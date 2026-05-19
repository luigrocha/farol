enum OccurrenceStatus {
  pending,
  paid,
  skipped,
  overridden;

  static OccurrenceStatus fromString(String v) =>
      OccurrenceStatus.values.firstWhere((e) => e.name == v);
}

class RecurringOccurrence {
  final String id;
  final String ruleId;
  final String userId;

  final DateTime scheduledDate;
  final double expectedAmount;

  final OccurrenceStatus status;
  final DateTime? paidDate;
  final double? actualAmount;

  /// bigint FK to expenses.id (matches expenses table PK type)
  final int? expenseId;

  final bool isException;
  final String? exceptionNotes;

  final DateTime createdAt;

  const RecurringOccurrence({
    required this.id,
    required this.ruleId,
    required this.userId,
    required this.scheduledDate,
    required this.expectedAmount,
    this.status = OccurrenceStatus.pending,
    this.paidDate,
    this.actualAmount,
    this.expenseId,
    this.isException = false,
    this.exceptionNotes,
    required this.createdAt,
  });

  bool get isPending => status == OccurrenceStatus.pending;
  bool get isPaid => status == OccurrenceStatus.paid;

  bool get isOverdue => isPending && scheduledDate.isBefore(DateTime.now());

  int get daysUntilDue {
    final today = DateTime.now();
    final due =
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    final now = DateTime(today.year, today.month, today.day);
    return due.difference(now).inDays;
  }

  factory RecurringOccurrence.fromJson(Map<String, dynamic> json) =>
      RecurringOccurrence(
        id: json['id'] as String,
        ruleId: json['rule_id'] as String,
        userId: json['user_id'] as String,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        expectedAmount: (json['expected_amount'] as num).toDouble(),
        status: OccurrenceStatus.fromString(
            (json['status'] as String?) ?? 'pending'),
        paidDate: json['paid_date'] != null
            ? DateTime.parse(json['paid_date'] as String)
            : null,
        actualAmount: (json['actual_amount'] as num?)?.toDouble(),
        expenseId: json['expense_id'] as int?,
        isException: (json['is_exception'] as bool?) ?? false,
        exceptionNotes: json['exception_notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'rule_id': ruleId,
        'user_id': userId,
        'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
        'expected_amount': expectedAmount,
        'status': status.name,
        if (paidDate != null)
          'paid_date': paidDate!.toIso8601String().substring(0, 10),
        if (actualAmount != null) 'actual_amount': actualAmount,
        if (expenseId != null) 'expense_id': expenseId,
        'is_exception': isException,
        if (exceptionNotes != null) 'exception_notes': exceptionNotes,
      };

  RecurringOccurrence copyWith({
    OccurrenceStatus? status,
    DateTime? paidDate,
    double? actualAmount,
    int? expenseId,
    bool? isException,
    String? exceptionNotes,
  }) =>
      RecurringOccurrence(
        id: id,
        ruleId: ruleId,
        userId: userId,
        scheduledDate: scheduledDate,
        expectedAmount: expectedAmount,
        status: status ?? this.status,
        paidDate: paidDate ?? this.paidDate,
        actualAmount: actualAmount ?? this.actualAmount,
        expenseId: expenseId ?? this.expenseId,
        isException: isException ?? this.isException,
        exceptionNotes: exceptionNotes ?? this.exceptionNotes,
        createdAt: createdAt,
      );
}
