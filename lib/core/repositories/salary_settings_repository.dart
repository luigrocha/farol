import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/salary_settings.dart';

class SalarySettingsRepository {
  final SupabaseClient _supabase;

  SalarySettingsRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<SalarySettings?> fetch() async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final data = await _supabase
          .from('user_salary_settings')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (data == null) return null;
      return SalarySettings.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(SalarySettings settings) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');
    await _supabase.from('user_salary_settings').upsert(
      {'user_id': uid, ...settings.toJson()},
      onConflict: 'user_id',
    );
  }
}
