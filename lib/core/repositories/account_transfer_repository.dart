import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_transfer.dart';

class AccountTransferRepository {
  final SupabaseClient _supabase;
  const AccountTransferRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<AccountTransfer>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('account_transfers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('transfer_date', ascending: false)
        .map((rows) => rows.map(AccountTransfer.fromJson).toList());
  }

  Future<void> transfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.rpc('execute_account_transfer', params: {
      'p_user_id': userId,
      'p_from_id': fromAccountId,
      'p_to_id': toAccountId,
      'p_amount': amount,
      'p_date': date.toIso8601String().substring(0, 10),
      if (description != null) 'p_description': description,
    });
  }
}
