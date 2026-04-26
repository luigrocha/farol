import 'package:drift/drift.dart';
import 'dart:async';

QueryExecutor openConnection() {
  return _FakeExecutor();
}

class _FakeExecutor extends QueryExecutor {
  final Map<String, String> _settings = {};

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  bool get isSequential => true;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    _handleUpsert(statement, args);
  }

  void _handleUpsert(String statement, List<Object?>? args) {
    if (statement.contains('user_settings') && args != null && args.length >= 2) {
      // Drift generates different SQL for upsert depending on version/config
      // But usually key/value are the first two args or specifically named
      if (args[0] is String && args[1] is String) {
        _settings[args[0] as String] = args[1] as String;
      }
    }
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    _handleUpsert(statement, args);
    return 0;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(String statement, List<Object?> args) async {
    if (statement.contains('user_settings') && args.isNotEmpty && args[0] is String) {
      final key = args[0] as String;
      if (_settings.containsKey(key)) {
        return [{'key': key, 'value': _settings[key]}];
      }
    }
    return [];
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    _handleUpsert(statement, args);
    return 0;
  }

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  TransactionExecutor beginTransaction() => _FakeTransaction(this);
}

class _FakeTransaction extends TransactionExecutor {
  _FakeTransaction(this.executor);
  final _FakeExecutor executor;

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  bool get supportsNestedTransactions => false;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<void> rollback() async {}

  @override
  Future<void> send() async {}

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) => executor.runCustom(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) => executor.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) => executor.runInsert(statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(String statement, List<Object?> args) => executor.runSelect(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) => executor.runUpdate(statement, args);

  @override
  Future<void> runBatched(BatchedStatements statements) => executor.runBatched(statements);

  @override
  TransactionExecutor beginTransaction() => throw UnsupportedError('Nested transactions not supported');
}
