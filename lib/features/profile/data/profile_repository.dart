import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.metadata = const {},
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['id'],
      email: data['email'] ?? '',
      displayName: data['display_name'],
      photoUrl: data['photo_url'],
      createdAt: DateTime.parse(data['created_at']),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'metadata': metadata,
    };
  }
}

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createProfile(UserProfile profile) async {
    await _supabase.from('profiles').insert(profile.toSupabase());
  }

  Future<UserProfile?> getProfile(String uid) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
        
    if (response == null) return null;
    return UserProfile.fromSupabase(response);
  }

  Future<void> updateProfile(String uid, {String? name, String? avatarUrl}) async {
    await _supabase.from('profiles').upsert({
      'id': uid,
      if (name != null) 'display_name': name,
      if (avatarUrl != null) 'photo_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateMetadata(String uid, Map<String, dynamic> metadata) async {
    await _supabase.from('profiles').update({
      'metadata': metadata,
    }).eq('id', uid);
  }
}
