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

  Future<void> insert({
    required String description,
    required DateTime purchaseDate,
    required double totalValue,
    required int numInstallments,
    int currentInstallment = 1,
    required double monthlyAmount,
    String status = 'Active',
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('card_installments').insert({
      'user_id': userId,
      'description': description,
      'purchase_date': purchaseDate.toIso8601String(),
      'total_value': totalValue,
      'num_installments': numInstallments,
      'current_installment': currentInstallment,
      'monthly_amount': monthlyAmount,
      'status': status,
    });
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
