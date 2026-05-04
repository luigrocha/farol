import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final String? cpf;
  final String? jobTitle;
  final String? company;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.cpf,
    this.jobTitle,
    this.company,
    this.emailVerified = false,
    this.phoneVerified = false,
    required this.createdAt,
    this.metadata = const {},
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['id'],
      email: data['email'] ?? '',
      displayName: data['display_name'],
      photoUrl: data['photo_url'],
      phone: data['phone'],
      cpf: data['cpf'],
      jobTitle: data['job_title'],
      company: data['company'],
      emailVerified: data['email_verified'] as bool? ?? false,
      phoneVerified: data['phone_verified'] as bool? ?? false,
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
      'phone': phone,
      'cpf': cpf,
      'job_title': jobTitle,
      'company': company,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
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

  Future<void> updateProfile(
    String uid, {
    String? name,
    String? avatarUrl,
    String? phone,
    String? jobTitle,
    String? company,
  }) async {
    await _supabase.from('profiles').upsert({
      'id': uid,
      if (name != null) 'display_name': name,
      if (avatarUrl != null) 'photo_url': avatarUrl,
      if (phone != null) 'phone': phone,
      if (jobTitle != null) 'job_title': jobTitle,
      if (company != null) 'company': company,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> deleteAccount(String uid) async {
    await _supabase.from('profiles').delete().eq('id', uid);
    await _supabase.auth.signOut();
  }

  Future<void> updateMetadata(String uid, Map<String, dynamic> metadata) async {
    await _supabase.from('profiles').update({
      'metadata': metadata,
    }).eq('id', uid);
  }
}
