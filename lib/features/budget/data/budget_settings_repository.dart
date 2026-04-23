import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/budget_settings.dart';

class BudgetSettingsRepository {
  final SupabaseClient _supabase;

  BudgetSettingsRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<BudgetSettings?> fetch() async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final data = await _supabase
          .from('budget_settings')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (data == null) return null;
      return BudgetSettings.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(BudgetSettings settings) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');
    await _supabase.from('budget_settings').upsert(
      {
        'user_id': uid,
        ...settings.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
