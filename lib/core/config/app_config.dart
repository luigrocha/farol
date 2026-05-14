import 'package:flutter/foundation.dart';

/// Central app configuration resolved from --dart-define-from-file=env.json.
/// Falls back to Uri.base (web) or localhost (mobile/desktop) when APP_BASE_URL
/// is not set, so invite links work correctly in every environment.
class AppConfig {
  AppConfig._();

  /// The base URL of this deployment, without a trailing slash.
  ///
  /// Resolution order:
  /// 1. APP_BASE_URL dart-define (production / staging)
  /// 2. kIsWeb → Uri.base stripped of fragment/query (auto-detects localhost)
  /// 3. Fallback: http://localhost
  static String get baseUrl {
    const defined = String.fromEnvironment('APP_BASE_URL');
    if (defined.isNotEmpty) return defined.replaceAll(RegExp(r'/+$'), '');

    if (kIsWeb) {
      // Uri.base in Flutter Web is the current page URL, e.g.:
      //   http://localhost:8080/  → http://localhost:8080
      //   https://luigrocha.github.io/farol/  → https://luigrocha.github.io/farol
      final base = Uri.base;
      final origin = '${base.scheme}://${base.host}'
          '${base.port != 0 && base.port != 80 && base.port != 443 ? ":${base.port}" : ""}';
      final path = base.path.replaceAll(RegExp(r'/+$'), '');
      return '$origin$path';
    }

    return 'http://localhost';
  }
}
