/// The four sequential steps of the بيان Elite Onboarding flow.
enum OnboardingStep {
  /// User has seen the welcome / brand introduction screen.
  welcomeSeen,

  /// User has picked their Prestige Categories (interests).
  interestsSelected,

  /// User has recorded and stored their 5-second Acoustic Identity.
  voicePrintCreated,

  /// All steps completed — onboarding is fully done.
  completed;

  /// Human-readable Arabic label for each step.
  String get label => switch (this) {
    OnboardingStep.welcomeSeen => 'الترحيب',
    OnboardingStep.interestsSelected => 'اختيار الاهتمامات',
    OnboardingStep.voicePrintCreated => 'الهوية الصوتية',
    OnboardingStep.completed => 'اكتمل',
  };

  /// Position within the ordered sequence (0-based).
  int get stepIndex => OnboardingStep.values.indexOf(this);
}

/// Immutable snapshot of one user's onboarding state machine.
class OnboardingStatus {
  final bool welcomeSeen;
  final bool interestsSelected;
  final bool voicePrintCreated;
  final bool completed;
  final DateTime? completedAt;
  final List<String> selectedCategories;

  const OnboardingStatus({
    this.welcomeSeen = false,
    this.interestsSelected = false,
    this.voicePrintCreated = false,
    this.completed = false,
    this.completedAt,
    this.selectedCategories = const [],
  });

  factory OnboardingStatus.fresh() => const OnboardingStatus();

  // -------------------------------------------------------------------------
  // Serialisation
  // -------------------------------------------------------------------------

  factory OnboardingStatus.fromMap(Map<String, dynamic> map) {
    return OnboardingStatus(
      welcomeSeen: (map['welcome_seen'] as bool?) ?? false,
      interestsSelected: (map['interests_selected'] as bool?) ?? false,
      voicePrintCreated: (map['voice_print_created'] as bool?) ?? false,
      completed: (map['completed'] as bool?) ?? false,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      selectedCategories: _parseCategories(map['selected_categories']),
    );
  }

  static List<String> _parseCategories(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.cast<String>();
    return const [];
  }

  Map<String, dynamic> toMap() => {
    'welcome_seen': welcomeSeen,
    'interests_selected': interestsSelected,
    'voice_print_created': voicePrintCreated,
    'completed': completed,
    'completed_at': completedAt?.toIso8601String(),
    'selected_categories': selectedCategories,
  };

  // -------------------------------------------------------------------------
  // Business logic
  // -------------------------------------------------------------------------

  /// Returns the next step the user must complete, or `null` if fully done.
  OnboardingStep? get nextStep {
    if (!welcomeSeen) return OnboardingStep.welcomeSeen;
    if (!interestsSelected) return OnboardingStep.interestsSelected;
    if (!voicePrintCreated) return OnboardingStep.voicePrintCreated;
    if (!completed) return OnboardingStep.completed;
    return null;
  }

  /// True when the user should see the onboarding flow.
  bool get requiresOnboarding => !completed;

  /// Completion fraction 0.0 → 1.0 (excludes the terminal `completed` step).
  double get progress {
    int done = 0;
    if (welcomeSeen) done++;
    if (interestsSelected) done++;
    if (voicePrintCreated) done++;
    return done / 3.0;
  }

  OnboardingStatus copyWith({
    bool? welcomeSeen,
    bool? interestsSelected,
    bool? voicePrintCreated,
    bool? completed,
    DateTime? completedAt,
    List<String>? selectedCategories,
  }) {
    return OnboardingStatus(
      welcomeSeen: welcomeSeen ?? this.welcomeSeen,
      interestsSelected: interestsSelected ?? this.interestsSelected,
      voicePrintCreated: voicePrintCreated ?? this.voicePrintCreated,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStatus &&
          welcomeSeen == other.welcomeSeen &&
          interestsSelected == other.interestsSelected &&
          voicePrintCreated == other.voicePrintCreated &&
          completed == other.completed;

  @override
  int get hashCode =>
      Object.hash(welcomeSeen, interestsSelected, voicePrintCreated, completed);
}
