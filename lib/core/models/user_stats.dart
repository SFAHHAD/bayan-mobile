class UserStats {
  final String userId;
  final int totalLiveMinutes;
  final double totalHoursHosted;
  final int totalDiwansHosted;
  final int peakListenersEver;
  final int followerCount;
  final int voiceCount;
  final int influenceScore;

  const UserStats({
    required this.userId,
    required this.totalLiveMinutes,
    required this.totalHoursHosted,
    required this.totalDiwansHosted,
    required this.peakListenersEver,
    required this.followerCount,
    required this.voiceCount,
    required this.influenceScore,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      userId: map['user_id'] as String,
      totalLiveMinutes: (map['total_live_minutes'] as int?) ?? 0,
      totalHoursHosted:
          double.tryParse(map['total_hours_hosted']?.toString() ?? '0') ?? 0.0,
      totalDiwansHosted: (map['total_diwans_hosted'] as int?) ?? 0,
      peakListenersEver: (map['peak_listeners_ever'] as int?) ?? 0,
      followerCount: (map['follower_count'] as int?) ?? 0,
      voiceCount: (map['voice_count'] as int?) ?? 0,
      influenceScore: (map['influence_score'] as int?) ?? 0,
    );
  }

  UserStats copyWith({
    int? totalLiveMinutes,
    double? totalHoursHosted,
    int? totalDiwansHosted,
    int? peakListenersEver,
    int? followerCount,
    int? voiceCount,
    int? influenceScore,
  }) {
    return UserStats(
      userId: userId,
      totalLiveMinutes: totalLiveMinutes ?? this.totalLiveMinutes,
      totalHoursHosted: totalHoursHosted ?? this.totalHoursHosted,
      totalDiwansHosted: totalDiwansHosted ?? this.totalDiwansHosted,
      peakListenersEver: peakListenersEver ?? this.peakListenersEver,
      followerCount: followerCount ?? this.followerCount,
      voiceCount: voiceCount ?? this.voiceCount,
      influenceScore: influenceScore ?? this.influenceScore,
    );
  }

  /// Returns a zero-valued stats object for [userId].
  factory UserStats.empty(String userId) => UserStats(
    userId: userId,
    totalLiveMinutes: 0,
    totalHoursHosted: 0,
    totalDiwansHosted: 0,
    peakListenersEver: 0,
    followerCount: 0,
    voiceCount: 0,
    influenceScore: 0,
  );
}
