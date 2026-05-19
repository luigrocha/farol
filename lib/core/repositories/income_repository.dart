import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/income.dart';
import '../services/supabase_realtime_manager.dart';

class IncomeRepository {
  final SupabaseClient _supabase;
  final String? workspaceId;

  const IncomeRepository(this._supabase, {this.workspaceId});

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Income>> watchAll() {
    final wsId = workspaceId;
    if (wsId != null) {
      return _supabase
          .from('incomes')
          .stream(primaryKey: ['id'])
          .eq('workspace_id', wsId)
          .map((rows) => rows.map(Income.fromJson).toList());
    }
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
    final wsId = workspaceId;
    if (wsId != null) {
      final data =
          await _supabase.from('incomes').select().eq('workspace_id', wsId);
      return data.map((r) => Income.fromJson(r)).toList();
    }
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase.from('incomes').select().eq('user_id', userId);
    return data.map((r) => Income.fromJson(r)).toList();
  }

  Future<List<Income>> getByRange(
      int startMonth, int startYear, int endMonth, int endYear) async {
    final wsId = workspaceId;
    final userId = _userId;
    final data = await () {
      if (wsId != null) {
        return _supabase
            .from('incomes')
            .select()
            .eq('workspace_id', wsId)
            .gte('year', startYear)
            .lte('year', endYear);
      }
      if (userId == null) return Future.value(<Map<String, dynamic>>[]);
      return _supabase
          .from('incomes')
          .select()
          .eq('user_id', userId)
          .gte('year', startYear)
          .lte('year', endYear);
    }();
    return data
        .map((r) => Income.fromJson(r))
        .where((i) =>
            _inRange(i.month, i.year, startMonth, startYear, endMonth, endYear))
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
      if (workspaceId != null) 'workspace_id': workspaceId,
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

  Future<void> update({
    required int id,
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
    await _supabase.from('incomes').update({
      'month': month,
      'year': year,
      'income_type': incomeType,
      'amount': amount,
      'is_net': isNet,
      if (inssDeducted != null) 'inss_deducted': inssDeducted,
      if (irrfDeducted != null) 'irrf_deducted': irrfDeducted,
      if (notes != null) 'notes': notes,
    }).eq('id', id);
  }

  Future<void> delete(int id) async {
    await _supabase.from('incomes').delete().eq('id', id);
  }

  Stream<List<Income>> watchRealtime() {
    return SupabaseRealtimeManager.instance.createManagedStream<Income>(
      table: 'incomes',
      primaryKey: ['id'],
      fromJson: Income.fromJson,
      userId: _userId,
      userIdColumn: 'user_id',
    );
  }

  Future<void> unsubscribeRealtime() {
    return SupabaseRealtimeManager.instance.unsubscribe('incomes');
  }

  bool get shouldFallbackToPolling =>
      SupabaseRealtimeManager.instance.isMaxRetriesReached('incomes');

  Future<List<Income>> fetchAll() async {
    return SupabaseRealtimeManager.instance
        .fetchAll(
          table: 'incomes',
          userId: _userId,
          userIdColumn: 'user_id',
        )
        .then((rows) => rows.map(Income.fromJson).toList());
  }

  bool _inRange(int m, int y, int sm, int sy, int em, int ey) {
    final v = y * 12 + m;
    return v >= sy * 12 + sm && v <= ey * 12 + em;
  }
}
