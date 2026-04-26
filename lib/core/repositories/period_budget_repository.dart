import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_period.dart';
import '../models/period_budget.dart';

class PeriodBudgetRepository {
  final SupabaseClient _supabase;
  const PeriodBudgetRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns budgets for [period] with aggregated cash spending — single query
  /// via the `get_period_budgets_with_spending` RPC.
  Future<List<BudgetWithUsage>> getBudgetsWithUsage(FinancialPeriod period) async {
    final uid = _userId;
    if (uid == null) return [];

    final data = await _supabase.rpc(
      'get_period_budgets_with_spending',
      params: {
        'p_user_id': uid,
        'p_period_start': period.startIso,
        'p_period_end': period.endIso,
      },
    ) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(BudgetWithUsage.fromRpcJson)
        .toList();
  }

  /// Raw budget rows for [period] (no spending aggregation).
  Future<List<PeriodBudget>> getBudgets(FinancialPeriod period) async {
    final uid = _userId;
    if (uid == null) return [];

    final data = await _supabase
        .from('period_budgets')
        .select()
        .eq('user_id', uid)
        .eq('period_start', period.startIso)
        .eq('period_end', period.endIso);

    return data.map(PeriodBudget.fromJson).toList();
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> upsert({
    required String category,
    required FinancialPeriod period,
    required double amount,
    bool isCustom = false,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Not authenticated');

    await _supabase.from('period_budgets').upsert(
      {
        'user_id': uid,
        'category': category,
        'period_start': period.startIso,
        'period_end': period.endIso,
        'amount': amount,
        'is_custom': isCustom,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,category,period_start,period_end',
    );
  }

  Future<void> delete(String id) async {
    await _supabase.from('period_budgets').delete().eq('id', id);
  }

  // ── Rollover ───────────────────────────────────────────────────────────────

  /// Copies all budgets from [from] into [to] using the server-side RPC.
  /// Skips categories that already have a budget in [to].
  /// Returns the number of rows inserted.
  Future<int> copyFromPeriod({
    required FinancialPeriod from,
    required FinancialPeriod to,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Not authenticated');

    final result = await _supabase.rpc(
      'copy_period_budgets',
      params: {
        'p_user_id': uid,
        'p_from_start': from.startIso,
        'p_from_end': from.endIso,
        'p_to_start': to.startIso,
        'p_to_end': to.endIso,
      },
    );

    return (result as num?)?.toInt() ?? 0;
  }
}
