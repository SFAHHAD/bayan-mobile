import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/semantic_result.dart';

enum SemanticSearchType { diwan, voice }

class SemanticSearchRepository {
  final SupabaseClient _client;

  const SemanticSearchRepository(this._client);

  // -------------------------------------------------------------------------
  // Semantic search via Edge Function
  // -------------------------------------------------------------------------

  /// Searches for [type] content by semantic meaning of [query].
  ///
  /// Calls the `semantic-search` Edge Function which generates an embedding
  /// via OpenAI and calls the `match_diwans` / `match_voices` RPC.
  Future<List<SemanticResult>> search(
    String query, {
    double threshold = 0.70,
    int limit = 10,
    SemanticSearchType type = SemanticSearchType.diwan,
  }) async {
    if (query.trim().isEmpty) return [];
    final response = await _client.functions.invoke(
      'semantic-search',
      body: {
        'query': query.trim(),
        'limit': limit,
        'threshold': threshold,
        'type': type == SemanticSearchType.voice ? 'voice' : 'diwan',
      },
    );
    final data = response.data;
    if (data == null) return [];
    final results = data['results'];
    if (results == null) return [];
    return (results as List)
        .map((r) => SemanticResult.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Embedding generation (host action)
  // -------------------------------------------------------------------------

  /// Triggers the `generate-embeddings` Edge Function to embed a diwan or
  /// voice clip's text content and store it in the DB.
  Future<bool> generateEmbedding({
    required String id,
    SemanticSearchType type = SemanticSearchType.diwan,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-embeddings',
        body: {
          'id': id,
          'type': type == SemanticSearchType.voice ? 'voice' : 'diwan',
        },
      );
      final data = response.data;
      return (data?['success'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Direct RPC (when embedding vector is already available client-side)
  // -------------------------------------------------------------------------

  Future<List<SemanticResult>> matchByVector(
    List<double> embedding, {
    double threshold = 0.70,
    int limit = 10,
  }) async {
    final vectorStr = '[${embedding.join(',')}]';
    final data = await _client.rpc(
      'match_diwans',
      params: {
        'query_embedding': vectorStr,
        'match_threshold': threshold,
        'match_count': limit,
      },
    );
    if (data == null) return [];
    return (data as List)
        .map((r) => SemanticResult.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
