import 'dart:convert';
import '../database/app_database.dart';
import '../domain/entities/financial_insight.dart';
import '../domain/entities/insight_stats.dart';

/// Persists dismissed insight IDs/groups in UserSettings (Drift).
///
/// Keys:
/// - `'dismissed_insights'` → JSON array of dismissed ID/group strings.
/// - `'insight_dismissal_stats'` → JSON map `{"overdraftRisk": {"count": 2, "lastAt": "..."}}`
///   used for dismiss-rate analytics.
class DismissedInsightsRepository {
  final AppDatabase _db;
  static const _key = 'dismissed_insights';
  static const _statsKey = 'insight_dismissal_stats';

  const DismissedInsightsRepository(this._db);

  Future<Set<String>> getDismissed() async {
    final raw = await _db.getSetting(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> dismiss(String idOrGroup) async {
    final current = await getDismissed();
    current.add(idOrGroup);
    await _db.setSetting(_key, jsonEncode(current.toList()));
  }

  Future<void> restore(String idOrGroup) async {
    final current = await getDismissed();
    current.remove(idOrGroup);
    await _db.setSetting(_key, jsonEncode(current.toList()));
  }

  Future<void> clearAll() async {
    await _db.setSetting(_key, '[]');
  }

  // ── Dismiss-rate analytics ───────────────────────────────────────────────

  /// Records a dismiss event for [type].
  /// Increments the counter and updates [lastDismissedAt] in UserSettings.
  Future<void> trackDismiss(InsightType type) async {
    final raw = await _db.getSetting(_statsKey);
    final Map<String, dynamic> stats = raw != null && raw.isNotEmpty
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : {};

    final key = type.name;
    final existing = stats[key] as Map<String, dynamic>? ?? {};
    final count = (existing['count'] as int? ?? 0) + 1;
    stats[key] = {
      'count': count,
      'lastAt': DateTime.now().toUtc().toIso8601String(),
    };

    await _db.setSetting(_statsKey, jsonEncode(stats));
  }

  /// Returns dismiss stats sorted by [InsightStats.dismissedCount] descending.
  Future<List<InsightStats>> getStats() async {
    final raw = await _db.getSetting(_statsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = <InsightStats>[];

      for (final entry in map.entries) {
        // Match the string key back to an InsightType enum value.
        final type =
            InsightType.values.where((t) => t.name == entry.key).firstOrNull;
        if (type == null) continue;

        final data = entry.value as Map<String, dynamic>;
        final count = data['count'] as int? ?? 0;
        final lastAtRaw = data['lastAt'] as String?;
        final lastAt = lastAtRaw != null ? DateTime.tryParse(lastAtRaw) : null;

        result.add(InsightStats(
          type: type,
          dismissedCount: count,
          lastDismissedAt: lastAt,
        ));
      }

      result.sort((a, b) => b.dismissedCount.compareTo(a.dismissedCount));
      return result;
    } catch (_) {
      return [];
    }
  }
}
