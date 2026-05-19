// lib/core/services/space_notification_service.dart
//
// Manages FCM push notifications for Space events.
//
// ⚠️  REQUIRES the following pubspec.yaml additions before use:
//       firebase_core: ^3.3.0
//       firebase_messaging: ^15.1.0
//       flutter_local_notifications: ^17.2.0
//
//   AND the Firebase native setup (google-services.json / GoogleService-Info.plist).
//   See plans/sprint7_push_notifications.md → "Prerequisite" section.
//
// Usage (from _MainShellState.initState, inside addPostFrameCallback):
//
//   SpaceNotificationService.instance.init(ref);
//
// The service is a singleton and is safe to call multiple times — subsequent
// calls after the first are no-ops.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Conditional firebase imports ──────────────────────────────────────────────
// Uncomment these once firebase_* packages are added to pubspec.yaml:
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────────
// Singleton service
// ─────────────────────────────────────────────────────────────────

/// Manages FCM token registration, foreground display, and tap routing.
/// Initialise once from `_MainShellState.initState`.
class SpaceNotificationService {
  SpaceNotificationService._();
  static final instance = SpaceNotificationService._();

  bool _initialized = false;

  // ── Public API ────────────────────────────────────────────────────

  /// Initialises Firebase Messaging, requests permission, registers the
  /// device token, and wires foreground + tap handlers.
  ///
  /// Safe to call multiple times — only runs once.
  Future<void> init(WidgetRef ref) async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initFirebase(ref);
    } catch (e) {
      // Firebase not yet configured — degrade gracefully.
      debugPrint('[SpaceNotificationService] Firebase not configured: $e');
      _initialized = false; // allow retry after config is added
    }
  }

  // ── Private implementation ────────────────────────────────────────

  Future<void> _initFirebase(WidgetRef ref) async {
    // ── Step 1: Initialise Firebase ──────────────────────────────────
    // await Firebase.initializeApp();

    // ── Step 2: Request permission (iOS / macOS) ─────────────────────
    // final messaging = FirebaseMessaging.instance;
    // final settings  = await messaging.requestPermission(
    //   alert: true, badge: true, sound: true,
    // );
    // if (settings.authorizationStatus == AuthorizationStatus.denied) {
    //   debugPrint('[SpaceNotificationService] Permission denied');
    //   return;
    // }

    // ── Step 3: Get token + upsert into push_tokens ──────────────────
    // final token = await messaging.getToken();
    // if (token != null) {
    //   await ref.read(pushTokenRepositoryProvider).upsertToken(
    //     token: token, platform: _fcmPlatform,
    //   );
    // }

    // ── Step 4: Listen for token refresh ────────────────────────────
    // messaging.onTokenRefresh.listen((newToken) {
    //   ref.read(pushTokenRepositoryProvider).upsertToken(
    //     token: newToken, platform: _fcmPlatform,
    //   );
    // });

    // ── Step 5: Foreground messages (via flutter_local_notifications) ─
    // await _setupLocalNotifications();
    // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── Step 6: Background / terminated tap ─────────────────────────
    // FirebaseMessaging.onMessageOpenedApp.listen(
    //   (msg) => _routeNotificationTap(msg.data, ref),
    // );
    // final initial = await messaging.getInitialMessage();
    // if (initial != null) _routeNotificationTap(initial.data, ref);

    // ── Step 7: iOS foreground presentation options ──────────────────
    // await messaging.setForegroundNotificationPresentationOptions(
    //   alert: false, badge: true, sound: true,
    // );

    debugPrint(
        '[SpaceNotificationService] stub — Firebase packages not yet added');
  }

  // ── Local notifications setup (foreground) ────────────────────────
  //
  // FlutterLocalNotificationsPlugin? _localNotifications;
  //
  // Future<void> _setupLocalNotifications() async {
  //   _localNotifications = FlutterLocalNotificationsPlugin();
  //   await _localNotifications!.initialize(
  //     const InitializationSettings(
  //       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  //       iOS:     DarwinInitializationSettings(),
  //     ),
  //   );
  // }
  //
  // void _handleForegroundMessage(RemoteMessage message) {
  //   final notif = message.notification;
  //   if (notif == null) return;
  //   _localNotifications?.show(
  //     notif.hashCode,
  //     notif.title,
  //     notif.body,
  //     const NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'space_activity', 'Atividade do espaço',
  //         importance: Importance.high,
  //         priority:   Priority.high,
  //       ),
  //       iOS: DarwinNotificationDetails(),
  //     ),
  //   );
  // }

  // ── Notification tap routing ──────────────────────────────────────
  //
  // Future<void> _routeNotificationTap(
  //   Map<String, dynamic> data,
  //   WidgetRef ref,
  // ) async {
  //   final spaceId = data['spaceId'] as String?;
  //   if (spaceId == null) return;
  //
  //   final spaces = await ref.read(userSpacesProvider.future);
  //   final space  = spaces.where((s) => s.id == spaceId).firstOrNull;
  //   if (space == null) return;
  //
  //   await ref.read(activeSpaceProvider.notifier).select(space);
  //   // Active space change will trigger SpaceDashboardScreen navigation
  //   // via the listener in MainShell (same pattern as workspace switching).
  // }
}

// ─────────────────────────────────────────────────────────────────
// Top-level helper — fire-and-forget notification dispatch
// ─────────────────────────────────────────────────────────────────

/// Calls the `send-space-notification` Edge Function.
///
/// Fire-and-forget — errors are logged but not rethrown.
/// Call after:
///   • a transaction is saved (AddSpaceTransactionSheet)
///   • a settlement is confirmed (_SettlementRowState._settle)
///   • a member joins (accept-space-invite Edge Function already handles this)
Future<void> sendSpaceNotification({
  required String spaceId,
  required String event,
  required String actorUserId,
  required String actorName,
  Map<String, dynamic> payload = const {},
}) async {
  try {
    await Supabase.instance.client.functions.invoke(
      'send-space-notification',
      body: {
        'spaceId': spaceId,
        'event': event,
        'actorUserId': actorUserId,
        'actorName': actorName,
        'payload': payload,
      },
    );
  } catch (e) {
    // Non-fatal — app works without push notifications.
    debugPrint('[SpaceNotificationService] sendSpaceNotification error: $e');
  }
}
