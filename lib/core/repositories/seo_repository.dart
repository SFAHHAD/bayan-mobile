import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/seo_metadata.dart';

class SeoRepository {
  final SupabaseClient _client;

  const SeoRepository(this._client);

  /// Derives the Edge Functions base URL from the Supabase REST URL.
  /// e.g. https://xyz.supabase.co  →  https://xyz.supabase.co/functions/v1
  String get _edgeFunctionsBaseUrl {
    final restUrl = _client.rest.url; // e.g. https://xyz.supabase.co/rest/v1
    final projectUrl = restUrl.replaceFirst(RegExp(r'/rest/v1$'), '');
    return '$projectUrl/functions/v1';
  }

  // -------------------------------------------------------------------------
  // Fetch diwan metadata for sharing (direct DB query — no extra Edge hop)
  // -------------------------------------------------------------------------

  Future<SeoMetadata> fetchMetadata(String diwanId) async {
    final data = await _client
        .from('diwans')
        .select('id, title, description, cover_url, is_live, listener_count')
        .eq('id', diwanId)
        .maybeSingle();
    if (data == null) return SeoMetadata.defaultMeta();
    return SeoMetadata.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Build the Edge Function URL for external crawlers / share previews
  // -------------------------------------------------------------------------

  String buildSharePreviewUrl(String diwanId) {
    return '$_edgeFunctionsBaseUrl/generate-seo-metadata?diwan_id=$diwanId';
  }
}
