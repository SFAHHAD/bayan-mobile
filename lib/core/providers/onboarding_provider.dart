import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/feed_item.dart';
import 'package:bayan/core/models/onboarding_status.dart';
import 'package:bayan/core/models/prestige_category.dart';
import 'package:bayan/core/models/voice_print.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/repositories/onboarding_repository.dart';
import 'package:bayan/core/services/feed_warmup_service.dart';
import 'package:bayan/core/services/voice_print_service.dart';

// ---------------------------------------------------------------------------
// Onboarding state machine
// ---------------------------------------------------------------------------

/// Notifier that drives the Elite Onboarding state machine.
class OnboardingNotifier extends AsyncNotifier<OnboardingStatus> {
  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);
  FeedWarmupService get _warmup => ref.read(feedWarmupServiceProvider);
  VoicePrintService get _voicePrint => ref.read(voicePrintServiceProvider);

  @override
  Future<OnboardingStatus> build() => _repo.getStatus();

  // -------------------------------------------------------------------------

  /// Marks the welcome screen as seen.
  Future<void> completeWelcome() async {
    final updated = await _repo.markWelcomeSeen();
    state = AsyncData(updated);
  }

  /// Saves the user's Prestige Category selections and warms the feed.
  /// Returns the pre-warmed first page of the personalised feed.
  Future<List<FeedItem>> completeInterests(
    List<PrestigeCategory> categories,
  ) async {
    final updated = await _repo.markInterestsSelected(categories);
    state = AsyncData(updated);
    return _warmup.warmWithCategories(categories);
  }

  /// Encrypts and stores [audioBytes] as the user's Acoustic Identity,
  /// then marks the voice print step done.
  Future<VoicePrint> completeVoicePrint({
    required String userId,
    required Uint8List audioBytes,
    int durationSeconds = VoicePrintService.targetDurationSeconds,
  }) async {
    final print = await _voicePrint.createVoicePrint(
      userId: userId,
      audioBytes: audioBytes,
      durationSeconds: durationSeconds,
    );
    final updated = await _repo.markVoicePrintCreated();
    state = AsyncData(updated);
    return print;
  }

  /// Finalises the entire onboarding flow.
  Future<void> complete() async {
    final updated = await _repo.markCompleted();
    state = AsyncData(updated);
  }

  /// Convenience: skip voice print and go straight to completion.
  Future<void> skipVoicePrint() async {
    final updated = await _repo.markVoicePrintCreated();
    state = AsyncData(updated);
  }
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingNotifier, OnboardingStatus>(
      OnboardingNotifier.new,
    );

// ---------------------------------------------------------------------------
// Derived convenience providers
// ---------------------------------------------------------------------------

/// `true` while the user still needs to go through onboarding.
final requiresOnboardingProvider = Provider<bool>((ref) {
  final status = ref.watch(onboardingProvider);
  return status.when(
    data: (s) => s.requiresOnboarding,
    loading: () => false,
    error: (e, _) => false,
  );
});

/// The next step the current user must complete, or `null` if done.
final nextOnboardingStepProvider = Provider<OnboardingStep?>((ref) {
  final status = ref.watch(onboardingProvider);
  return status.when(
    data: (s) => s.nextStep,
    loading: () => null,
    error: (e, _) => null,
  );
});

/// Completion fraction 0.0 → 1.0 for a progress indicator.
final onboardingProgressProvider = Provider<double>((ref) {
  final status = ref.watch(onboardingProvider);
  return status.when(
    data: (s) => s.progress,
    loading: () => 0.0,
    error: (e, _) => 0.0,
  );
});
