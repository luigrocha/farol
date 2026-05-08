import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/installment_plan.dart';

class InstallmentPlanRepository {
  final SupabaseClient _supabase;
  const InstallmentPlanRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<InstallmentPlan>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('installment_plans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          final plans = rows.map(InstallmentPlan.fromJson).toList();
          return _attachPaidCounts(plans);
        });
  }

  Stream<List<InstallmentPlan>> watchActive() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('installment_plans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('first_due_date', ascending: true)
        .asyncMap((rows) async {
          final plans = rows
              .map(InstallmentPlan.fromJson)
              .where((p) => p.isActive)
              .toList();
          return _attachPaidCounts(plans);
        });
  }

  Future<List<InstallmentPlan>> getActive() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('installment_plans')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('first_due_date', ascending: true);
    final plans = data.map(InstallmentPlan.fromJson).toList();
    return _attachPaidCounts(plans);
  }

  Future<InstallmentPlan?> getById(String id) async {
    final data = await _supabase
        .from('installment_plans')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    final plan = InstallmentPlan.fromJson(data);
    final plans = await _attachPaidCounts([plan]);
    return plans.first;
  }

  Future<InstallmentPlan> create(InstallmentPlan plan) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    final data = await _supabase
        .from('installment_plans')
        .insert(plan.toJson()..remove('id'))
        .select()
        .single();
    return InstallmentPlan.fromJson(data);
  }

  Future<void> updateStatus(String id, String status) async {
    await _supabase.from('installment_plans').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('installment_plans').delete().eq('id', id);
  }

  // Fetches paid count for each plan and attaches it
  Future<List<InstallmentPlan>> _attachPaidCounts(
      List<InstallmentPlan> plans) async {
    if (plans.isEmpty) return plans;
    final ids = plans.map((p) => p.id).toList();
    final data = await _supabase
        .from('installment_payments')
        .select('plan_id')
        .inFilter('plan_id', ids)
        .eq('status', 'paid');
    final counts = <String, int>{};
    for (final row in data) {
      final pid = row['plan_id'] as String;
      counts[pid] = (counts[pid] ?? 0) + 1;
    }
    return plans
        .map((p) => p.copyWith(paidCount: counts[p.id] ?? 0))
        .toList();
  }
}
