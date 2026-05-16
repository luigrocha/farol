// lib/core/repositories/space_activity_repository.dart
//
// Data access for the space_activity feed.
// Mirrors WorkspaceActivityRepository exactly but queries space_activity
// and returns SpaceActivity entities.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/space_activity.dart';

class SpaceActivityRepository {
  final SupabaseClient _supabase;

  const SpaceActivityRepository(this._supabase);

  /// Fetches the [limit] most recent activity items for [spaceId].
  /// Used by the dashboard preview card.
  Future<List<SpaceActivity>> fetchLatest({
    required String spaceId,
    int limit = 3,
  }) async {
    final rows = await _supabase
        .from('space_activity')
        .select()
        .eq('space_id', spaceId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(SpaceActivity.fromJson).toList();
  }

  /// Paginated fetch for a full activity feed.
  /// [before] is used as a cursor — fetches items older than that timestamp.
  Future<List<SpaceActivity>> fetchPage({
    required String spaceId,
    int pageSize = 30,
    DateTime? before,
  }) async {
    var query = _supabase
        .from('space_activity')
        .select()
        .eq('space_id', spaceId);

    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(pageSize);
    return rows.map(SpaceActivity.fromJson).toList();
  }
}
