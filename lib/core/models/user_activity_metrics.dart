import 'dart:math' as math;

// Level = 1 + floor(sqrt(xp / 100))   — matches the SQL xp_to_level function
int levelFromXp(int xp) => 1 + math.sqrt(math.max(xp, 0) / 100.0).floor();

// XP threshold to reach level N  =  (N-1)^2 * 100
int xpForLevel(int level) {
  final n = math.max(level - 1, 0);
  return n * n * 100;
}

/// Named tiers that map a level number to a display label.
enum UserLevel {
  listener(1, 'مستمع'),
  conversationalist(2, 'محاور'),
  orator(3, 'خطيب'),
  thinker(4, 'مفكّر'),
  sage(5, 'حكيم'),
  masterOfDiwan(6, 'سيّد الديوان');

  const UserLevel(this.minLevel, this.label);
  final int minLevel;
  final String label;

  static UserLevel fromLevel(int level) {
    for (final v in UserLevel.values.reversed) {
      if (level >= v.minLevel) return v;
    }
    return UserLevel.listener;
  }
}

class UserActivityMetrics {
  final String userId;
  final int dailyStreak;
  final int longestStreak;
  final int totalMinutesListened;
  final int engagementXp;
  final int currentLevel;
  final DateTime? lastCheckinDate;
  final int prestigeTokens;
  final DateTime updatedAt;

  const UserActivityMetrics({
    required this.userId,
    this.dailyStreak = 0,
    this.longestStreak = 0,
    this.totalMinutesListened = 0,
    this.engagementXp = 0,
    this.currentLevel = 1,
    this.lastCheckinDate,
    this.prestigeTokens = 0,
    required this.updatedAt,
  });

  factory UserActivityMetrics.fromMap(Map<String, dynamic> map) {
    return UserActivityMetrics(
      userId: map['user_id'] as String,
      dailyStreak: (map['daily_streak'] as int?) ?? 0,
      longestStreak: (map['longest_streak'] as int?) ?? 0,
      totalMinutesListened: (map['total_minutes_listened'] as int?) ?? 0,
      engagementXp: (map['engagement_xp'] as int?) ?? 0,
      currentLevel: (map['current_level'] as int?) ?? 1,
      lastCheckinDate: map['last_checkin_date'] == null
          ? null
          : DateTime.parse(map['last_checkin_date'] as String),
      prestigeTokens: (map['prestige_tokens'] as int?) ?? 0,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // -------------------------------------------------------------------------
  // Computed properties
  // -------------------------------------------------------------------------

  UserLevel get userLevel => UserLevel.fromLevel(currentLevel);

  /// XP earned within the current level (numerator for progress bar).
  int get xpWithinLevel => engagementXp - xpForLevel(currentLevel);

  /// Total XP span of the current level (denominator for progress bar).
  int get xpRangeForLevel =>
      xpForLevel(currentLevel + 1) - xpForLevel(currentLevel);

  /// 0.0 – 1.0 progress toward next level.
  double get levelProgress {
    final range = xpRangeForLevel;
    if (range <= 0) return 1.0;
    return (xpWithinLevel / range).clamp(0.0, 1.0);
  }

  /// XP still needed to reach the next level.
  int get xpToNextLevel => xpForLevel(currentLevel + 1) - engagementXp;

  bool get hasCheckedInToday {
    if (lastCheckinDate == null) return false;
    final now = DateTime.now();
    return lastCheckinDate!.year == now.year &&
        lastCheckinDate!.month == now.month &&
        lastCheckinDate!.day == now.day;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserActivityMetrics &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'UserActivityMetrics(userId: $userId, level: $currentLevel, xp: $engagementXp, streak: $dailyStreak)';
}

/// Result returned by the daily_checkin RPC.
class CheckinResult {
  final bool alreadyCheckedIn;
  final int xpAwarded;
  final int newStreak;
  final bool leveledUp;
  final int newLevel;
  final int prestigeTokensAwarded;

  const CheckinResult({
    required this.alreadyCheckedIn,
    required this.xpAwarded,
    required this.newStreak,
    required this.leveledUp,
    required this.newLevel,
    required this.prestigeTokensAwarded,
  });

  factory CheckinResult.fromMap(Map<String, dynamic> map) {
    return CheckinResult(
      alreadyCheckedIn: (map['already_checked_in'] as bool?) ?? false,
      xpAwarded: (map['xp'] as int?) ?? 0,
      newStreak: (map['streak'] as int?) ?? 1,
      leveledUp: (map['leveled_up'] as bool?) ?? false,
      newLevel: (map['new_level'] as int?) ?? 1,
      prestigeTokensAwarded: (map['prestige_tokens'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinResult &&
          runtimeType == other.runtimeType &&
          alreadyCheckedIn == other.alreadyCheckedIn &&
          xpAwarded == other.xpAwarded &&
          newStreak == other.newStreak &&
          leveledUp == other.leveledUp &&
          newLevel == other.newLevel &&
          prestigeTokensAwarded == other.prestigeTokensAwarded;

  @override
  int get hashCode => Object.hash(
    alreadyCheckedIn,
    xpAwarded,
    newStreak,
    leveledUp,
    newLevel,
    prestigeTokensAwarded,
  );
}
