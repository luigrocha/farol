import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/income.dart';

class IncomeRepository {
  final SupabaseClient _supabase;
  const IncomeRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Income>> watchAll() {
    final userId = _userId;
    if (userId != null) {
      return _supabase
          .from('incomes')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((rows) => rows.map(Income.fromJson).toList());
    }
    return _supabase.auth.onAuthStateChange
        .where((e) => e.session != null)
        .take(1)
        .asyncExpand((e) {
          final uid = e.session!.user.id;
          return _supabase
              .from('incomes')
              .stream(primaryKey: ['id'])
              .eq('user_id', uid)
              .map((rows) => rows.map(Income.fromJson).toList());
        });
  }

  Future<List<Income>> getAll() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase.from('incomes').select().eq('user_id', userId);
    return data.map((r) => Income.fromJson(r)).toList();
  }

  Future<List<Income>> getByRange(
      int startMonth, int startYear, int endMonth, int endYear) async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('incomes')
        .select()
        .eq('user_id', userId);
    return data
        .map((r) => Income.fromJson(r))
        .where((i) => _inRange(i.month, i.year, startMonth, startYear, endMonth, endYear))
        .toList();
  }

  Future<void> insert({
    required int month,
    required int year,
    required String incomeType,
    required double amount,
    bool isNet = true,
    double? inssDeducted,
    double? irrfDeducted,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('incomes').insert({
      'user_id': userId,
      'month': month,
      'year': year,
      'income_type': incomeType,
      'amount': amount,
      'is_net': isNet,
      if (inssDeducted != null) 'inss_deducted': inssDeducted,
      if (irrfDeducted != null) 'irrf_deducted': irrfDeducted,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> delete(int id) async {
    await _supabase.from('incomes').delete().eq('id', id);
  }

  bool _inRange(int m, int y, int sm, int sy, int em, int ey) {
    final v = y * 12 + m;
    return v >= sy * 12 + sm && v <= ey * 12 + em;
  }
}
