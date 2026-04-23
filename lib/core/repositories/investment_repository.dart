import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/investment.dart';

class InvestmentRepository {
  final SupabaseClient _supabase;
  const InvestmentRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Investment>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('investments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(Investment.fromJson).toList());
  }

  Future<void> insert({
    required String type,
    required String productName,
    required String institution,
    required DateTime dateAdded,
    required double totalInvested,
    required double currentBalance,
    double returnAmount = 0,
    String? liquidity,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('investments').insert({
      'user_id': userId,
      'type': type,
      'product_name': productName,
      'institution': institution,
      'date_added': dateAdded.toIso8601String(),
      'total_invested': totalInvested,
      'current_balance': currentBalance,
      'return_amount': returnAmount,
      if (liquidity != null) 'liquidity': liquidity,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> update(int id, {
    double? currentBalance,
    double? returnAmount,
  }) async {
    await _supabase.from('investments').update({
      if (currentBalance != null) 'current_balance': currentBalance,
      if (returnAmount != null) 'return_amount': returnAmount,
    }).eq('id', id);
  }

  Future<void> delete(int id) async {
    await _supabase.from('investments').delete().eq('id', id);
  }
}
