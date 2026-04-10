import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/remote_config.dart';

class ConfigRepository {
  final SupabaseClient _client;

  const ConfigRepository(this._client);

  static const _table = 'remote_configs';

  // -------------------------------------------------------------------------
  // Fetch all active configs
  // -------------------------------------------------------------------------

  Future<List<RemoteConfig>> fetchAll() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('is_active', true)
        .order('key');
    return (data as List)
        .map((r) => RemoteConfig.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<RemoteConfig?> fetchByKey(String key) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('key', key)
        .eq('is_active', true)
        .maybeSingle();
    if (data == null) return null;
    return RemoteConfig.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Realtime stream — all active configs
  // -------------------------------------------------------------------------

  Stream<List<RemoteConfig>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('key')
        .map(
          (rows) => rows
              .where((r) => (r['is_active'] as bool?) ?? true)
              .map(RemoteConfig.fromMap)
              .toList(),
        );
  }
}
