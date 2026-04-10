import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/production_health.dart';

/// Verifies that all production API keys (OpenAI, LiveKit, FCM) are
/// switched from test placeholders to live Supabase Secrets, and that the
/// system is ready for production traffic.
class ProductionService {
  final SupabaseClient _client;

  ProductionService(this._client);

  // -------------------------------------------------------------------------
  // Required secret keys
  // -------------------------------------------------------------------------

  static const List<String> requiredSecrets = [
    'OPENAI_API_KEY',
    'LIVEKIT_API_KEY',
    'LIVEKIT_API_SECRET',
    'FCM_SERVER_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
  ];

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Calls the [verify-production-secrets] Edge Function and returns the
  /// full health report. Falls back to [ProductionHealth.notReady] on error.
  Future<ProductionHealth> verifySecrets() async {
    try {
      final result = await _client.functions.invoke(
        'verify-production-secrets',
        method: HttpMethod.post,
      );
      if (result.status != 200 && result.status != 206) {
        return ProductionHealth.notReady(requiredSecrets);
      }
      final data = result.data as Map<String, dynamic>?;
      if (data == null) return ProductionHealth.notReady(requiredSecrets);
      return ProductionHealth.fromMap(data);
    } catch (_) {
      return ProductionHealth.notReady(requiredSecrets);
    }
  }

  /// Returns [true] only if all secrets are set and no key is a known
  /// test/placeholder value.
  Future<bool> isProductionReady() async {
    final health = await verifySecrets();
    return health.isProductionReady;
  }

  /// Fetches the persisted health state from the DB (cheaper than calling
  /// the Edge Function on every app start).
  Future<ProductionHealth> getCachedHealth() async {
    try {
      final raw = await _client.rpc('get_production_health');
      if (raw == null) return ProductionHealth.notReady(requiredSecrets);
      final entries = raw as List;
      final secrets = entries
          .map((e) => SecretStatus.fromMap(e as Map<String, dynamic>))
          .toList();
      final allSet = secrets.isNotEmpty && secrets.every((s) => s.isSet);
      return ProductionHealth(
        allSecretsConfigured: allSet,
        secrets: secrets,
        checkedAt: DateTime.now(),
        environment: 'production',
      );
    } catch (_) {
      return ProductionHealth.notReady(requiredSecrets);
    }
  }

  /// Validates that a given key value does not look like a test placeholder.
  static bool looksLikeTestKey(String value) {
    final lower = value.toLowerCase();
    return lower.contains('test') ||
        lower.contains('placeholder') ||
        lower.contains('dummy') ||
        lower.contains('xxx') ||
        lower.contains('your_') ||
        value.length < 10;
  }

  /// Mask a key value for display: show first 4 chars + stars.
  static String maskKey(String value) {
    if (value.length < 4) return '****';
    return '${value.substring(0, 4)}${'*' * (value.length - 4).clamp(0, 20)}';
  }
}
