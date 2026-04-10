import 'package:bayan/core/models/app_icon_variant.dart';
import 'package:bayan/core/models/profile.dart';
import 'package:bayan/core/repositories/dynamic_icon_repository.dart';

/// Governs dynamic launcher icon switching for بيان's Elite (Sovereign) users.
///
/// ## Security model
/// Eligibility is **always** validated server-side via the
/// `check_icon_eligibility` Supabase RPC — never via local storage or
/// a cached flag.  This prevents a tampered client from promoting itself to
/// the Gold tier by flipping a Hive/SharedPreferences value.
///
/// ## OS limitations
/// * **iOS** — the system shows a brief confirmation dialog when the icon
///   changes.  This cannot be suppressed; the call awaits its dismissal.
/// * **Android** — icon switching via activity-aliases causes the launcher
///   to briefly show a "shortcut removed / added" toast.  This is an OS
///   behaviour and is handled gracefully.
class DynamicIconService {
  final DynamicIconRepository _repository;

  const DynamicIconService(this._repository);

  // -------------------------------------------------------------------------
  // Eligibility thresholds (single source of truth)
  // -------------------------------------------------------------------------

  static const int _minimumLevel = 50;

  // -------------------------------------------------------------------------
  // Pure eligibility helpers (no network, fully testable)
  // -------------------------------------------------------------------------

  /// Returns `true` if [profile] qualifies for the Gold icon without any
  /// network call.  Used for fast UI toggling and unit tests.
  static bool isProfileEligible(Profile profile) =>
      profile.isSovereign || profile.level >= _minimumLevel;

  // -------------------------------------------------------------------------
  // Backend-validated eligibility (tamper-proof)
  // -------------------------------------------------------------------------

  /// Delegates to [DynamicIconRepository.checkEligibility] for server-side
  /// validation.  Returns `false` on any network/DB error (fail-closed).
  Future<bool> isEligible(String userId) =>
      _repository.checkEligibility(userId);

  // -------------------------------------------------------------------------
  // Icon switching
  // -------------------------------------------------------------------------

  /// Switches to the Gold icon after performing a **server-side** eligibility
  /// check.  Returns [IconSwitchResult.notEligible] immediately if the user
  /// does not meet the criteria — no platform API is invoked.
  Future<IconSwitchResult> switchToGold(String userId) async {
    final supported = await _repository.isSupported();
    if (!supported) return IconSwitchResult.notSupported;

    final eligible = await isEligible(userId);
    if (!eligible) return IconSwitchResult.notEligible;

    try {
      await _repository.setVariant(AppIconVariant.gold);
      return IconSwitchResult.success;
    } catch (_) {
      return IconSwitchResult.error;
    }
  }

  /// Resets the launcher icon to the default بيان icon.
  /// Always allowed regardless of user tier.
  Future<IconSwitchResult> switchToDefault() async {
    final supported = await _repository.isSupported();
    if (!supported) return IconSwitchResult.notSupported;

    try {
      await _repository.setVariant(AppIconVariant.defaultIcon);
      return IconSwitchResult.success;
    } catch (_) {
      return IconSwitchResult.error;
    }
  }

  // -------------------------------------------------------------------------
  // App-start integrity check
  // -------------------------------------------------------------------------

  /// Called on every cold start.  If the active icon is Gold but the user is
  /// no longer eligible (e.g. subscription lapsed), silently restores the
  /// default — preventing a permanent Gold icon on a free account.
  Future<void> restoreCorrectIcon(String userId) async {
    try {
      final active = await _repository.getActiveVariant();
      if (!active.requiresElite) return; // default icon — nothing to do

      final eligible = await isEligible(userId);
      if (!eligible) {
        await _repository.setVariant(AppIconVariant.defaultIcon);
      }
    } catch (_) {
      // Never crash the app on icon integrity check failure
    }
  }

  /// Returns the currently active icon variant.
  Future<AppIconVariant> getActiveVariant() => _repository.getActiveVariant();
}
