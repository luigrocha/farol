import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../domain/app_user.dart';
import '../domain/auth_state.dart';

abstract class AuthRepository {
  Stream<AppAuthState> get authStateChanges;
  AppUser? get currentUser;

  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String email, String password, {String? fullName, String? cpf});
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();

  Future<void> resendVerificationEmail();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: const String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: 'dummy-client-id.apps.googleusercontent.com',
    ),
  );

  @override
  Stream<AppAuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        if (user == null) return const AppAuthUnauthenticated();
        final appUser = AppUser.fromSupabase(user);
        if (event.event == AuthChangeEvent.passwordRecovery) {
          return AppAuthPasswordRecovery(appUser);
        }
        return AppAuthAuthenticated(appUser);
      });

  @override
  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    return user != null ? AppUser.fromSupabase(user) : null;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('User is null after sign in');
      return AppUser.fromSupabase(response.user!);
    } on AuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AppUser> signUpWithEmail(String email, String password, {String? fullName, String? cpf}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
        },
      );
      if (response.user == null) throw Exception('User is null after sign up');
      return AppUser.fromSupabase(response.user!);
    } on AuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Sign in cancelled by user');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      // accessToken is optional for Supabase when idToken is present
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('No ID token received from Google Sign-In');
      }

      // ignore: experimental_member_use
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) throw Exception('User is null after Google sign in');
      return AppUser.fromSupabase(response.user!);
    } on AuthException catch (e) {
      throw _mapException(e);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        throw Exception('No identity token received from Apple Sign-In');
      }

      // ignore: experimental_member_use
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: identityToken,
      );

      if (response.user == null) throw Exception('User is null after Apple sign in');
      return AppUser.fromSupabase(response.user!);
    } on AuthException catch (e) {
      throw _mapException(e);
    } catch (e) {
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  @override
  Future<void> resendVerificationEmail() async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) {
      throw Exception('No authenticated user to resend verification to');
    }
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _supabase.auth.signOut(),
        if (await _googleSignIn.isSignedIn()) _googleSignIn.signOut(),
      ]);
    } catch (e) {
      // Local session is already cleared by Supabase before the error; log and continue.
      debugPrint('[Auth] Sign out error (session cleared locally): $e');
    }
  }

  Exception _mapException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return Exception('Invalid email or password.');
    }
    if (msg.contains('user already registered') ||
        msg.contains('already registered')) {
      return Exception('This email is already registered. Try signing in instead.');
    }
    if (msg.contains('email not confirmed')) {
      return Exception('Please verify your email before signing in.');
    }
    if (msg.contains('rate limit') || e.statusCode == '429') {
      return Exception('Too many attempts. Please wait a moment and try again.');
    }
    return Exception(e.message);
  }
}
