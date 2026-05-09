import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/recurring_rule.dart';

class RecurringRulesRepository {
  final SupabaseClient _supabase;
  final String? workspaceId;

  const RecurringRulesRepository(this._supabase, {this.workspaceId});

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<RecurringRule>> watchAll() {
    final wsId = workspaceId;
    final userId = _userId;
    final filterKey = wsId != null ? 'workspace_id' : 'user_id';
    final filterVal = wsId ?? userId;
    if (filterVal == null) return Stream.value([]);
    return _supabase
        .from('recurring_rules')
        .stream(primaryKey: ['id'])
        .eq(filterKey, filterVal)
        .map((rows) => rows.map(RecurringRule.fromJson).toList());
  }

  Future<List<RecurringRule>> getActive() async {
    final wsId = workspaceId;
    final userId = _userId;
    final filterKey = wsId != null ? 'workspace_id' : 'user_id';
    final filterVal = wsId ?? userId;
    if (filterVal == null) return [];
    final data = await _supabase
        .from('recurring_rules')
        .select()
        .eq(filterKey, filterVal)
        .eq('status', 'active');
    return data.map(RecurringRule.fromJson).toList();
  }

  Future<List<RecurringRule>> getAll() async {
    final wsId = workspaceId;
    final userId = _userId;
    final filterKey = wsId != null ? 'workspace_id' : 'user_id';
    final filterVal = wsId ?? userId;
    if (filterVal == null) return [];
    final data = await _supabase
        .from('recurring_rules')
        .select()
        .eq(filterKey, filterVal)
        .order('created_at', ascending: false);
    return data.map(RecurringRule.fromJson).toList();
  }

  Future<RecurringRule> create(RecurringRule rule) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    final payload = rule.toJson()..['user_id'] = userId;
    if (workspaceId != null) payload['workspace_id'] = workspaceId;
    final row = await _supabase
        .from('recurring_rules')
        .insert(payload)
        .select()
        .single();
    return RecurringRule.fromJson(row);
  }

  Future<RecurringRule> update(String id, RecurringRule rule) async {
    final row = await _supabase
        .from('recurring_rules')
        .update({
          ...rule.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return RecurringRule.fromJson(row);
  }

  Future<void> updateStatus(String id, RecurringStatus status,
      {DateTime? pausedUntil}) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (pausedUntil != null) {
      updates['paused_until'] = pausedUntil.toIso8601String().substring(0, 10);
    } else if (status == RecurringStatus.active) {
      updates['paused_until'] = null;
    }
    await _supabase.from('recurring_rules').update(updates).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('recurring_rules').delete().eq('id', id);
  }
}
