import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_installment.dart';

class InstallmentRepository {
  final SupabaseClient _supabase;
  const InstallmentRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<CardInstallment>> watchActive() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('card_installments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows
            .map(CardInstallment.fromJson)
            .where((i) => i.status == 'Active')
            .toList());
  }

  Stream<List<CardInstallment>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('card_installments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(CardInstallment.fromJson).toList());
  }

  Future<int> insert({
    required String description,
    required DateTime purchaseDate,
    required double totalValue,
    required int numInstallments,
    int currentInstallment = 1,
    required double monthlyAmount,
    String status = 'Active',
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    final result = await _supabase.from('card_installments').insert({
      'user_id': userId,
      'description': description,
      'purchase_date': purchaseDate.toIso8601String(),
      'total_value': totalValue,
      'num_installments': numInstallments,
      'current_installment': currentInstallment,
      'monthly_amount': monthlyAmount,
      'status': status,
      if (notes != null) 'notes': notes,
    }).select('id').single();
    return (result['id'] as num).toInt();
  }

  Future<void> advance(int id, int newCurrent, int numInstallments) async {
    final newStatus = newCurrent >= numInstallments ? 'Settled' : 'Active';
    await _supabase.from('card_installments').update({
      'current_installment': newCurrent,
      'status': newStatus,
    }).eq('id', id);
  }

  Future<void> complete(int id) async {
    await _supabase.from('card_installments').update({
      'status': 'Settled',
    }).eq('id', id);
  }

  Future<void> update(int id, {
    String? description,
    double? totalValue,
    int? numInstallments,
    double? monthlyAmount,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (description != null) updates['description'] = description;
    if (totalValue != null) updates['total_value'] = totalValue;
    if (numInstallments != null) updates['num_installments'] = numInstallments;
    if (monthlyAmount != null) updates['monthly_amount'] = monthlyAmount;
    if (notes != null) updates['notes'] = notes;
    if (updates.isEmpty) return;
    await _supabase.from('card_installments').update(updates).eq('id', id);
  }

  Future<List<CardInstallment>> getActive() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('card_installments')
        .select()
        .eq('user_id', userId)
        .eq('status', 'Active');
    return data.map(CardInstallment.fromJson).toList();
  }

  Future<void> delete(int id) async {
    await _supabase.from('card_installments').delete().eq('id', id);
  }
}
