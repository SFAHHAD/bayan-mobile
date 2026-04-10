/// The curated set of Elite Prestige Categories for بيان.
///
/// These map 1-to-1 with the `category` column in `user_interests` and the
/// `warm_feed_with_interests` RPC.  They are ordered from most broadly appealing
/// to most specialised to guide the onboarding UX.
enum PrestigeCategory {
  politics,
  economy,
  culture,
  technology,
  science,
  arts,
  philosophy,
  history,
  literature,
  business,
  sports,
  religion;

  // -------------------------------------------------------------------------
  // Display
  // -------------------------------------------------------------------------

  /// Arabic label shown in the onboarding interest picker.
  String get arabicLabel => switch (this) {
    PrestigeCategory.politics => 'السياسة',
    PrestigeCategory.economy => 'الاقتصاد',
    PrestigeCategory.culture => 'الثقافة',
    PrestigeCategory.technology => 'التقنية',
    PrestigeCategory.science => 'العلوم',
    PrestigeCategory.arts => 'الفن',
    PrestigeCategory.philosophy => 'الفلسفة',
    PrestigeCategory.history => 'التاريخ',
    PrestigeCategory.literature => 'الأدب',
    PrestigeCategory.business => 'الأعمال',
    PrestigeCategory.sports => 'الرياضة',
    PrestigeCategory.religion => 'الدين',
  };

  /// The canonical string stored in the database `user_interests.category`.
  String get key => switch (this) {
    PrestigeCategory.politics => 'السياسة',
    PrestigeCategory.economy => 'الاقتصاد',
    PrestigeCategory.culture => 'الثقافة',
    PrestigeCategory.technology => 'التقنية',
    PrestigeCategory.science => 'العلوم',
    PrestigeCategory.arts => 'الفن',
    PrestigeCategory.philosophy => 'الفلسفة',
    PrestigeCategory.history => 'التاريخ',
    PrestigeCategory.literature => 'الأدب',
    PrestigeCategory.business => 'الأعمال',
    PrestigeCategory.sports => 'الرياضة',
    PrestigeCategory.religion => 'الدين',
  };

  // -------------------------------------------------------------------------
  // Parsing
  // -------------------------------------------------------------------------

  /// Parses a stored category key back to a [PrestigeCategory].
  /// Returns `null` if the key is unrecognised.
  static PrestigeCategory? fromKey(String key) {
    for (final c in PrestigeCategory.values) {
      if (c.key == key) return c;
    }
    return null;
  }

  /// Converts a list of raw category keys to [PrestigeCategory] values,
  /// silently dropping unrecognised entries.
  static List<PrestigeCategory> fromKeys(List<String> keys) =>
      keys.map(fromKey).whereType<PrestigeCategory>().toList();

  // -------------------------------------------------------------------------
  // Minimum selection requirement
  // -------------------------------------------------------------------------

  /// Minimum number of categories a user must pick during onboarding.
  static const int minimumSelection = 3;

  /// Validates that [selected] meets the minimum selection requirement.
  static bool isValidSelection(List<PrestigeCategory> selected) =>
      selected.length >= minimumSelection;
}
