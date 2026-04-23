import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => ProfileRepository(),
);

final currentProfileProvider = FutureProvider<UserProfile?>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return Future.value(null);
  return ref.read(profileRepositoryProvider).getProfile(uid);
});

class ProfileNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveProfile({required String uid, String? name, String? avatarUrl}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateProfile(uid, name: name, avatarUrl: avatarUrl);
      ref.invalidate(currentProfileProvider);
    });
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileNotifier, void>(ProfileNotifier.new);
