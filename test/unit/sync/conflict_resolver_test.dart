import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/infrastructure/sync/conflict_resolver.dart';

void main() {
  const resolver = ConflictResolver();

  Map<String, dynamic> record(String ts) => {'updated_at': ts, 'value': ts};
  Map<String, dynamic> recordDt(DateTime dt) =>
      {'updated_at': dt, 'value': dt.toIso8601String()};

  group('ConflictResolver.resolve — Last-Write-Wins', () {
    test('local is newer → local wins', () {
      final local = record('2026-05-08T12:00:00.000Z');
      final remote = record('2026-05-08T11:00:00.000Z');
      expect(resolver.resolve(local, remote), same(local));
    });

    test('remote is newer → remote wins', () {
      final local = record('2026-05-08T10:00:00.000Z');
      final remote = record('2026-05-08T11:00:00.000Z');
      expect(resolver.resolve(local, remote), same(remote));
    });

    test('equal timestamps → remote wins (Supabase is source of truth)', () {
      const ts = '2026-05-08T10:00:00.000Z';
      final local = record(ts);
      final remote = record(ts);
      expect(resolver.resolve(local, remote), same(remote));
    });

    test('null local timestamp → remote wins', () {
      final local = {'updated_at': null, 'value': 'local'};
      final remote = record('2026-05-08T10:00:00.000Z');
      expect(resolver.resolve(local, remote), same(remote));
    });

    test('null remote timestamp → remote wins (fallback, not local)', () {
      // When remote has no timestamp, the condition localTs.isAfter(remoteTs)
      // short-circuits (remoteTs is null) → returns remote as fallback.
      final local = record('2026-05-08T10:00:00.000Z');
      final remote = {'updated_at': null, 'value': 'remote'};
      expect(resolver.resolve(local, remote), same(remote));
    });

    test('both timestamps null → remote wins (fallback)', () {
      final local = {'updated_at': null, 'value': 'local'};
      final remote = {'updated_at': null, 'value': 'remote'};
      expect(resolver.resolve(local, remote), same(remote));
    });

    test('DateTime objects are accepted directly (not just strings)', () {
      final now = DateTime.now();
      final local = recordDt(now.add(const Duration(hours: 1)));
      final remote = recordDt(now);
      expect(resolver.resolve(local, remote), same(local));
    });

    test('ISO string with milliseconds is parsed correctly', () {
      final local = record('2026-05-08T15:30:00.123Z');
      final remote = record('2026-05-08T15:30:00.000Z');
      expect(resolver.resolve(local, remote), same(local),
          reason: 'local is 123ms newer');
    });

    test('returns the same Map reference, does not copy', () {
      final local = record('2026-05-08T12:00:00.000Z');
      final remote = record('2026-05-08T11:00:00.000Z');
      final result = resolver.resolve(local, remote);
      expect(identical(result, local), isTrue);
    });
  });
}
