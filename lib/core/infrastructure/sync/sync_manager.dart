import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'operation_queue.dart';
import 'sync_operations.dart';

enum SyncState { idle, syncing, error }

class SyncStatus {
  final SyncState state;
  final int pendingCount;
  final bool hasFailedOps;
  final DateTime? lastSyncAt;
  final bool isOnline;

  const SyncStatus({
    required this.state,
    required this.pendingCount,
    required this.hasFailedOps,
    required this.lastSyncAt,
    required this.isOnline,
  });

  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    bool? hasFailedOps,
    DateTime? lastSyncAt,
    bool? isOnline,
  }) =>
      SyncStatus(
        state: state ?? this.state,
        pendingCount: pendingCount ?? this.pendingCount,
        hasFailedOps: hasFailedOps ?? this.hasFailedOps,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        isOnline: isOnline ?? this.isOnline,
      );

  static const SyncStatus initial = SyncStatus(
    state: SyncState.idle,
    pendingCount: 0,
    hasFailedOps: false,
    lastSyncAt: null,
    isOnline: true,
  );
}

/// Orchestrates optimistic local writes + remote sync.
/// - If online: writes locally then immediately to Supabase.
/// - If offline: writes locally, enqueues remote write for later.
/// - On reconnect: automatically drains the queue.
class SyncManager {
  final OperationQueue _queue;
  final SupabaseClient _supabase;
  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.initial;
  StreamSubscription? _connectivitySub;

  SyncManager(this._queue, this._supabase) {
    _startConnectivityMonitor();
  }

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _status;

  /// Execute an operation: apply locally + remote (or enqueue if offline).
  Future<void> execute(SyncOperation op) async {
    // Always apply locally first (optimistic)
    await op.applyLocally();

    if (_status.isOnline) {
      try {
        await op.executeRemote(_supabase);
        _emitStatus(_status.copyWith(lastSyncAt: DateTime.now()));
      } catch (_) {
        // Remote failed → enqueue for retry
        await _queue.enqueue(op);
        await _refreshStatus();
      }
    } else {
      await _queue.enqueue(op);
      await _refreshStatus();
    }
  }

  Future<void> processPendingQueue() async {
    if (_status.state == SyncState.syncing) return;
    _emitStatus(_status.copyWith(state: SyncState.syncing));
    try {
      await _queue.processPending();
      await _refreshStatus();
      _emitStatus(_status.copyWith(
          state: SyncState.idle, lastSyncAt: DateTime.now()));
    } catch (_) {
      _emitStatus(_status.copyWith(state: SyncState.error));
    }
  }

  void _startConnectivityMonitor() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      final wasOffline = !_status.isOnline;
      _emitStatus(_status.copyWith(isOnline: isOnline));

      // Auto-drain queue when coming back online
      if (isOnline && wasOffline) {
        await processPendingQueue();
      }
    });
  }

  Future<void> _refreshStatus() async {
    final count = await _queue.pendingCount();
    final hasFailed = await _queue.hasFailedItems;
    _emitStatus(_status.copyWith(
      pendingCount: count,
      hasFailedOps: hasFailed,
    ));
  }

  void _emitStatus(SyncStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }
}
