import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/poll.dart';
import 'package:bayan/core/models/poll_option.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class PollState {
  final Poll? activePoll;
  final List<PollOption> liveOptions;
  final bool hasVoted;
  final bool isLoading;
  final String? error;

  const PollState({
    this.activePoll,
    this.liveOptions = const [],
    this.hasVoted = false,
    this.isLoading = false,
    this.error,
  });

  PollState copyWith({
    Poll? activePoll,
    List<PollOption>? liveOptions,
    bool? hasVoted,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearPoll = false,
  }) => PollState(
    activePoll: clearPoll ? null : (activePoll ?? this.activePoll),
    liveOptions: liveOptions ?? this.liveOptions,
    hasVoted: hasVoted ?? this.hasVoted,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

// -------------------------------------------------------------------------
// Notifier (per-diwan)
// -------------------------------------------------------------------------
class PollNotifier extends AutoDisposeFamilyNotifier<PollState, String> {
  StreamSubscription<Poll?>? _pollSub;
  StreamSubscription<List<PollOption>>? _optionSub;

  @override
  PollState build(String diwanId) {
    ref.onDispose(() {
      _pollSub?.cancel();
      _optionSub?.cancel();
    });
    _watchActivePoll(diwanId);
    return const PollState();
  }

  void _watchActivePoll(String diwanId) {
    _pollSub = ref.read(pollRepositoryProvider).watchActivePoll(diwanId).listen(
      (poll) {
        if (poll == null) {
          state = state.copyWith(clearPoll: true, liveOptions: []);
          _optionSub?.cancel();
          return;
        }
        state = state.copyWith(activePoll: poll);
        _watchOptions(poll.id);
      },
    );
  }

  void _watchOptions(String pollId) {
    _optionSub?.cancel();
    _optionSub = ref
        .read(pollRepositoryProvider)
        .watchPollOptions(pollId)
        .listen((opts) {
          state = state.copyWith(liveOptions: opts);
        });
  }

  Future<void> vote(String optionId) async {
    final poll = state.activePoll;
    if (poll == null || state.hasVoted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final success = await ref
        .read(pollRepositoryProvider)
        .vote(pollId: poll.id, optionId: optionId);
    state = state.copyWith(
      isLoading: false,
      hasVoted: success,
      error: success ? null : 'لقد صوّتت مسبقاً',
    );
  }

  // Host-only controls
  Future<void> startPoll(String pollId) async {
    await ref.read(pollRepositoryProvider).startPoll(pollId);
  }

  Future<void> endPoll(String pollId) async {
    await ref.read(pollRepositoryProvider).endPoll(pollId);
  }

  Future<Poll?> createPoll({
    required String question,
    required List<String> options,
  }) async {
    final userId = ref.read(userProvider).user?.id;
    if (userId == null) return null;
    return ref
        .read(pollRepositoryProvider)
        .createPoll(
          diwanId: arg,
          hostId: userId,
          question: question,
          optionTexts: options,
        );
  }
}

final pollProvider = NotifierProvider.autoDispose
    .family<PollNotifier, PollState, String>(PollNotifier.new);

/// One-shot fetch of a poll (results screen).
final pollResultsProvider = FutureProvider.autoDispose.family<Poll?, String>((
  ref,
  pollId,
) {
  return ref.read(pollRepositoryProvider).getPoll(pollId);
});

/// All polls for a diwan (history).
final diwanPollsProvider = FutureProvider.autoDispose
    .family<List<Poll>, String>((ref, diwanId) {
      return ref.read(pollRepositoryProvider).getDiwanPolls(diwanId);
    });
