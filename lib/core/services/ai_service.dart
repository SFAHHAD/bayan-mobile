import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/diwan_summary.dart';

/// Communicates with the `generate-diwan-summary` Supabase Edge Function.
/// The OpenAI API key is stored as a Supabase secret — never in the client.
class AIService {
  final SupabaseClient _client;

  const AIService(this._client);

  static const _summaryTable = 'diwan_summaries';

  // -------------------------------------------------------------------------
  // Summary generation
  // -------------------------------------------------------------------------

  /// Triggers the `generate-diwan-summary` Edge Function for [diwanId].
  /// Returns the generated summary text on success.
  Future<String> generateSummary(String diwanId) async {
    final result = await _client.functions.invoke(
      'generate-diwan-summary',
      body: {'diwan_id': diwanId},
    );

    if (result.status != 200) {
      final msg =
          (result.data as Map<String, dynamic>?)?['error'] as String? ??
          'تعذّر إنشاء الملخص';
      throw Exception(msg);
    }

    return (result.data as Map<String, dynamic>?)?['summary'] as String? ?? '';
  }

  // -------------------------------------------------------------------------
  // Summary retrieval
  // -------------------------------------------------------------------------

  /// Fetches the stored summary for [diwanId], or null if none exists.
  Future<DiwanSummary?> getSummary(String diwanId) async {
    final data = await _client
        .from(_summaryTable)
        .select()
        .eq('diwan_id', diwanId)
        .maybeSingle();
    if (data == null) return null;
    return DiwanSummary.fromMap(data);
  }

  /// Real-time stream of the summary status for [diwanId].
  /// The UI can watch this to show a progress indicator while the Edge
  /// Function processes the clips.
  Stream<DiwanSummary?> watchSummary(String diwanId) {
    return _client
        .from(_summaryTable)
        .stream(primaryKey: ['id'])
        .eq('diwan_id', diwanId)
        .map((rows) => rows.isEmpty ? null : DiwanSummary.fromMap(rows.first));
  }

  // -------------------------------------------------------------------------
  // Batch utilities
  // -------------------------------------------------------------------------

  /// Returns all summaries with [SummaryStatus.pending] so a background
  /// runner can kick off generation (e.g. called from an app startup hook).
  Future<List<DiwanSummary>> getPendingSummaries() async {
    final data = await _client
        .from(_summaryTable)
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (data as List)
        .map((r) => DiwanSummary.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
