import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farol/core/database/app_database.dart';
import 'package:farol/core/infrastructure/sync/operation_queue.dart';
import 'package:farol/core/infrastructure/sync/sync_operations.dart';

class _FakeSupabase extends Fake implements SupabaseClient {}

class _SpyOperation extends SyncOperation {
  _SpyOperation({Map<String, dynamic>? payload, String? idempotencyKey})
      : super(
          operationType: InsertExpenseOperation.type,
          payload: payload ?? {'test': 'data'},
          idempotencyKey: idempotencyKey,
        );

  @override
  Future<void> applyLocally() async {}

  @override
  Future<void> executeRemote(SupabaseClient supabase) async {}
}

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  group('OperationQueue', () {
    late AppDatabase db;
    late OperationQueue queue;

    setUp(() {
      db = _openTestDb();
      queue = OperationQueue(db, _FakeSupabase());
    });

    tearDown(() => db.close());

    test('enqueue adds a pending item', () async {
      await queue.enqueue(_SpyOperation());
      expect(await queue.pendingCount(), 1);
      expect(await queue.hasPending, isTrue);
    });

    test('duplicate idempotency key is silently ignored', () async {
      const key = 'fixed-key-abc';
      await queue.enqueue(_SpyOperation(idempotencyKey: key));
      await queue.enqueue(_SpyOperation(idempotencyKey: key));
      expect(await queue.pendingCount(), 1);
    });

    test('processPending increments retry on unknown op type', () async {
      await queue.enqueue(_SpyOperation());
      // Overwrite to an unknown type so fromQueue throws
      await (db.update(db.syncQueueItems)
            ..where((t) => t.status.equals('pending')))
          .write(const SyncQueueItemsCompanion(
            operationType: Value('unknown_op'),
          ));

      await queue.processPending();

      final items = await db.select(db.syncQueueItems).get();
      expect(items.first.retryCount, 1);
      expect(items.first.status, 'pending'); // < maxRetries, stays pending
    });

    test('marks failed after maxRetries (3) exceeded', () async {
      await queue.enqueue(_SpyOperation());
      await (db.update(db.syncQueueItems)
            ..where((t) => t.status.equals('pending')))
          .write(const SyncQueueItemsCompanion(
            operationType: Value('unknown_op'),
            retryCount: Value(2), // next failure pushes to 3 → failed
          ));

      await queue.processPending();

      final items = await db.select(db.syncQueueItems).get();
      expect(items.first.status, 'failed');
      expect(items.first.error, isNotNull);
    });

    test('hasFailedItems reflects failed entries', () async {
      expect(await queue.hasFailedItems, isFalse);

      await queue.enqueue(_SpyOperation());
      await (db.update(db.syncQueueItems)
            ..where((t) => t.status.equals('pending')))
          .write(const SyncQueueItemsCompanion(status: Value('failed')));

      expect(await queue.hasFailedItems, isTrue);
    });

    test('pending count does not include completed items', () async {
      await queue.enqueue(_SpyOperation());
      await (db.update(db.syncQueueItems)
            ..where((t) => t.status.equals('pending')))
          .write(const SyncQueueItemsCompanion(status: Value('completed')));

      expect(await queue.pendingCount(), 0);
      expect(await queue.hasPending, isFalse);
    });
  });
}
