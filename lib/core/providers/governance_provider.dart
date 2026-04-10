import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/governance_vote.dart';
import 'package:bayan/core/models/proposal.dart';
import 'package:bayan/core/models/trust_score.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// Proposals stream
// -------------------------------------------------------------------------
final proposalsStreamProvider = StreamProvider.autoDispose<List<Proposal>>((
  ref,
) {
  return ref.read(governanceRepositoryProvider).watchProposals();
});

// -------------------------------------------------------------------------
// Single proposal fetch
// -------------------------------------------------------------------------
final proposalProvider = FutureProvider.autoDispose.family<Proposal?, String>((
  ref,
  id,
) {
  return ref.read(governanceRepositoryProvider).fetchProposal(id);
});

// -------------------------------------------------------------------------
// My vote on a proposal
// -------------------------------------------------------------------------
final myVoteProvider = FutureProvider.autoDispose
    .family<GovernanceVote?, String>((ref, proposalId) {
      return ref.read(governanceRepositoryProvider).fetchMyVote(proposalId);
    });

// -------------------------------------------------------------------------
// Trust Score
// -------------------------------------------------------------------------
final trustScoreProvider = FutureProvider.autoDispose
    .family<TrustScore, String>((ref, userId) {
      return ref.read(reputationServiceProvider).getTrustScore(userId);
    });

final myTrustScoreProvider = FutureProvider.autoDispose<TrustScore?>((ref) {
  return ref.read(reputationServiceProvider).getMyTrustScore();
});

// -------------------------------------------------------------------------
// Create proposal state
// -------------------------------------------------------------------------
class CreateProposalState {
  final bool isLoading;
  final Proposal? created;
  final String? error;

  const CreateProposalState({this.isLoading = false, this.created, this.error});

  CreateProposalState copyWith({
    bool? isLoading,
    Proposal? created,
    String? error,
    bool clearError = false,
  }) => CreateProposalState(
    isLoading: isLoading ?? this.isLoading,
    created: created ?? this.created,
    error: clearError ? null : (error ?? this.error),
  );
}

class CreateProposalNotifier extends AutoDisposeNotifier<CreateProposalState> {
  @override
  CreateProposalState build() => const CreateProposalState();

  Future<void> create({
    required String title,
    required String body,
    ProposalType type = ProposalType.feature,
    DateTime? votingEndsAt,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final proposal = await ref
          .read(governanceRepositoryProvider)
          .createProposal(
            title: title,
            body: body,
            type: type,
            votingEndsAt: votingEndsAt,
          );
      state = state.copyWith(isLoading: false, created: proposal);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر إنشاء المقترح');
    }
  }
}

final createProposalProvider =
    NotifierProvider.autoDispose<CreateProposalNotifier, CreateProposalState>(
      CreateProposalNotifier.new,
    );

// -------------------------------------------------------------------------
// Vote state
// -------------------------------------------------------------------------
class VoteState {
  final bool isLoading;
  final bool? success;
  final String? error;

  const VoteState({this.isLoading = false, this.success, this.error});

  VoteState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
    bool clearError = false,
  }) => VoteState(
    isLoading: isLoading ?? this.isLoading,
    success: success ?? this.success,
    error: clearError ? null : (error ?? this.error),
  );
}

class VoteNotifier extends AutoDisposeNotifier<VoteState> {
  @override
  VoteState build() => const VoteState();

  Future<void> vote(String proposalId, VoteChoice choice) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(governanceRepositoryProvider)
          .castVote(proposalId, choice);
      final ok = (result['success'] as bool?) ?? false;
      final errCode = result['error'] as String?;
      state = state.copyWith(
        isLoading: false,
        success: ok,
        error: ok ? null : _localizeError(errCode),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تسجيل التصويت');
    }
  }

  String _localizeError(String? code) {
    switch (code) {
      case 'already_voted':
        return 'لقد صوّتت مسبقاً';
      case 'voting_not_open':
        return 'التصويت غير مفتوح';
      case 'sovereign_required':
        return 'يتطلب عضوية نادي السيادة';
      default:
        return 'تعذّر تسجيل التصويت';
    }
  }
}

final voteProvider = NotifierProvider.autoDispose<VoteNotifier, VoteState>(
  VoteNotifier.new,
);
