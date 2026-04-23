# Auth Flow — Farol

> Last updated: 2026-04-22

## Overview

Farol uses **Supabase** as the authentication backend, with a reactive Flutter architecture built on **Riverpod**. The app supports email/password, Google (native SDK), and Apple Sign-In.

---

## Architecture

```
Supabase SDK
    │
    ▼
SupabaseAuthRepository          ← implements AuthRepository (abstract)
    │  exposes Stream<AppAuthState>
    ▼
authStateProvider (StreamProvider)
    │
    ▼
AppEntryPoint                   ← listens to the stream, routes reactively
    ├── AppAuthUnauthenticated  → OnboardingScreen
    ├── AppAuthAuthenticated (email unverified) → VerificationScreen
    ├── AppAuthAuthenticated (verified) → MainShell
    └── AppAuthPasswordRecovery → PasswordResetScreen
```

### Key files

| File | Role |
|------|------|
| `lib/features/auth/domain/app_user.dart` | Domain model — decouples UI from Supabase SDK |
| `lib/features/auth/domain/auth_state.dart` | Sealed class representing all possible auth states |
| `lib/features/auth/data/auth_repository.dart` | Abstract interface + Supabase implementation |
| `lib/features/auth/presentation/auth_providers.dart` | Riverpod providers + `AuthNotifier` |
| `lib/features/auth/presentation/login_screen.dart` | Email/password + social sign-in UI |
| `lib/features/auth/presentation/signup_screen.dart` | Registration UI |
| `lib/features/auth/presentation/password_reset_screen.dart` | New-password UI (opened via deep link) |
| `lib/main.dart` | App entry point, reactive routing, `VerificationScreen` |

---

## Auth States (`AppAuthState`)

```dart
sealed class AppAuthState { ... }

AppAuthUnauthenticated          // no session
AppAuthAuthenticated(user)      // active session; user.emailVerified may be false
AppAuthPasswordRecovery(user)   // session opened via password-reset deep link
```

`AppAuthState` is emitted by `SupabaseAuthRepository.authStateChanges`, which wraps `supabase.auth.onAuthStateChange`. The `passwordRecovery` event from Supabase maps to `AppAuthPasswordRecovery`.

> **Note:** The class is named `AppAuthState` (not `AuthState`) to avoid a naming collision with `gotrue`'s internal `AuthState` type, which is a transitive dependency of `supabase_flutter`.

---

## Sign-In Methods

### Email / Password
Standard Supabase `signInWithPassword`. Errors are mapped to user-friendly messages by `_mapException`.

### Google (native)
Uses the `google_sign_in` package to obtain an ID token, then exchanges it with Supabase via `signInWithIdToken`. The `accessToken` is optional — Supabase accepts `idToken` alone. Configure `GOOGLE_CLIENT_ID` via `--dart-define`.

### Apple
Uses `sign_in_with_apple` to obtain a credential, checks `identityToken` for null before passing to Supabase. Previously this was a force-unwrap (`!`) that would crash if Apple returned a null token.

---

## Password Reset Flow

1. User enters email on `LoginScreen` → `sendPasswordResetEmail(email)` → Supabase sends a link.
2. User taps the link → the app opens via deep link → Supabase emits `AuthChangeEvent.passwordRecovery`.
3. `authStateChanges` maps this to `AppAuthPasswordRecovery`.
4. `AppEntryPoint` routes to `PasswordResetScreen`.
5. User submits a new password → `updatePassword(newPassword)` → Supabase emits `userUpdated`.
6. `authStateChanges` maps this to `AppAuthAuthenticated` → `AppEntryPoint` navigates to `MainShell`.

### Native deep link configuration required

The reset email contains a link of the form `farol://auth/reset`. To handle it natively, configure:

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>farol</string></array>
  </dict>
</array>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="farol"/>
</intent-filter>
```

**Supabase Dashboard → Authentication → URL Configuration:**
Add `farol://auth/reset` to the allowed redirect URLs.

---

## Email Verification Flow

After sign-up with email/password, Supabase requires email confirmation by default. Until confirmed:
- `user.emailConfirmedAt == null` → `AppUser.emailVerified == false`
- `AppEntryPoint` routes to `VerificationScreen`
- `VerificationScreen` allows the user to **resend the verification email** via `resendVerificationEmail()`, which calls `supabase.auth.resend(type: OtpType.signup, email: email)`
- Once the user clicks the link, Supabase updates the session and the stream automatically transitions to `AppAuthAuthenticated(verified: true)` → `MainShell`

> Social sign-in users (Google, Apple) skip this screen because their email is pre-verified.

---

## Error Handling

`_mapException(AuthException)` translates Supabase error messages to user-friendly strings:

| Supabase message | User-facing message |
|------------------|---------------------|
| `invalid login credentials` | Invalid email or password. |
| `user already registered` | This email is already registered. Try signing in instead. |
| `email not confirmed` | Please verify your email before signing in. |
| Rate limit / status 429 | Too many attempts. Please wait a moment and try again. |
| Anything else | Forwarded as-is from Supabase |

Errors surface via `AuthActionHandler` (a wrapper widget that calls `ref.listen` on `authControllerProvider` and shows a `SnackBar`).

---

## Build Configuration

Credentials are injected at compile time via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
```

In debug builds, missing `SUPABASE_URL` or `SUPABASE_ANON_KEY` will trigger a Dart `assert` failure with a descriptive message, preventing silent runtime failures.

---

## Sign Out

`signOut()` calls both `supabase.auth.signOut()` and `GoogleSignIn.signOut()` concurrently (Apple does not require explicit sign-out). Errors are logged via `debugPrint` but do not surface to the user — Supabase clears the local session before any network call, so the app is effectively signed out regardless.
