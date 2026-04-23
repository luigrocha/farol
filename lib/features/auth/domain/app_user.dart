import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Domain model representing an authenticated user in the application.
/// Decouples the UI and business logic from the Supabase SDK.
class AppUser {
  final String uid;
  final String? email;
  final bool emailVerified;
  final String? displayName;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.displayName,
    this.photoUrl,
  });

  /// Maps a Supabase [supabase.User] to the domain [AppUser].
  factory AppUser.fromSupabase(supabase.User user) {
    return AppUser(
      uid: user.id,
      email: user.email,
      emailVerified: user.emailConfirmedAt != null,
      displayName: user.userMetadata?['full_name'] as String?,
      photoUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  @override
  String toString() => 'AppUser(uid: $uid, email: $email, verified: $emailVerified)';
}
