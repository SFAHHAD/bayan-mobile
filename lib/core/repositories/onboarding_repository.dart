import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/onboarding_status.dart';
import 'package:bayan/core/models/prestige_category.dart';

/// Offline-first persistence for the Elite Onboarding state machine.
///
/// ## Strategy
/// - **Hive** is the source of truth for reads (instant, no network).
/// - **Supabase** (`onboarding_status` table via `upsert_onboarding_status` RPC)
///   is updated asynchronously on every write so the state is portable across
///   devices / reinstalls.
/// - On first launch the Hive box is empty; the repository falls back to the
///   remote row (if any) before returning [OnboardingStatus.fresh].
class OnboardingRepository {
  final SupabaseClient _client;

  const OnboardingRepository(this._client);

  static const _boxName = 'onboarding_state';
  static const _key = 'status';

  // -------------------------------------------------------------------------
  // Read
  // -------------------------------------------------------------------------

  /// Returns the current onboarding status.
  ///
  /// 1. Returns the locally cached value if present.
  /// 2. Otherwise fetches from Supabase and caches it locally.
  /// 3. Falls back to [OnboardingStatus.fresh] on any error.
  Future<OnboardingStatus> getStatus() async {
    final local = _readLocal();
    if (local != null) return local;
    return _fetchRemoteAndCache();
  }

  /// Returns `true` if the onboarding flow has been completed.
  Future<bool> isCompleted() async {
    final status = await getStatus();
    return status.completed;
  }

  // -------------------------------------------------------------------------
  // Write — individual step completions
  // -------------------------------------------------------------------------

  /// Marks the welcome screen as seen.
  Future<OnboardingStatus> markWelcomeSeen() async {
    final current = await getStatus();
    final updated = current.copyWith(welcomeSeen: true);
    return _persist(updated, remoteParams: {'p_welcome_seen': true});
  }

  /// Records the user's chosen Prestige Categories and marks the step done.
  Future<OnboardingStatus> markInterestsSelected(
    List<PrestigeCategory> categories,
  ) async {
    assert(
      PrestigeCategory.isValidSelection(categories),
      'Must select at least ${PrestigeCategory.minimumSelection} categories',
    );
    final current = await getStatus();
    final keys = categories.map((c) => c.key).toList();
    final updated = current.copyWith(
      interestsSelected: true,
      selectedCategories: keys,
    );
    return _persist(
      updated,
      remoteParams: {
        'p_interests_selected': true,
        'p_selected_categories': keys,
      },
    );
  }

  /// Marks the voice print creation step as done.
  Future<OnboardingStatus> markVoicePrintCreated() async {
    final current = await getStatus();
    final updated = current.copyWith(voicePrintCreated: true);
    return _persist(updated, remoteParams: {'p_voice_print_created': true});
  }

  /// Marks the entire onboarding flow as completed.
  Future<OnboardingStatus> markCompleted() async {
    final current = await getStatus();
    final updated = current.copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );
    return _persist(updated, remoteParams: {'p_completed': true});
  }

  // -------------------------------------------------------------------------
  // Reset (testing / re-onboarding)
  // -------------------------------------------------------------------------

  /// Clears local state only.  The remote row is left untouched.
  Future<void> clearLocal() async {
    final box = await _openBox();
    await box.delete(_key);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  OnboardingStatus? _readLocal() {
    if (!Hive.isBoxOpen(_boxName)) return null;
    final raw = Hive.box(_boxName).get(_key) as String?;
    if (raw == null) return null;
    try {
      return OnboardingStatus.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<OnboardingStatus> _fetchRemoteAndCache() async {
    try {
      final raw = await _client.rpc('get_onboarding_status');
      if (raw == null) return OnboardingStatus.fresh();
      final list = raw as List;
      if (list.isEmpty) return OnboardingStatus.fresh();
      final status = OnboardingStatus.fromMap(
        Map<String, dynamic>.from(list.first as Map),
      );
      await _writeLocal(status);
      return status;
    } catch (_) {
      return OnboardingStatus.fresh();
    }
  }

  Future<OnboardingStatus> _persist(
    OnboardingStatus status, {
    required Map<String, dynamic> remoteParams,
  }) async {
    await _writeLocal(status);
    _syncRemote(remoteParams); // fire-and-forget
    return status;
  }

  Future<void> _writeLocal(OnboardingStatus status) async {
    final box = await _openBox();
    await box.put(_key, jsonEncode(status.toMap()));
  }

  void _syncRemote(Map<String, dynamic> params) {
    _client.rpc('upsert_onboarding_status', params: params).catchError((_) {
      /* silently ignore — local Hive is the source of truth */
    });
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }
}
