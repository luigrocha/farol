import 'dart:async';
import 'package:flutter/material.dart' show DateUtils;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../services/supabase_realtime_manager.dart';

class ExpenseRepository {
  final SupabaseClient _supabase;
  const ExpenseRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Expense>> watchAll() {
    final userId = _userId;
    if (userId != null) {
      return _supabase
          .from('expenses')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .map((rows) => rows.map(Expense.fromJson).toList());
    }
    // userId null at call time: wait for sign-in then open the real stream
    return _supabase.auth.onAuthStateChange
        .where((e) => e.session != null)
        .take(1)
        .asyncExpand((e) {
          final uid = e.session!.user.id;
          return _supabase
              .from('expenses')
              .stream(primaryKey: ['id'])
              .eq('user_id', uid)
              .order('transaction_date', ascending: false)
              .map((rows) => rows.map(Expense.fromJson).toList());
        });
  }

  Future<List<Expense>> getAll() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase.from('expenses').select().eq('user_id', userId);
    return data.map((r) => Expense.fromJson(r)).toList();
  }

  Future<List<Expense>> getByRange(
      int startMonth, int startYear, int endMonth, int endYear) async {
    final userId = _userId;
    if (userId == null) return [];
    // Push year range filter to Supabase; trim edge months in Dart.
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .gte('year', startYear)
        .lte('year', endYear);
    return data
        .map((r) => Expense.fromJson(r))
        .where((e) => _inRange(e.month, e.year, startMonth, startYear, endMonth, endYear))
        .toList();
  }

  Future<void> insert({
    required DateTime transactionDate,
    required int month,
    required int year,
    required String payType,
    required String category,
    String? subcategory,
    required double amount,
    required String paymentMethod,
    int installments = 1,
    bool isFixed = false,
    String? storeDescription,
    bool isProjected = false,
    int? installmentPlanId,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('expenses').insert({
      'user_id': userId,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'month': month,
      'year': year,
      'pay_type': payType,
      'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      'amount': amount,
      'payment_method': paymentMethod,
      'installments': installments,
      'is_fixed': isFixed,
      if (storeDescription != null) 'store_description': storeDescription,
      'is_projected': isProjected,
      if (installmentPlanId != null) 'installment_plan_id': installmentPlanId,
    });
  }

  Future<void> update({
    required int id,
    required DateTime transactionDate,
    required int month,
    required int year,
    required String payType,
    required String category,
    String? subcategory,
    required double amount,
    required String paymentMethod,
    int installments = 1,
    bool isFixed = false,
    String? storeDescription,
  }) async {
    await _supabase.from('expenses').update({
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'month': month,
      'year': year,
      'pay_type': payType,
      'category': category,
      'subcategory': subcategory,
      'amount': amount,
      'payment_method': paymentMethod,
      'installments': installments,
      'is_fixed': isFixed,
      'store_description': storeDescription,
    }).eq('id', id);
  }

  Future<void> delete(int id) async {
    await _supabase.from('expenses').delete().eq('id', id);
  }

  /// Deletes all fixed expenses from [from]'s period onward that share the
  /// same category, payment method, and store description.
  Future<void> deleteFixedSeriesFrom(Expense from) async {
    final userId = _userId;
    if (userId == null) return;
    final data = await _supabase
        .from('expenses')
        .select('id, month, year, store_description')
        .eq('user_id', userId)
        .eq('is_fixed', true)
        .eq('category', from.category)
        .eq('payment_method', from.paymentMethod);
    final ids = (data as List)
        .where((r) {
          if ((r['store_description'] as String?) != from.storeDescription) return false;
          final y = (r['year'] as num).toInt();
          final m = (r['month'] as num).toInt();
          return y * 12 + m >= from.year * 12 + from.month;
        })
        .map((r) => (r['id'] as num).toInt())
        .toList();
    if (ids.isEmpty) return;
    await _supabase.from('expenses').delete().inFilter('id', ids);
  }

  Future<int> getProjectedCountForPlan(int planId) async {
    final data = await _supabase
        .from('expenses')
        .select('id')
        .eq('installment_plan_id', planId)
        .eq('is_projected', true);
    return data.length;
  }

  Stream<List<Expense>> watchRealtime() {
    return SupabaseRealtimeManager.instance.createManagedStream<Expense>(
      table: 'expenses',
      primaryKey: ['id'],
      fromJson: Expense.fromJson,
      userId: _userId,
      userIdColumn: 'user_id',
    );
  }

  Future<void> unsubscribeRealtime() {
    return SupabaseRealtimeManager.instance.unsubscribe('expenses');
  }
  bool get shouldFallbackToPolling => SupabaseRealtimeManager.instance.isMaxRetriesReached('expenses');

  Future<List<Expense>> fetchAll() async {
    return SupabaseRealtimeManager.instance
        .fetchAll(
          table: 'expenses',
          userId: _userId,
          userIdColumn: 'user_id',
        )
        .then((rows) => rows.map(Expense.fromJson).toList());
  }

  Future<List<Expense>> getFixedForMonth(int month, int year) async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year)
        .eq('is_fixed', true);
    return data.map((r) => Expense.fromJson(r)).toList();
  }

  /// Copies fixed expenses from the most recent prior month that has them
  /// into [toMonth]/[toYear]. No-op if target month already has fixed expenses.
  /// Returns the number of expenses propagated (0 = already done or none found).
  Future<int> propagateFixedExpenses(int toMonth, int toYear) async {
    final userId = _userId;
    if (userId == null) return 0;

    final existing = await getFixedForMonth(toMonth, toYear);
    if (existing.isNotEmpty) return 0;

    for (int i = 1; i <= 12; i++) {
      final dt = DateTime(toYear, toMonth - i, 1);
      final source = (await getFixedForMonth(dt.month, dt.year))
          .where((e) => !e.isProjected)
          .toList();
      if (source.isEmpty) continue;

      final rows = source.map((e) {
        final day = e.transactionDate.day;
        final maxDay = DateUtils.getDaysInMonth(toYear, toMonth);
        return {
          'user_id': userId,
          'transaction_date':
              DateTime(toYear, toMonth, day.clamp(1, maxDay)).toIso8601String().substring(0, 10),
          'month': toMonth,
          'year': toYear,
          'pay_type': e.payType,
          'category': e.category,
          if (e.subcategory != null) 'subcategory': e.subcategory,
          'amount': e.amount,
          'payment_method': e.paymentMethod,
          'installments': e.installments,
          'is_fixed': true,
          if (e.storeDescription != null) 'store_description': e.storeDescription,
        };
      }).toList();

      await _supabase.from('expenses').insert(rows);
      return rows.length;
    }
    return 0;
  }

  bool _inRange(int m, int y, int sm, int sy, int em, int ey) {
    final v = y * 12 + m;
    return v >= sy * 12 + sm && v <= ey * 12 + em;
  }
}
