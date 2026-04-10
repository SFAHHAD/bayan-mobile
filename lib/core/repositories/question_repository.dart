import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/question.dart';
import 'package:bayan/core/models/speaker_queue_entry.dart';

class QuestionRepository {
  final SupabaseClient _client;

  const QuestionRepository(this._client);

  static const _table = 'questions';

  // -------------------------------------------------------------------------
  // Submit & manage
  // -------------------------------------------------------------------------

  Future<Question> submitQuestion({
    required String diwanId,
    required String userId,
    required String text,
  }) async {
    final response = await _client
        .from(_table)
        .insert({'diwan_id': diwanId, 'user_id': userId, 'text': text})
        .select()
        .single();
    return Question.fromMap(response);
  }

  /// Marks a question as answered (host action).
  Future<void> markAnswered(String questionId) async {
    await _client
        .from(_table)
        .update({'is_answered': true})
        .eq('id', questionId);
  }

  /// Hides an inappropriate question (host moderation).
  Future<void> hideQuestion(String questionId) async {
    await _client.from(_table).update({'is_hidden': true}).eq('id', questionId);
  }

  // -------------------------------------------------------------------------
  // Upvoting
  // -------------------------------------------------------------------------

  /// Upvotes [questionId] for the authenticated user.
  /// Returns `true` on success, `false` if already upvoted.
  Future<bool> upvote(String questionId) async {
    final result =
        await _client.rpc(
              'upvote_question',
              params: {'p_question_id': questionId},
            )
            as Map<String, dynamic>;
    return result['success'] == true;
  }

  // -------------------------------------------------------------------------
  // Queries
  // -------------------------------------------------------------------------

  Future<List<Question>> getQuestions(
    String diwanId, {
    bool includeAnswered = true,
  }) async {
    var query = _client
        .from(_table)
        .select()
        .eq('diwan_id', diwanId)
        .eq('is_hidden', false);

    if (!includeAnswered) {
      query = query.eq('is_answered', false);
    }

    final data = await query.order('upvotes_count', ascending: false);
    return (data as List)
        .map((r) => Question.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Speaker queue
  // -------------------------------------------------------------------------

  /// Returns the current speaker queue for [diwanId], ordered by prestige score.
  Future<List<SpeakerQueueEntry>> getSpeakerQueue(String diwanId) async {
    final data =
        await _client.rpc('get_speaker_queue', params: {'p_diwan_id': diwanId})
            as List;
    return data
        .map((r) => SpeakerQueueEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Real-time stream
  // -------------------------------------------------------------------------

  /// Streams questions for [diwanId], sorted by upvotes descending.
  Stream<List<Question>> watchQuestions(String diwanId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('upvotes_count', ascending: false)
        .map(
          (rows) => rows
              .where(
                (r) =>
                    r['diwan_id'] == diwanId &&
                    (r['is_hidden'] as bool? ?? false) == false,
              )
              .map(Question.fromMap)
              .toList(),
        );
  }
}
