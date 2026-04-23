import 'package:supabase_flutter/supabase_flutter.dart';

class UserPreferencesRepository {
  final SupabaseClient _supabase;
  const UserPreferencesRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<({String? locale, String? themeMode})> fetch() async {
    final userId = _userId;
    if (userId == null) return (locale: null, themeMode: null);
    try {
      final data = await _supabase
          .from('user_preferences')
          .select('locale, theme_mode')
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return (locale: null, themeMode: null);
      return (
        locale: data['locale'] as String?,
        themeMode: data['theme_mode'] as String?,
      );
    } catch (_) {
      return (locale: null, themeMode: null);
    }
  }

  Future<void> setLocale(String locale) async {
    final userId = _userId;
    if (userId == null) return;
    await _supabase.from('user_preferences').upsert(
      {
        'user_id': userId,
        'locale': locale,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  Future<void> setThemeMode(String themeMode) async {
    final userId = _userId;
    if (userId == null) return;
    await _supabase.from('user_preferences').upsert(
      {
        'user_id': userId,
        'theme_mode': themeMode,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
