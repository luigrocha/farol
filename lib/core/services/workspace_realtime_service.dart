import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages a single Supabase Realtime channel per active workspace.
///
/// Responsibilities:
/// - Subscribe to postgres changes on `workspace_activity` for the active workspace
/// - Broadcast events to registered listeners (Riverpod providers invalidate on receive)
/// - Handle channel lifecycle: subscribe on resume, unsubscribe on pause/switch
/// - Presence tracking: track which user IDs are online in the workspace
///
/// Usage:
///   WorkspaceRealtimeService.instance.setWorkspace(workspaceId, userId);
///   WorkspaceRealtimeService.instance.onActivityChange.listen((_) { ... });
///
/// Lifecycle: managed by MainShell's WidgetsBindingObserver.
class WorkspaceRealtimeService {
  WorkspaceRealtimeService._();
  static final WorkspaceRealtimeService instance = WorkspaceRealtimeService._();

  final _client = Supabase.instance.client;

  RealtimeChannel? _channel;
  String? _currentWorkspaceId;
  String? _currentUserId;

  // ── Activity change stream ────────────────────────────────────────────────

  final _activityController = StreamController<void>.broadcast();

  /// Fires whenever a new workspace_activity row is inserted.
  Stream<void> get onActivityChange => _activityController.stream;

  // ── Presence stream ───────────────────────────────────────────────────────

  final _presenceController =
      StreamController<Set<String>>.broadcast();

  /// Set of user IDs currently online in the workspace (excluding self).
  Stream<Set<String>> get onPresenceChange => _presenceController.stream;

  Set<String> _onlineUserIds = {};
  Set<String> get currentOnlineUsers => Set.unmodifiable(_onlineUserIds);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call when the user switches to a different workspace or logs in.
  /// Unsubscribes from the old channel and subscribes to the new one.
  Future<void> setWorkspace(String workspaceId, String userId) async {
    if (_currentWorkspaceId == workspaceId && _currentUserId == userId) return;
    await _unsubscribe();
    _currentWorkspaceId = workspaceId;
    _currentUserId = userId;
    await _subscribe();
  }

  /// Call when the app resumes from background.
  Future<void> resume() async {
    if (_currentWorkspaceId != null && _currentUserId != null) {
      await _subscribe();
    }
  }

  /// Call when the app goes to background or user logs out.
  Future<void> pause() async {
    await _unsubscribe();
  }

  Future<void> dispose() async {
    await _unsubscribe();
    await _activityController.close();
    await _presenceController.close();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _subscribe() async {
    final wsId = _currentWorkspaceId;
    final uid = _currentUserId;
    if (wsId == null || uid == null) return;
    if (_channel != null) return; // already subscribed

    final channelName = 'workspace:$wsId';
    final channel = _client.channel(channelName);

    // ── Postgres changes: workspace_activity inserts ──
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'workspace_activity',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'workspace_id',
        value: wsId,
      ),
      callback: (_) {
        if (!_activityController.isClosed) {
          _activityController.add(null);
        }
      },
    );

    // ── Presence: track who is online ──
    channel.onPresenceSync((_) {
      _updatePresence(channel, uid);
    });

    channel.onPresenceJoin((_) {
      _updatePresence(channel, uid);
    });

    channel.onPresenceLeave((_) {
      _updatePresence(channel, uid);
    });

    channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Announce our own presence
        await channel.track({'user_id': uid, 'online_at': DateTime.now().toIso8601String()});
      }
    });

    _channel = channel;
  }

  Future<void> _unsubscribe() async {
    final ch = _channel;
    if (ch != null) {
      await _client.removeChannel(ch);
      _channel = null;
    }
    _onlineUserIds = {};
  }

  void _updatePresence(RealtimeChannel channel, String selfUserId) {
    final presenceState = channel.presenceState();
    final online = <String>{};
    for (final p in presenceState) {
      for (final presence in p.presences) {
        final uid = presence.payload['user_id'] as String?;
        if (uid != null && uid != selfUserId) {
          online.add(uid);
        }
      }
    }
    _onlineUserIds = online;
    if (!_presenceController.isClosed) {
      _presenceController.add(Set.unmodifiable(online));
    }
  }
}
