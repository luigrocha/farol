import '../value_objects/money.dart';

enum ScheduledPaymentType { installment, recurring }

class ScheduledPayment {
  final String id;
  final String description;
  final Money amount;
  final DateTime dueDate;
  final ScheduledPaymentType type;
  final String? categorySlug;

  const ScheduledPayment({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.type,
    this.categorySlug,
  });

  int get daysFromNow {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  bool get isOverdue => daysFromNow < 0;
  bool get isDueThisWeek => daysFromNow >= 0 && daysFromNow <= 7;
}
