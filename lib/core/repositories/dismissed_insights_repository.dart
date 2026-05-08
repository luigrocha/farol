import 'dart:convert';
import '../database/app_database.dart';

/// Persists dismissed insight IDs/groups in UserSettings (Drift).
/// Key: 'dismissed_insights' → JSON array of strings.
class DismissedInsightsRepository {
  final AppDatabase _db;
  static const _key = 'dismissed_insights';

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
}
