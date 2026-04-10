import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/governance_vote.dart';
import 'package:bayan/core/models/proposal.dart';

class GovernanceRepository {
  final SupabaseClient _client;

  const GovernanceRepository(this._client);

  static const _proposals = 'proposals';
  static const _votes = 'governance_votes';

  // -------------------------------------------------------------------------
  // Proposals
  // -------------------------------------------------------------------------

  Future<List<Proposal>> fetchProposals({
    ProposalStatus? status,
    int limit = 50,
  }) async {
    final base = _client.from(_proposals).select();
    final data = await (status != null
        ? base
              .eq('status', Proposal.statusToString(status))
              .order('created_at', ascending: false)
              .limit(limit)
        : base.order('created_at', ascending: false).limit(limit));
    return (data as List)
        .map((r) => Proposal.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<Proposal?> fetchProposal(String id) async {
    final data = await _client
        .from(_proposals)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Proposal.fromMap(data);
  }

  Stream<List<Proposal>> watchProposals() {
    return _client
        .from(_proposals)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (rows) =>
              rows.map(Proposal.fromMap).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<Proposal> createProposal({
    required String title,
    required String body,
    ProposalType type = ProposalType.feature,
    DateTime? votingEndsAt,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from(_proposals)
        .insert({
          'creator_id': userId,
          'title': title,
          'body': body,
          'type': Proposal.typeToString(type),
          'voting_ends_at': votingEndsAt?.toIso8601String(),
        })
        .select()
        .single();
    return Proposal.fromMap(data);
  }

  Future<bool> withdrawProposal(String proposalId) async {
    await _client
        .from(_proposals)
        .update({'status': 'withdrawn'})
        .eq('id', proposalId)
        .eq('creator_id', _client.auth.currentUser!.id);
    return true;
  }

  // -------------------------------------------------------------------------
  // Voting
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> castVote(
    String proposalId,
    VoteChoice vote,
  ) async {
    final raw = await _client.rpc(
      'cast_vote',
      params: {
        'p_proposal_id': proposalId,
        'p_vote': GovernanceVote.voteToString(vote),
      },
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<GovernanceVote?> fetchMyVote(String proposalId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from(_votes)
        .select()
        .eq('proposal_id', proposalId)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return GovernanceVote.fromMap(data);
  }

  Future<List<GovernanceVote>> fetchVotes(String proposalId) async {
    final data = await _client
        .from(_votes)
        .select()
        .eq('proposal_id', proposalId)
        .order('created_at');
    return (data as List)
        .map((r) => GovernanceVote.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Admin / cron — finalize
  // -------------------------------------------------------------------------

  Future<String> finalizeProposal(String proposalId) async {
    final raw = await _client.rpc(
      'finalize_proposal',
      params: {'p_proposal_id': proposalId},
    );
    return (raw as String?) ?? 'error';
  }
}
