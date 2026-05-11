import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/workspace_activity.dart';

class WorkspaceActivityRepository {
  final SupabaseClient _supabase;

  const WorkspaceActivityRepository(this._supabase);

  /// Fetches the [limit] most recent activity items for [workspaceId].
  /// Used by the dashboard preview card.
  Future<List<WorkspaceActivity>> fetchLatest({
    required String workspaceId,
    int limit = 3,
  }) async {
    final rows = await _supabase
        .from('workspace_activity')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(WorkspaceActivity.fromJson).toList();
  }

  /// Paginated fetch for the full activity feed screen.
  /// [before] is used as a cursor — fetches items older than that timestamp.
  Future<List<WorkspaceActivity>> fetchPage({
    required String workspaceId,
    int pageSize = 30,
    DateTime? before,
  }) async {
    var filter = _supabase
        .from('workspace_activity')
        .select()
        .eq('workspace_id', workspaceId);

    if (before != null) {
      filter = filter.lt('created_at', before.toIso8601String());
    }

    final rows = await filter
        .select()
        .order('created_at', ascending: false)
        .limit(pageSize);
    return rows.map(WorkspaceActivity.fromJson).toList();
  }
}
