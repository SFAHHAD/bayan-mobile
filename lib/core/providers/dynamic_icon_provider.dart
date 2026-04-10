import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/app_icon_variant.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/repositories/dynamic_icon_repository.dart';
import 'package:bayan/core/services/dynamic_icon_service.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final dynamicIconRepositoryProvider = Provider<DynamicIconRepository>(
  (ref) => DynamicIconRepository(ref.read(supabaseClientProvider)),
);

final dynamicIconServiceProvider = Provider<DynamicIconService>(
  (ref) => DynamicIconService(ref.read(dynamicIconRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// State: currently active variant
// ---------------------------------------------------------------------------

/// Notifier that owns the active [AppIconVariant] and exposes the
/// switching actions to the UI.
class DynamicIconNotifier extends AsyncNotifier<AppIconVariant> {
  DynamicIconService get _service => ref.read(dynamicIconServiceProvider);

  @override
  Future<AppIconVariant> build() => _service.getActiveVariant();

  // -------------------------------------------------------------------------

  /// Switch to the Gold icon.  Returns the [IconSwitchResult] to allow the
  /// caller to show contextual feedback (e.g. a SnackBar for notEligible).
  Future<IconSwitchResult> switchToGold(String userId) async {
    final result = await _service.switchToGold(userId);
    if (result == IconSwitchResult.success) {
      state = const AsyncData(AppIconVariant.gold);
    }
    return result;
  }

  /// Reset to the default icon (always succeeds if supported).
  Future<IconSwitchResult> switchToDefault() async {
    final result = await _service.switchToDefault();
    if (result == IconSwitchResult.success) {
      state = const AsyncData(AppIconVariant.defaultIcon);
    }
    return result;
  }

  /// Run the app-start integrity check for [userId].
  Future<void> restoreCorrectIcon(String userId) async {
    await _service.restoreCorrectIcon(userId);
    state = AsyncData(await _service.getActiveVariant());
  }
}

final dynamicIconProvider =
    AsyncNotifierProvider<DynamicIconNotifier, AppIconVariant>(
      DynamicIconNotifier.new,
    );

// ---------------------------------------------------------------------------
// Convenience: is the current user eligible (profile-only, no network)?
// ---------------------------------------------------------------------------

/// `true` if the loaded profile qualifies for the Gold icon based on local
/// profile data.  A fast gate for showing/hiding the settings toggle.
final isEliteIconEligibleProvider = Provider<bool>((ref) {
  final session = ref.watch(userProvider);
  final profile = session.profile;
  if (profile == null) return false;
  return DynamicIconService.isProfileEligible(profile);
});
