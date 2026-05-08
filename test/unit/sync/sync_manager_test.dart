import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farol/core/database/app_database.dart';
import 'package:farol/core/infrastructure/sync/operation_queue.dart';
import 'package:farol/core/infrastructure/sync/sync_manager.dart';
import 'package:farol/core/infrastructure/sync/sync_operations.dart';

class _FakeSupabase extends Fake implements SupabaseClient {}

class _SpyOperation extends SyncOperation {
  int localCalls = 0;
  int remoteCalls = 0;
  bool remoteThrows = false;

  _SpyOperation()
      : super(operationType: InsertExpenseOperation.type, payload: {'x': 1});

  @override
  Future<void> applyLocally() async => localCalls++;

  @override
  Future<void> executeRemote(SupabaseClient supabase) async {
    remoteCalls++;
    if (remoteThrows) throw Exception('network error');
  }
}

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  setUpAll(() => WidgetsFlutterBinding.ensureInitialized());

  group('SyncManager.execute', () {
    late AppDatabase db;
    late OperationQueue queue;

    setUp(() {
      db = _openTestDb();
      queue = OperationQueue(db, _FakeSupabase());
    });

    tearDown(() => db.close());

    test('online path: applyLocally + executeRemote, nothing queued', () async {
      final op = _SpyOperation();
      // SyncManager.initial has isOnline=true
      final mgr = SyncManager(queue, _FakeSupabase());

      await mgr.execute(op);
      mgr.dispose();

      expect(op.localCalls, 1, reason: 'applyLocally always runs');
      expect(op.remoteCalls, 1, reason: 'executeRemote runs when online');
      expect(await queue.pendingCount(), 0);
    });

    test('online path: remote failure enqueues for retry', () async {
      final op = _SpyOperation()..remoteThrows = true;
      final mgr = SyncManager(queue, _FakeSupabase());

      await mgr.execute(op);
      mgr.dispose();

      expect(op.localCalls, 1);
      expect(op.remoteCalls, 1);
      expect(await queue.pendingCount(), 1, reason: 'queued after remote fail');
    });

    test('statusStream emits when item is enqueued', () async {
      final mgr = SyncManager(queue, _FakeSupabase());
      final statuses = <SyncStatus>[];
      final sub = mgr.statusStream.listen(statuses.add);

      final op = _SpyOperation()..remoteThrows = true;
      await mgr.execute(op); // remote fails → enqueued → status emitted

      await Future<void>.delayed(Duration.zero); // pump microtask queue
      await sub.cancel();
      mgr.dispose();

      expect(statuses, isNotEmpty);
      expect(statuses.any((s) => s.pendingCount > 0), isTrue);
    });

    test('SyncStatus.initial is online with zero pending', () {
      const s = SyncStatus.initial;
      expect(s.isOnline, isTrue);
      expect(s.pendingCount, 0);
      expect(s.hasFailedOps, isFalse);
      expect(s.state, SyncState.idle);
    });

    // ── Offline path ──────────────────────────────────────────────────────────

    test('offline path: applyLocally runs, executeRemote is skipped, enqueued',
        () async {
      final op = _SpyOperation();
      final mgr = SyncManager(queue, _FakeSupabase());
      await mgr.setOnlineForTest(false);

      await mgr.execute(op);
      mgr.dispose();

      expect(op.localCalls, 1, reason: 'local write always happens');
      expect(op.remoteCalls, 0, reason: 'remote is skipped when offline');
      expect(await queue.pendingCount(), 1, reason: 'enqueued for later');
    });

    test('statusStream reflects offline state after setOnlineForTest(false)',
        () async {
      final mgr = SyncManager(queue, _FakeSupabase());
      final statuses = <SyncStatus>[];
      final sub = mgr.statusStream.listen(statuses.add);

      await mgr.setOnlineForTest(false);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      mgr.dispose();

      expect(statuses.any((s) => !s.isOnline), isTrue);
    });

    // ── processPendingQueue ───────────────────────────────────────────────────

    test('processPendingQueue: emits syncing then idle', () async {
      // Enqueue an item that will fail at remote (FakeSupabase throws)
      final mgr = SyncManager(queue, _FakeSupabase());
      final states = <SyncState>[];
      final sub = mgr.statusStream.listen((s) => states.add(s.state));

      // Enqueue by forcing a remote failure
      await mgr.execute(_SpyOperation()..remoteThrows = true);
      expect(await queue.pendingCount(), 1);

      await mgr.processPendingQueue();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      mgr.dispose();

      expect(states.contains(SyncState.syncing), isTrue,
          reason: 'processPendingQueue emits syncing before processing');
      expect(states.last, SyncState.idle,
          reason: 'always returns to idle when processPending does not throw');
    });

    test('processPendingQueue: guard prevents concurrent execution', () async {
      final mgr = SyncManager(queue, _FakeSupabase());
      final states = <SyncState>[];
      final sub = mgr.statusStream.listen((s) => states.add(s.state));

      // Manually set state to syncing before calling processPendingQueue
      // (simulate another call already in progress)
      // ignore: invalid_use_of_visible_for_testing_member
      // We trigger it twice concurrently; second call should be a no-op.
      final f1 = mgr.processPendingQueue();
      final f2 = mgr.processPendingQueue(); // concurrent call — should be skipped
      await Future.wait([f1, f2]);

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      mgr.dispose();

      // Count how many times 'syncing' appears — should be exactly 1
      final syncingCount = states.where((s) => s == SyncState.syncing).length;
      expect(syncingCount, 1,
          reason: 'second concurrent call is a no-op, syncing emitted once');
    });

    // ── Offline → Online reconnect ────────────────────────────────────────────

    test('coming back online triggers processPendingQueue', () async {
      final op = _SpyOperation();
      final mgr = SyncManager(queue, _FakeSupabase());
      final states = <SyncState>[];
      final sub = mgr.statusStream.listen((s) => states.add(s.state));

      // Go offline and queue an item
      await mgr.setOnlineForTest(false);
      await mgr.execute(op);
      expect(await queue.pendingCount(), 1);

      // Come back online — setOnlineForTest triggers processPendingQueue.
      // FakeSupabase.from throws so the item stays pending (retry < maxRetries),
      // but processPendingQueue does run (syncing state is emitted).
      await mgr.setOnlineForTest(true);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      mgr.dispose();

      expect(states.contains(SyncState.syncing), isTrue,
          reason: 'processPendingQueue triggered on reconnect');
      // Item stays pending (retry incremented to 1, still < maxRetries=3)
      expect(await queue.pendingCount(), 1);
    });

    // ── SyncStatus value object ───────────────────────────────────────────────

    test('SyncStatus.copyWith preserves unspecified fields', () {
      const original = SyncStatus.initial;
      final copy = original.copyWith(pendingCount: 5);
      expect(copy.pendingCount, 5);
      expect(copy.isOnline, original.isOnline);
      expect(copy.state, original.state);
      expect(copy.hasFailedOps, original.hasFailedOps);
    });
  });
}
