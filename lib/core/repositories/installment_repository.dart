import 'package:supabase_flutter/supabase_flutter.dart';

class InstallmentRepository {
  final SupabaseClient _supabase;
  const InstallmentRepository(this._supabase);

  /// Deletes a legacy card_installments row by int PK.
  /// Used only when an expense still references a legacy plan id.
  Future<void> delete(int id) async {
    await _supabase.from('card_installments').delete().eq('id', id);
  }
}
