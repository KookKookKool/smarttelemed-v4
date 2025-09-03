import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized STMS API endpoints for emr-life.com
/// Uses runtime environment variable `STMS_API_BASE` when available (via .env)
/// Falls back to the compile-time default if not provided.
class StmsApi {
  // Compile-time fallback base (must be a true const)
  // Use a non-sensitive placeholder in source. Production/staging URLs
  // should come from runtime env (.env) or CI --dart-define.
  static const String _defaultBase =
      'https://emr-life.com/expert/telemed/StmsApi';

  // Runtime-resolvable base: prefer dotenv.env['STMS_API_BASE'] when available
  static String get base {
    try {
      final env = dotenv.env['STMS_API_BASE'];
      if (env != null && env.isNotEmpty) return env;
    } catch (e) {
      // ignore - dotenv may not be initialized in some contexts
    }
    return _defaultBase;
  }

  // Common endpoints
  static String get listCareUnit => '${base}/list_care_unit';
  static String get addVisit => '${base}/add_visit';

  // Helper to build other endpoints (optional)
  static String endpoint(String path) => '${base}/$path';
}
