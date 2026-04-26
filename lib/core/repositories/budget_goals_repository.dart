import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget_goal.dart';

class BudgetGoalsRepository {
  final SupabaseClient _supabase;
  const BudgetGoalsRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<BudgetGoal>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('budget_goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(BudgetGoal.fromJson).toList());
  }

  Future<List<BudgetGoal>> getAll() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('budget_goals')
        .select()
        .eq('user_id', userId);
    return data.map((r) => BudgetGoal.fromJson(r)).toList();
  }

  Future<void> insert({
    required String category,
    required double targetPercentage,
    required double targetAmount,
    required String type,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('budget_goals').insert({
      'user_id': userId,
      'category': category,
      'target_percentage': targetPercentage,
      'target_amount': targetAmount,
      'type': type,
    });
  }

  Future<void> delete(int id) async {
    await _supabase.from('budget_goals').delete().eq('id', id);
  }

  Future<void> upsert(BudgetGoal goal) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('budget_goals').upsert(
      goal.toJson()..['user_id'] = userId,
      onConflict: 'user_id,category',
    );
  }

  /// Bulk-updates target_percentage (and derives target_amount from netSalary)
  /// for multiple categories in a single Supabase upsert.
  Future<void> updateAllPercentages(
    Map<String, double> categoryToPercentage,
    double netSalary,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final current = await getAll();
    final currentMap = {for (final g in current) g.category: g};

    final rows = <Map<String, dynamic>>[];
    for (final entry in categoryToPercentage.entries) {
      final existing = currentMap[entry.key];
      if (existing == null) continue;
      rows.add({
        'user_id': userId,
        'category': entry.key,
        'target_percentage': entry.value,
        'target_amount': netSalary > 0
            ? (entry.value / 100) * netSalary
            : existing.targetAmount,
        'type': existing.type,
      });
    }

    if (rows.isNotEmpty) {
      await _supabase
          .from('budget_goals')
          .upsert(rows, onConflict: 'user_id,category');
    }
  }
}
