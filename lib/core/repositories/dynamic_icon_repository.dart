import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/app_icon_variant.dart';

/// Platform + data wrapper for dynamic icon operations.
///
/// Centralises all [FlutterDynamicIcon] plugin calls AND the Supabase
/// `check_icon_eligibility` RPC in one injectable class, keeping the
/// service layer fully testable without invoking native channels or real
/// network requests.
class DynamicIconRepository {
  final SupabaseClient _client;

  const DynamicIconRepository(this._client);

  // -------------------------------------------------------------------------
  // Platform capabilities
  // -------------------------------------------------------------------------

  /// Returns `true` if the current platform supports dynamic icon switching.
  Future<bool> isSupported() async {
    try {
      return await FlutterDynamicIcon.supportsAlternateIcons;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Eligibility
  // -------------------------------------------------------------------------

  /// Calls the `check_icon_eligibility` Supabase RPC.
  /// Returns `false` on any error (fail-closed, tamper-proof).
  Future<bool> checkEligibility(String userId) async {
    try {
      final result = await _client.rpc(
        'check_icon_eligibility',
        params: {'p_user_id': userId},
      );
      return (result as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Read
  // -------------------------------------------------------------------------

  /// Returns the currently active icon variant.
  /// Falls back to [AppIconVariant.defaultIcon] on any error.
  Future<AppIconVariant> getActiveVariant() async {
    try {
      final name = await FlutterDynamicIcon.getAlternateIconName();
      if (name == AppIconVariant.gold.iosIconName) return AppIconVariant.gold;
      return AppIconVariant.defaultIcon;
    } catch (_) {
      return AppIconVariant.defaultIcon;
    }
  }

  // -------------------------------------------------------------------------
  // Write
  // -------------------------------------------------------------------------

  /// Attempts to switch to [variant].
  ///
  /// On iOS the system displays a brief confirmation dialog — this is an OS
  /// limitation and cannot be suppressed.  The call awaits its dismissal.
  ///
  /// Throws a [DynamicIconException] if the platform reports an error.
  Future<void> setVariant(AppIconVariant variant) async {
    await FlutterDynamicIcon.setAlternateIconName(variant.iosIconName);
  }
}

/// Thrown when [DynamicIconRepository.setVariant] fails at the platform level.
class DynamicIconException implements Exception {
  final String message;
  const DynamicIconException(this.message);

  @override
  String toString() => 'DynamicIconException: $message';
}
