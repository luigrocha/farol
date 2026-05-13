import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farol/core/database/app_database.dart';
import 'package:farol/core/infrastructure/sync/operation_queue.dart';
import 'package:farol/core/infrastructure/sync/sync_manager.dart';
import 'package:farol/core/infrastructure/sync/sync_operations.dart';
import 'package:farol/core/repositories/expense_repository.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _FakeAuth extends Fake implements GoTrueClient {
  @override
  User? get currentUser => _FakeUser();

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
}

class _FakeUser extends Fake implements User {
  @override
  String get id => 'test-user-id';
}

class _FakeSupabase extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => _FakeAuth();

  @override
  SupabaseQueryBuilder from(String table) =>
      throw UnimplementedError('not expected in these tests');
}

// ─── Spy SyncManager ─────────────────────────────────────────────────────────

class _SpySyncManager extends SyncManager {
  final List<SyncOperation> executed = [];

  _SpySyncManager(super.queue, super.supabase);

  @override
  Future<void> execute(SyncOperation op) async => executed.add(op);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  setUpAll(() => WidgetsFlutterBinding.ensureInitialized());

  group('ExpenseRepository.insert with SyncManager', () {
    late AppDatabase db;
    late _FakeSupabase supabase;

    setUp(() {
      db = _openTestDb();
      supabase = _FakeSupabase();
    });

    tearDown(() => db.close());

    test('routes through SyncManager and returns 0 sentinel', () async {
      final queue = OperationQueue(db, supabase);
      final mgr = _SpySyncManager(queue, supabase);
      await mgr.setOnlineForTest(false);
      final repo = ExpenseRepository(supabase, syncManager: mgr);

      final result = await repo.insert(
        transactionDate: DateTime(2026, 5, 1),
        month: 5,
        year: 2026,
        payType: 'debit',
        category: 'food',
        amount: 42.50,
        paymentMethod: 'nubank',
      );

      expect(result, 0, reason: 'sentinel when SyncManager path is taken');
      expect(mgr.executed.length, 1);
      expect(mgr.executed.first, isA<InsertExpenseOperation>());
      mgr.dispose();
    });

    test('InsertExpenseOperation carries correct payload fields', () async {
      final queue = OperationQueue(db, supabase);
      final mgr = _SpySyncManager(queue, supabase);
      await mgr.setOnlineForTest(false);
      final repo = ExpenseRepository(supabase, syncManager: mgr);

      await repo.insert(
        transactionDate: DateTime(2026, 5, 15),
        month: 5,
        year: 2026,
        payType: 'credit',
        category: 'transport',
        amount: 100.0,
        paymentMethod: 'visa',
        storeDescription: 'Uber',
      );

      final op = mgr.executed.first as InsertExpenseOperation;
      expect(op.payload['month'], 5);
      expect(op.payload['year'], 2026);
      expect(op.payload['amount'], 100.0);
      expect(op.payload['category'], 'transport');
      expect(op.payload['store_description'], 'Uber');
      expect(op.payload['user_id'], 'test-user-id');
      expect(op.idempotencyKey, isNotEmpty);
      mgr.dispose();
    });

    test('real SyncManager enqueues when remote fails', () async {
      final queue = OperationQueue(db, supabase);
      final mgr = SyncManager(queue, supabase);
      await mgr.setOnlineForTest(false);
      final repo = ExpenseRepository(supabase, syncManager: mgr);

      // Offline → operation queued locally
      await repo.insert(
        transactionDate: DateTime(2026, 5, 1),
        month: 5,
        year: 2026,
        payType: 'debit',
        category: 'food',
        amount: 20.0,
        paymentMethod: 'nubank',
      );

      mgr.dispose();
      expect(await queue.pendingCount(), 1);
    });

    test('without SyncManager, no item is queued', () async {
      // Repo without syncManager — goes to Supabase directly.
      // FakeSupabase.from() throws, so insert throws too.
      final repo = ExpenseRepository(supabase);

      expect(
        () => repo.insert(
          transactionDate: DateTime(2026, 5, 1),
          month: 5,
          year: 2026,
          payType: 'debit',
          category: 'food',
          amount: 10.0,
          paymentMethod: 'nubank',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
