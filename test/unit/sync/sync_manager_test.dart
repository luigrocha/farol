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
  });
}
