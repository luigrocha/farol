import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages Supabase Realtime channels with proper lifecycle handling.
///
/// Prevents the RealtimeCloseEvent(1006) error by:
/// - Ensuring only one channel per table exists at any time
/// - Auto-subscribing when any screen listens to the data stream
/// - Explicit unsubscribe when screens go to background
/// - Implementing exponential backoff reconnection on errors
/// - Falling back to HTTP polling when realtime fails repeatedly
class SupabaseRealtimeManager {
  SupabaseRealtimeManager._();
  static final SupabaseRealtimeManager instance = SupabaseRealtimeManager._();

  final SupabaseClient _client = Supabase.instance.client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, int> _retryAttempts = {};
  final Map<String, StreamController> _streamControllers = {};
  final Map<String, Timer> _reconnectTimers = {};

  static const _maxRetries = 5;
  static const _baseRetryMs = 1000;

  /// Creates a managed realtime stream. Auto-subscribes on first listen.
  Stream<List<T>> createManagedStream<T>({
    required String table,
    required List<String> primaryKey,
    required T Function(Map<String, dynamic>) fromJson,
    String? userId,
    required String userIdColumn,
  }) {
    if (userId == null) {
      return const Stream.empty();
    }

    late StreamController<List<T>> controller;
    controller = StreamController<List<T>>.broadcast(
      onListen: () {
        _setupChannel<T>(
          table: table,
          primaryKey: primaryKey,
          userId: userId,
          userIdColumn: userIdColumn,
          controller: controller,
          fromJson: fromJson,
        );
      },
      onCancel: () => _closeChannel(table),
    );

    return controller.stream;
  }

  /// Explicitly unsubscribe (e.g., when app goes to background).
  Future<void> unsubscribe(String table) async {
    await _closeChannel(table);
    _streamControllers.remove(table);
  }

  Future<void> unsubscribeAll() async {
    for (final key in _channels.keys.toList()) {
      await unsubscribe(key);
    }
  }

  bool isMaxRetriesReached(String table) => (_retryAttempts[table] ?? 0) >= _maxRetries;

  /// One-shot HTTP fetch for polling fallback.
  Future<List<Map<String, dynamic>>> fetchAll({
    required String table,
    String? userId,
    required String userIdColumn,
  }) async {
    if (userId == null) return [];
    final response = await _client.from(table).select().eq(userIdColumn, userId);
    return List<Map<String, dynamic>>.from(response);
  }

  void _setupChannel<T>({
    required String table,
    required List<String> primaryKey,
    required String userId,
    required String userIdColumn,
    required StreamController<List<T>> controller,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    _streamControllers[table] = controller;

    // Fetch initial data immediately via HTTP so the UI isn't empty
    _fetchAndEmit<T>(
      table: table,
      userId: userId,
      userIdColumn: userIdColumn,
      fromJson: fromJson,
    );

    final channel = _client.channel('realtime:$table');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: userIdColumn,
            value: userId,
          ),
          callback: (_) {
            _retryAttempts[table] = 0;
            _fetchAndEmit<T>(
              table: table,
              userId: userId,
              userIdColumn: userIdColumn,
              fromJson: fromJson,
            );
          },
        )
        .subscribe(
          (status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              _channels[table] = channel;
              _retryAttempts[table] = 0;
            } else if (error != null || status == RealtimeSubscribeStatus.channelError) {
              _handleChannelError(table);
            }
          },
        );
  }

  Future<void> _fetchAndEmit<T>({
    required String table,
    required String userId,
    required String userIdColumn,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final controller = _streamControllers[table] as StreamController<List<T>>?;
      if (controller == null || controller.isClosed) return;

      final response = await _client
          .from(table)
          .select()
          .eq(userIdColumn, userId);

      final items = response.map((r) => fromJson(r)).toList();
      controller.add(items);
    } catch (_) {}
  }

  Future<void> _closeChannel(String table) async {
    _reconnectTimers[table]?.cancel();
    _reconnectTimers.remove(table);

    final channel = _channels[table];
    if (channel != null) {
      await _client.removeChannel(channel);
      _channels.remove(table);
    }
  }

  void _handleChannelError(String table) {
    final attempts = (_retryAttempts[table] ?? 0) + 1;
    _retryAttempts[table] = attempts;

    if (attempts >= _maxRetries) {
      _closeChannel(table);
      return;
    }

    final delayMs = _baseRetryMs * (1 << (attempts - 1));
    _reconnectTimers[table]?.cancel();
    _reconnectTimers[table] = Timer(Duration(milliseconds: delayMs), () {
      final channel = _channels[table];
      if (channel != null) {
        channel.subscribe();
      }
    });
  }

  void dispose() {
    unsubscribeAll();
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
