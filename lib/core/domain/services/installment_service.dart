import '../entities/installment_plan.dart';
import '../entities/installment_payment.dart';
import '../../repositories/installment_plan_repository.dart';
import '../../repositories/installment_payment_repository.dart';
import '../../repositories/expense_repository.dart';
import '../../models/financial_period.dart';

class InstallmentService {
  final InstallmentPlanRepository _planRepo;
  final InstallmentPaymentRepository _paymentRepo;
  final ExpenseRepository _expenseRepo;

  const InstallmentService({
    required InstallmentPlanRepository planRepo,
    required InstallmentPaymentRepository paymentRepo,
    required ExpenseRepository expenseRepo,
  })  : _planRepo = planRepo,
        _paymentRepo = paymentRepo,
        _expenseRepo = expenseRepo;

  // ─── createPurchase ───────────────────────────────────────────────────────

  /// Creates an [InstallmentPlan] and automatically generates all N
  /// [InstallmentPayment] rows. Rounding is applied to the last installment
  /// so that the sum of all payments equals [totalAmount] exactly.
  ///
  /// Returns the created plan with paidCount populated.
  Future<InstallmentPlan> createPurchase({
    required String description,
    String? storeName,
    required DateTime purchaseDate,
    required double totalAmount,
    required int numInstallments,
    required String paymentMethod,
    required DateTime firstDueDate,
    String? categoryId,
    String? categorySlug,
    int? cutoffDay,
  }) async {
    assert(numInstallments >= 2, 'Minimum 2 installments');
    assert(totalAmount > 0, 'totalAmount must be positive');

    // Rounding: floor each installment to cents, add remainder to last
    final baseAmount = (totalAmount / numInstallments * 100).floor() / 100;
    final lastAmount =
        double.parse((totalAmount - baseAmount * (numInstallments - 1))
            .toStringAsFixed(2));

    final plan = await _planRepo.create(InstallmentPlan(
      id: '',
      userId: '',
      categoryId: categoryId,
      description: description,
      storeName: storeName,
      purchaseDate: purchaseDate,
      totalAmount: totalAmount,
      numInstallments: numInstallments,
      installmentAmount: baseAmount,
      paymentMethod: paymentMethod,
      firstDueDate: firstDueDate,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final payments = List.generate(numInstallments, (i) {
      final num = i + 1;
      final dueDate = _addMonths(firstDueDate, i);
      final amount = num == numInstallments ? lastAmount : baseAmount;
      final period = cutoffDay != null
          ? FinancialPeriod.current(cutoffDay, now: dueDate)
          : null;

      return InstallmentPayment(
        id: '',
        planId: plan.id,
        userId: plan.userId,
        installmentNum: num,
        dueDate: dueDate,
        amount: amount,
        status: 'pending',
        financialPeriodStart: period?.start,
        financialPeriodEnd: period?.end,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    await _paymentRepo.insertAll(payments);
    return plan;
  }

  // ─── payInstallment ───────────────────────────────────────────────────────

  /// Marks [payment] as paid, creates a real [Expense] linked to it,
  /// and closes the plan if this was the last installment.
  ///
  /// Returns the updated payment.
  Future<InstallmentPayment> payInstallment({
    required InstallmentPayment payment,
    required InstallmentPlan plan,
    DateTime? paidDate,
    double? paidAmount,
  }) async {
    final actualDate = paidDate ?? payment.dueDate;
    final actualAmount = paidDate != null ? (paidAmount ?? payment.amount) : payment.amount;

    // Create the real expense — category slug passed by caller via plan
    final expenseId = await _expenseRepo.insert(
      transactionDate: actualDate,
      month: actualDate.month,
      year: actualDate.year,
      payType: 'Credit',
      category: plan.categorySlug ?? 'card_installments',
      amount: actualAmount,
      paymentMethod: plan.paymentMethod,
      storeDescription:
          plan.storeName ?? '${plan.description} ${payment.installmentNum}/${plan.numInstallments}',
      installmentPlanUuidId: plan.id,
      installmentPaymentId: payment.id,
    );

    // Mark payment as paid
    final updated = await _paymentRepo.markPaid(
      id: payment.id,
      paidDate: actualDate,
      paidAmount: actualAmount,
      expenseId: expenseId,
    );

    // Close plan if all installments are now paid
    final allPayments = await _paymentRepo.getByPlan(plan.id);
    final allPaid = allPayments.every((p) =>
        p.status == 'paid' || p.status == 'skipped' || p.id == payment.id);
    if (allPaid) {
      await _planRepo.updateStatus(plan.id, 'completed');
    }

    return updated;
  }

  // ─── skipInstallment ─────────────────────────────────────────────────────

  /// Marks [payment] as skipped — no expense created.
  Future<InstallmentPayment> skipInstallment(InstallmentPayment payment) {
    return _paymentRepo.markSkipped(payment.id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Adds [months] to [date], clamping day to the last valid day of the result month.
  static DateTime _addMonths(DateTime date, int months) =>
      addMonthsPublic(date, months);

  // Public for unit tests
  static DateTime addMonthsPublic(DateTime date, int months) {
    final targetMonth = date.month + months;
    final year = date.year + (targetMonth - 1) ~/ 12;
    final month = ((targetMonth - 1) % 12) + 1;
    final maxDay = DateTimeExtension.daysInMonth(year, month);
    return DateTime(year, month, date.day.clamp(1, maxDay));
  }

}

extension DateTimeExtension on DateTime {
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
