/// Describes the available launcher icon variants for بيان.
enum AppIconVariant {
  /// The standard dark-themed launcher icon (always available).
  defaultIcon,

  /// The 24-karat Gold launcher icon — Sovereign Elite members only.
  gold;

  /// The iOS `CFBundleAlternateIcons` key for this variant.
  /// `null` means "reset to the primary icon" (the default).
  String? get iosIconName => switch (this) {
    AppIconVariant.defaultIcon => null,
    AppIconVariant.gold => 'BayanGold',
  };

  /// The Android activity-alias component name for this variant.
  /// Must match the `android:name` attribute in AndroidManifest.xml.
  String get androidActivityAlias => switch (this) {
    AppIconVariant.defaultIcon => 'MainActivityDefaultIcon',
    AppIconVariant.gold => 'MainActivityGoldIcon',
  };

  /// Human-readable label shown in settings UI.
  String get displayLabel => switch (this) {
    AppIconVariant.defaultIcon => 'الأيقونة الافتراضية',
    AppIconVariant.gold => 'أيقونة الذهب الملكية',
  };

  /// Whether this variant requires the Gold / Sovereign tier.
  bool get requiresElite => this == AppIconVariant.gold;
}

/// The result of an icon-switch attempt.
enum IconSwitchResult {
  /// Icon switched successfully.
  success,

  /// User does not meet the Sovereign / Elite criteria.
  notEligible,

  /// Platform does not support dynamic icons (e.g. Android < 8 or desktop).
  notSupported,

  /// An unexpected platform error occurred.
  error,
}
