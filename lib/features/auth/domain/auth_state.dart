import 'app_user.dart';

sealed class AppAuthState {
  const AppAuthState();
}

final class AppAuthUnauthenticated extends AppAuthState {
  const AppAuthUnauthenticated();
}

final class AppAuthAuthenticated extends AppAuthState {
  final AppUser user;
  const AppAuthAuthenticated(this.user);
}

/// Emitted when the user opens the app via a password-reset deep link.
/// The session is temporarily valid only for updating the password.
final class AppAuthPasswordRecovery extends AppAuthState {
  final AppUser user;
  const AppAuthPasswordRecovery(this.user);
}
