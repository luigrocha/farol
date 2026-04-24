import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final SupabaseClient _supabase;
  const ExpenseRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Expense>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('transaction_date', ascending: false)
        .map((rows) => rows.map(Expense.fromJson).toList());
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
    final data = await _supabase
        .from('expenses')
        .select()
        .eq('user_id', userId);
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

  bool _inRange(int m, int y, int sm, int sy, int em, int ey) {
    final v = y * 12 + m;
    return v >= sy * 12 + sm && v <= ey * 12 + em;
  }
}
