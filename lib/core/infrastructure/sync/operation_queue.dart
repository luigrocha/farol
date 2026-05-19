import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/app_database.dart';
import 'sync_operations.dart';

/// Persistent operation queue backed by Drift.
/// Survives app restarts. Idempotency keys prevent duplicate remote writes.
class OperationQueue {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  static const int _maxRetries = 3;
  static const int _maxQueueSize = 500;

  OperationQueue(this._db, this._supabase);

  Future<void> enqueue(SyncOperation op) async {
    final count = await _pendingCount();
    if (count >= _maxQueueSize) {
      // Drop oldest failed items to make room
      await _pruneOldFailed();
    }

    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            operationType: op.operationType,
            payload: op.payloadJson,
            idempotencyKey: op.idempotencyKey,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Process all pending items in FIFO order.
  /// Returns count of successfully processed items.
  Future<int> processPending() async {
    final items = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    int processed = 0;
    for (final item in items) {
      final success = await _processItem(item);
      if (success) processed++;
      // Small delay between items to avoid request spikes
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return processed;
  }

  Future<bool> _processItem(SyncQueueItem item) async {
    try {
      final op = SyncOperation.fromQueue(
        operationType: item.operationType,
        payloadJson: item.payload,
        idempotencyKey: item.idempotencyKey,
      );
      await op.executeRemote(_supabase);
      await _markCompleted(item.id);
      return true;
    } catch (e) {
      final newRetry = item.retryCount + 1;
      if (newRetry >= _maxRetries) {
        await _markFailed(item.id, e.toString());
      } else {
        await _incrementRetry(item.id, newRetry, e.toString());
      }
      return false;
    }
  }

  Future<int> _pendingCount() async {
    final result = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.status.equals('pending')))
        .get();
    return result.length;
  }

  Future<int> pendingCount() => _pendingCount();

  Future<bool> get hasPending async => await _pendingCount() > 0;

  Future<bool> get hasFailedItems async {
    final result = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.status.equals('failed')))
        .get();
    return result.isNotEmpty;
  }

  Future<void> _markCompleted(int id) async {
    await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(id)))
        .write(SyncQueueItemsCompanion(
      status: const Value('completed'),
      processedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _markFailed(int id, String error) async {
    await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(id)))
        .write(SyncQueueItemsCompanion(
      status: const Value('failed'),
      error: Value(error),
      processedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _incrementRetry(int id, int newCount, String error) async {
    await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(id)))
        .write(SyncQueueItemsCompanion(
      retryCount: Value(newCount),
      error: Value(error),
    ));
  }

  Future<void> _pruneOldFailed() async {
    final failed = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.status.equals('failed'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(50))
        .get();
    for (final item in failed) {
      await (_db.delete(_db.syncQueueItems)..where((t) => t.id.equals(item.id)))
          .go();
    }
  }
}
