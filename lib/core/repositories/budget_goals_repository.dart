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
}
