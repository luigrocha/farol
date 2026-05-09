import 'dart:convert';
import '../database/app_database.dart';
import '../domain/entities/cashflow_forecast.dart';

/// Client-side TTL cache for the cashflow forecast chart (90-day simulation).
///
/// Stores the serialized [CashflowForecast] in Drift [UserSettings] under a
/// compound key that includes the period start/end dates, so a period change
/// automatically invalidates the cached result.
///
/// Default TTL: 2 hours. The cache is also explicitly invalidated by
/// [SyncManager] after a successful sync, so the chart always reflects
/// up-to-date data after a reconnect.
class ForecastCacheRepository {
  final AppDatabase _db;

  static const _key = 'cashflow_forecast_cache';

  /// Maximum age of a cached result before it is treated as stale.
  static const _ttl = Duration(hours: 2);

  const ForecastCacheRepository(this._db);

  /// Returns a cached [CashflowForecast] if one exists for [periodKey] and is
  /// still within the TTL window, otherwise returns `null`.
  Future<CashflowForecast?> get(String periodKey) async {
    final raw = await _db.getSetting(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;

      // Period mismatch → stale
      if (wrapper['periodKey'] != periodKey) return null;

      final cachedAt = DateTime.parse(wrapper['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;

      final forecast = CashflowForecast.fromJson(
          wrapper['forecast'] as Map<String, dynamic>);
      return forecast;
    } catch (_) {
      return null;
    }
  }

  /// Persists [forecast] for [periodKey], overwriting any previous entry.
  Future<void> put(String periodKey, CashflowForecast forecast) async {
    final wrapper = {
      'periodKey': periodKey,
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'forecast': forecast.toJson(),
    };
    await _db.setSetting(_key, jsonEncode(wrapper));
  }

  /// Clears the cached forecast (e.g., after a successful sync).
  Future<void> invalidate() async {
    await _db.setSetting(_key, '');
  }
}
