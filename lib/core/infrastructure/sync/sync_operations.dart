import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for all sync operations.
/// Each operation knows how to apply itself locally (Drift) and remotely (Supabase).
abstract class SyncOperation {
  final String operationType;
  final String idempotencyKey;
  final Map<String, dynamic> payload;

  SyncOperation({
    required this.operationType,
    required this.payload,
    String? idempotencyKey,
  }) : idempotencyKey = idempotencyKey ?? _generateUuid();

  /// Apply optimistically to local Drift database (always runs first).
  Future<void> applyLocally();

  /// Execute against Supabase (runs if online, or on reconnect from queue).
  Future<void> executeRemote(SupabaseClient supabase);

  String get payloadJson => jsonEncode(payload);

  static String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10).map(hex).join()}';
  }

  static SyncOperation fromQueue({
    required String operationType,
    required String payloadJson,
    required String idempotencyKey,
  }) {
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    return switch (operationType) {
      InsertExpenseOperation.type =>
        InsertExpenseOperation.fromPayload(payload, idempotencyKey),
      _ => throw UnsupportedError('Unknown operation: $operationType'),
    };
  }
}

// ─── InsertExpenseOperation ───────────────────────────────────────────────────

class InsertExpenseOperation extends SyncOperation {
  static const String type = 'insert_expense';

  InsertExpenseOperation({
    required super.payload,
    super.idempotencyKey,
  }) : super(
          operationType: type,
        );

  InsertExpenseOperation.fromPayload(
      Map<String, dynamic> payload, String idempotencyKey)
      : super(
          operationType: type,
          payload: payload,
          idempotencyKey: idempotencyKey,
        );

  @override
  Future<void> applyLocally() async {
    // No Drift expense table writable yet (Drift Expenses table uses int id from Supabase).
    // Local optimism is provided by the Riverpod state cache invalidation after remote write.
    // This is a no-op placeholder — can be upgraded to a full Drift write in a future iteration.
  }

  @override
  Future<void> executeRemote(SupabaseClient supabase) async {
    // Use idempotencyKey as a unique marker — Supabase upsert on idempotency_key
    // to avoid duplicates if retried.
    final row = Map<String, dynamic>.from(payload);
    row['idempotency_key'] = idempotencyKey;
    await supabase.from('expenses').upsert(
          row,
          onConflict: 'idempotency_key',
          ignoreDuplicates: true,
        );
  }
}
