import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/question.dart';
import 'package:bayan/core/models/speaker_queue_entry.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class QuestionState {
  final List<Question> questions;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const QuestionState({
    this.questions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  QuestionState copyWith({
    List<Question>? questions,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) => QuestionState(
    questions: questions ?? this.questions,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : (error ?? this.error),
  );
}

// -------------------------------------------------------------------------
// Notifier (per-diwan)
// -------------------------------------------------------------------------
class QuestionNotifier
    extends AutoDisposeFamilyNotifier<QuestionState, String> {
  StreamSubscription<List<Question>>? _sub;

  @override
  QuestionState build(String diwanId) {
    ref.onDispose(() {
      _sub?.cancel();
    });
    _sub = ref.read(questionRepositoryProvider).watchQuestions(diwanId).listen((
      qs,
    ) {
      state = state.copyWith(questions: qs);
    });
    return const QuestionState();
  }

  Future<void> submitQuestion(String text) async {
    final userId = ref.read(userProvider).user?.id;
    if (userId == null) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref
          .read(questionRepositoryProvider)
          .submitQuestion(diwanId: arg, userId: userId, text: text);
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: 'تعذّر إرسال السؤال');
    }
  }

  Future<void> upvote(String questionId) async {
    await ref.read(questionRepositoryProvider).upvote(questionId);
  }

  Future<void> markAnswered(String questionId) async {
    await ref.read(questionRepositoryProvider).markAnswered(questionId);
  }

  Future<void> hideQuestion(String questionId) async {
    await ref.read(questionRepositoryProvider).hideQuestion(questionId);
  }
}

final questionProvider = NotifierProvider.autoDispose
    .family<QuestionNotifier, QuestionState, String>(QuestionNotifier.new);

// -------------------------------------------------------------------------
// Speaker Queue Provider (per-diwan, periodically refreshed)
// -------------------------------------------------------------------------
final speakerQueueProvider = FutureProvider.autoDispose
    .family<List<SpeakerQueueEntry>, String>((ref, diwanId) {
      return ref.read(questionRepositoryProvider).getSpeakerQueue(diwanId);
    });
