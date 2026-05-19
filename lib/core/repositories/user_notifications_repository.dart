import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_notification.dart';

class UserNotificationsRepository {
  UserNotificationsRepository(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<UserNotification>> fetchPending() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _supabase
        .from('user_notifications')
        .select()
        .eq('user_id', uid)
        .isFilter('read_at', null)
        .order('created_at', ascending: false);
    return rows.map(UserNotification.fromJson).toList();
  }

  Future<void> markRead(String id) async {
    await _supabase
        .from('user_notifications')
        .update({'read_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final uid = _userId;
    if (uid == null) return;
    await _supabase
        .from('user_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', uid)
        .isFilter('read_at', null);
  }
}
