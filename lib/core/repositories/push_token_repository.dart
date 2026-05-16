// lib/core/repositories/push_token_repository.dart
//
// Upserts the device FCM token into push_tokens so the
// send-space-notification Edge Function can fan out push messages.
//
// Called once on startup (after Firebase.initializeApp) and again
// whenever FirebaseMessaging issues a token-refresh event.

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class PushTokenRepository {
  final SupabaseClient _supabase;

  const PushTokenRepository(this._supabase);

  String get _platform {
    if (kIsWeb) return 'web';
    // We use a try/catch import-style check to avoid dart:io on web.
    // Platform detection for mobile is done at the call site via firebase_messaging.
    return 'android'; // caller overrides with the real platform string
  }

  /// Upserts [token] for [platform] ('android' | 'ios' | 'web').
  /// No-ops if the user is not authenticated.
  Future<void> upsertToken({
    required String token,
    required String platform,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('push_tokens').upsert(
        {
          'user_id':    userId,
          'token':      token,
          'platform':   platform,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,platform',
      );
    } catch (e) {
      // Non-fatal — notification delivery degrades gracefully.
      debugPrint('[PushTokenRepository] upsertToken error: $e');
    }
  }

  /// Removes the token for [platform] on logout or permission revocation.
  Future<void> deleteToken(String platform) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('platform', platform);
    } catch (e) {
      debugPrint('[PushTokenRepository] deleteToken error: $e');
    }
  }
}
