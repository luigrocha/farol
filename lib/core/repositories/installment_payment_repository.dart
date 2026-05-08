import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/installment_payment.dart';

class InstallmentPaymentRepository {
  final SupabaseClient _supabase;
  const InstallmentPaymentRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<InstallmentPayment>> getByPlan(String planId) async {
    final data = await _supabase
        .from('installment_payments')
        .select()
        .eq('plan_id', planId)
        .order('installment_num', ascending: true);
    return data.map(InstallmentPayment.fromJson).toList();
  }

  Future<List<InstallmentPayment>> getPending() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('installment_payments')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('due_date', ascending: true);
    return data.map(InstallmentPayment.fromJson).toList();
  }

  /// Pending payments with due_date between [from] and [to] inclusive.
  /// Used by the ForecastingEngine to project cash flow.
  Future<List<InstallmentPayment>> getPendingInRange(
      DateTime from, DateTime to) async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('installment_payments')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .gte('due_date', from.toIso8601String().substring(0, 10))
        .lte('due_date', to.toIso8601String().substring(0, 10))
        .order('due_date', ascending: true);
    return data.map(InstallmentPayment.fromJson).toList();
  }

  Future<List<InstallmentPayment>> insertAll(
      List<InstallmentPayment> payments) async {
    if (payments.isEmpty) return [];
    final rows = payments.map((p) => p.toJson()..remove('id')).toList();
    final data = await _supabase
        .from('installment_payments')
        .insert(rows)
        .select();
    return data.map(InstallmentPayment.fromJson).toList();
  }

  Future<InstallmentPayment> markPaid({
    required String id,
    required DateTime paidDate,
    required double paidAmount,
    required int expenseId,
  }) async {
    final data = await _supabase
        .from('installment_payments')
        .update({
          'status': 'paid',
          'paid_date': paidDate.toIso8601String().substring(0, 10),
          'paid_amount': paidAmount,
          'expense_id': expenseId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return InstallmentPayment.fromJson(data);
  }

  Future<InstallmentPayment> markSkipped(String id) async {
    final data = await _supabase
        .from('installment_payments')
        .update({
          'status': 'skipped',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return InstallmentPayment.fromJson(data);
  }

  /// Marks overdue any pending payments past their due_date.
  /// Call periodically (e.g. on app resume).
  Future<void> syncOverdueStatuses() async {
    final userId = _userId;
    if (userId == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _supabase
        .from('installment_payments')
        .update({
          'status': 'overdue',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('status', 'pending')
        .lt('due_date', today);
  }
}
