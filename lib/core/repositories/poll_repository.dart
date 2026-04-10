import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/poll.dart';
import 'package:bayan/core/models/poll_option.dart';

class PollRepository {
  final SupabaseClient _client;

  const PollRepository(this._client);

  static const _pollTable = 'polls';
  static const _optionTable = 'poll_options';

  // -------------------------------------------------------------------------
  // Create
  // -------------------------------------------------------------------------

  /// Creates a poll in 'draft' status with the given [options].
  Future<Poll> createPoll({
    required String diwanId,
    required String hostId,
    required String question,
    required List<String> optionTexts,
  }) async {
    final pollResponse = await _client
        .from(_pollTable)
        .insert({
          'diwan_id': diwanId,
          'host_id': hostId,
          'question': question,
          'status': 'draft',
        })
        .select()
        .single();

    final pollId = pollResponse['id'] as String;

    final optionsPayload = optionTexts
        .map((t) => {'poll_id': pollId, 'text': t})
        .toList();

    final optionRows = await _client
        .from(_optionTable)
        .insert(optionsPayload)
        .select();

    final options = (optionRows as List)
        .map((r) => PollOption.fromMap(r as Map<String, dynamic>))
        .toList();

    return Poll.fromMap({
      ...pollResponse,
      'poll_options': optionRows,
    }).copyWith(options: options);
  }

  // -------------------------------------------------------------------------
  // Host controls (via RPCs)
  // -------------------------------------------------------------------------

  Future<void> startPoll(String pollId) async {
    await _client.rpc('start_poll', params: {'p_poll_id': pollId});
  }

  Future<void> endPoll(String pollId) async {
    await _client.rpc('end_poll', params: {'p_poll_id': pollId});
  }

  // -------------------------------------------------------------------------
  // Voting
  // -------------------------------------------------------------------------

  /// Casts a vote for [optionId] in [pollId].
  /// Returns `true` on success, `false` if the user already voted.
  Future<bool> vote({required String pollId, required String optionId}) async {
    final result =
        await _client.rpc(
              'vote_poll',
              params: {'p_poll_id': pollId, 'p_option_id': optionId},
            )
            as Map<String, dynamic>;
    return result['success'] == true;
  }

  // -------------------------------------------------------------------------
  // Queries
  // -------------------------------------------------------------------------

  /// Fetches the currently active poll for [diwanId], or null if none.
  Future<Poll?> getActivePoll(String diwanId) async {
    final data = await _client
        .from(_pollTable)
        .select('*, poll_options(*)')
        .eq('diwan_id', diwanId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return Poll.fromMap(data);
  }

  Future<Poll?> getPoll(String pollId) async {
    final data = await _client
        .from(_pollTable)
        .select('*, poll_options(*)')
        .eq('id', pollId)
        .maybeSingle();
    if (data == null) return null;
    return Poll.fromMap(data);
  }

  Future<List<Poll>> getDiwanPolls(String diwanId) async {
    final data = await _client
        .from(_pollTable)
        .select('*, poll_options(*)')
        .eq('diwan_id', diwanId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => Poll.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Real-time streams
  // -------------------------------------------------------------------------

  /// Streams live option vote counts for [pollId].
  /// Emits a new list whenever any option's `votes_count` changes.
  Stream<List<PollOption>> watchPollOptions(String pollId) {
    return _client
        .from(_optionTable)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (rows) => rows
              .where((r) => r['poll_id'] == pollId)
              .map(PollOption.fromMap)
              .toList(),
        );
  }

  /// Streams the active poll for [diwanId] (status + total_votes).
  Stream<Poll?> watchActivePoll(String diwanId) {
    return _client
        .from(_pollTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          final active = rows.firstWhere(
            (r) => r['diwan_id'] == diwanId && r['status'] == 'active',
            orElse: () => <String, dynamic>{},
          );
          if (active.isEmpty) return null;
          return Poll.fromMap(active);
        });
  }
}
