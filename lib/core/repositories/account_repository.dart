import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';

class AccountRepository {
  final SupabaseClient _supabase;
  const AccountRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Account>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(Account.fromJson).toList());
  }

  Future<void> insert({
    required String name,
    required String institution,
    required String type,
    double initialBalance = 0,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('accounts').insert({
      'user_id': userId,
      'name': name,
      'institution': institution,
      'type': type,
      'current_balance': initialBalance,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> updateBalance(int id, double newBalance) async {
    await _supabase
        .from('accounts')
        .update({'current_balance': newBalance})
        .eq('id', id);
  }

  Future<void> update(
    int id, {
    String? name,
    String? institution,
    String? notes,
    bool? isActive,
  }) async {
    await _supabase.from('accounts').update({
      if (name != null) 'name': name,
      if (institution != null) 'institution': institution,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> delete(int id) async {
    await _supabase.from('accounts').delete().eq('id', id);
  }
}
