import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/report.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/repositories/moderation_repository.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class ModerationState {
  final List<String> blockedIds;
  final bool isLoading;
  final String? error;

  const ModerationState({
    this.blockedIds = const [],
    this.isLoading = false,
    this.error,
  });

  ModerationState copyWith({
    List<String>? blockedIds,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ModerationState(
      blockedIds: blockedIds ?? this.blockedIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool isBlocked(String userId) => blockedIds.contains(userId);
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class ModerationNotifier extends StateNotifier<ModerationState> {
  final Ref _ref;

  ModerationNotifier(this._ref) : super(const ModerationState()) {
    _loadBlocks();
  }

  String? get _myId => _ref.read(userProvider).user?.id;
  ModerationRepository get _repo => _ref.read(moderationRepositoryProvider);

  Future<void> _loadBlocks() async {
    final me = _myId;
    if (me == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final ids = await _repo.getBlockedIds(me);
      state = state.copyWith(blockedIds: ids, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> blockUser(String targetId) async {
    final me = _myId;
    if (me == null || me == targetId) return;
    await _repo.blockUser(me, targetId);
    state = state.copyWith(blockedIds: [...state.blockedIds, targetId]);
  }

  Future<void> unblockUser(String targetId) async {
    final me = _myId;
    if (me == null) return;
    await _repo.unblockUser(me, targetId);
    state = state.copyWith(
      blockedIds: state.blockedIds.where((id) => id != targetId).toList(),
    );
  }

  Future<void> reportContent({
    required ReportContentType contentType,
    required String contentId,
    required String reason,
    String? description,
  }) async {
    final me = _myId;
    if (me == null) return;
    await _repo.reportContent(
      reporterId: me,
      contentType: contentType,
      contentId: contentId,
      reason: reason,
      description: description,
    );
  }
}

// -------------------------------------------------------------------------
// Providers
// -------------------------------------------------------------------------
final moderationProvider =
    StateNotifierProvider<ModerationNotifier, ModerationState>(
      (ref) => ModerationNotifier(ref),
    );

/// Exposes whether a specific [userId] is blocked by the current user.
final isBlockedProvider = Provider.autoDispose.family<bool, String>((
  ref,
  userId,
) {
  return ref.watch(moderationProvider).isBlocked(userId);
});
