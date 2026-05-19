import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/recurring_occurrence.dart';

class RecurringOccurrencesRepository {
  final SupabaseClient _supabase;
  const RecurringOccurrencesRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Pending occurrences in [start]..[end] — used by ObligationEngine.
  Future<List<RecurringOccurrence>> getPendingInRange(
      DateTime start, DateTime end) async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('recurring_occurrences')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .gte('scheduled_date', start.toIso8601String().substring(0, 10))
        .lte('scheduled_date', end.toIso8601String().substring(0, 10))
        .order('scheduled_date');
    return data.map(RecurringOccurrence.fromJson).toList();
  }

  Future<List<RecurringOccurrence>> getByRule(String ruleId) async {
    final data = await _supabase
        .from('recurring_occurrences')
        .select()
        .eq('rule_id', ruleId)
        .order('scheduled_date');
    return data.map(RecurringOccurrence.fromJson).toList();
  }

  /// Bulk-insert occurrences — idempotent via ON CONFLICT DO NOTHING
  /// (unique constraint on rule_id + scheduled_date).
  Future<void> upsertOccurrences(List<RecurringOccurrence> occurrences) async {
    if (occurrences.isEmpty) return;
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final rows = occurrences.map((o) {
      final json = o.toJson();
      json['user_id'] = userId;
      return json;
    }).toList();

    await _supabase.from('recurring_occurrences').upsert(
          rows,
          onConflict: 'rule_id,scheduled_date',
          ignoreDuplicates: true,
        );
  }

  Future<RecurringOccurrence> markPaid({
    required String id,
    required DateTime paidDate,
    required double actualAmount,
    required int expenseId,
  }) async {
    final row = await _supabase
        .from('recurring_occurrences')
        .update({
          'status': 'paid',
          'paid_date': paidDate.toIso8601String().substring(0, 10),
          'actual_amount': actualAmount,
          'expense_id': expenseId,
        })
        .eq('id', id)
        .select()
        .single();
    return RecurringOccurrence.fromJson(row);
  }

  Future<RecurringOccurrence> markSkipped(String id, {String? notes}) async {
    final row = await _supabase
        .from('recurring_occurrences')
        .update({
          'status': 'skipped',
          if (notes != null) 'exception_notes': notes,
          'is_exception': notes != null,
        })
        .eq('id', id)
        .select()
        .single();
    return RecurringOccurrence.fromJson(row);
  }
}
