class DiwanReportSession {
  final int totalDurationSeconds;
  final String totalDurationFormatted;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const DiwanReportSession({
    required this.totalDurationSeconds,
    required this.totalDurationFormatted,
    this.startedAt,
    this.endedAt,
  });

  factory DiwanReportSession.fromMap(Map<String, dynamic> map) {
    return DiwanReportSession(
      totalDurationSeconds: (map['total_duration_seconds'] as int?) ?? 0,
      totalDurationFormatted:
          (map['total_duration_formatted'] as String?) ?? '0s',
      startedAt: map['started_at'] != null
          ? DateTime.tryParse(map['started_at'] as String)
          : null,
      endedAt: map['ended_at'] != null
          ? DateTime.tryParse(map['ended_at'] as String)
          : null,
    );
  }
}

class DiwanReportAudience {
  final int peakListeners;
  final int uniqueListeners;

  const DiwanReportAudience({
    required this.peakListeners,
    required this.uniqueListeners,
  });

  factory DiwanReportAudience.fromMap(Map<String, dynamic> map) {
    return DiwanReportAudience(
      peakListeners: (map['peak_listeners'] as int?) ?? 0,
      uniqueListeners: (map['unique_listeners'] as int?) ?? 0,
    );
  }
}

class DiwanReportEconomy {
  final int totalGiftsValue;
  final int ticketsSold;
  final int ticketRevenue;
  final int totalRevenue;

  const DiwanReportEconomy({
    required this.totalGiftsValue,
    required this.ticketsSold,
    required this.ticketRevenue,
    required this.totalRevenue,
  });

  factory DiwanReportEconomy.fromMap(Map<String, dynamic> map) {
    return DiwanReportEconomy(
      totalGiftsValue: (map['total_gifts_value'] as int?) ?? 0,
      ticketsSold: (map['tickets_sold'] as int?) ?? 0,
      ticketRevenue: (map['ticket_revenue'] as int?) ?? 0,
      totalRevenue: (map['total_revenue'] as int?) ?? 0,
    );
  }
}

class DiwanReportEngagement {
  final int totalPollVotes;
  final int pollsConducted;
  final int totalQuestions;
  final int questionsAnswered;

  const DiwanReportEngagement({
    required this.totalPollVotes,
    required this.pollsConducted,
    required this.totalQuestions,
    required this.questionsAnswered,
  });

  factory DiwanReportEngagement.fromMap(Map<String, dynamic> map) {
    return DiwanReportEngagement(
      totalPollVotes: (map['total_poll_votes'] as int?) ?? 0,
      pollsConducted: (map['polls_conducted'] as int?) ?? 0,
      totalQuestions: (map['total_questions'] as int?) ?? 0,
      questionsAnswered: (map['questions_answered'] as int?) ?? 0,
    );
  }
}

class DiwanReportAiInsights {
  final String summary;
  final List<String> keyPoints;

  const DiwanReportAiInsights({required this.summary, required this.keyPoints});

  factory DiwanReportAiInsights.fromMap(Map<String, dynamic> map) {
    final raw = map['key_points'];
    final List<String> kp;
    if (raw is List) {
      kp = raw.map((e) => e as String).toList();
    } else {
      kp = [];
    }
    return DiwanReportAiInsights(
      summary: (map['summary'] as String?) ?? '',
      keyPoints: kp,
    );
  }
}

/// Aggregated report returned by the generate-diwan-report Edge Function.
class DiwanReport {
  final String diwanId;
  final String title;
  final DateTime generatedAt;
  final DiwanReportSession session;
  final DiwanReportAudience audience;
  final DiwanReportEconomy economy;
  final DiwanReportEngagement engagement;
  final DiwanReportAiInsights aiInsights;

  const DiwanReport({
    required this.diwanId,
    required this.title,
    required this.generatedAt,
    required this.session,
    required this.audience,
    required this.economy,
    required this.engagement,
    required this.aiInsights,
  });

  factory DiwanReport.fromMap(Map<String, dynamic> map) {
    return DiwanReport(
      diwanId: map['diwan_id'] as String,
      title: map['title'] as String,
      generatedAt: DateTime.parse(map['generated_at'] as String),
      session: DiwanReportSession.fromMap(
        map['session'] as Map<String, dynamic>,
      ),
      audience: DiwanReportAudience.fromMap(
        map['audience'] as Map<String, dynamic>,
      ),
      economy: DiwanReportEconomy.fromMap(
        map['economy'] as Map<String, dynamic>,
      ),
      engagement: DiwanReportEngagement.fromMap(
        map['engagement'] as Map<String, dynamic>,
      ),
      aiInsights: DiwanReportAiInsights.fromMap(
        map['ai_insights'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiwanReport &&
          runtimeType == other.runtimeType &&
          diwanId == other.diwanId;

  @override
  int get hashCode => diwanId.hashCode;
}
