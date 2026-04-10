enum SummaryStatus { pending, processing, done, failed }

class DiwanSummary {
  final String id;
  final String diwanId;
  final String? transcript;
  final String? summary;
  final List<String> keyPoints;
  final SummaryStatus status;
  final DateTime? generatedAt;
  final DateTime createdAt;

  const DiwanSummary({
    required this.id,
    required this.diwanId,
    this.transcript,
    this.summary,
    this.keyPoints = const [],
    required this.status,
    this.generatedAt,
    required this.createdAt,
  });

  static SummaryStatus _statusFromString(String? s) {
    switch (s) {
      case 'processing':
        return SummaryStatus.processing;
      case 'done':
        return SummaryStatus.done;
      case 'failed':
        return SummaryStatus.failed;
      default:
        return SummaryStatus.pending;
    }
  }

  factory DiwanSummary.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['key_points'];
    final List<String> points;
    if (rawPoints is List) {
      points = rawPoints.map((e) => e.toString()).toList();
    } else {
      points = [];
    }

    return DiwanSummary(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      transcript: map['transcript'] as String?,
      summary: map['summary'] as String?,
      keyPoints: points,
      status: _statusFromString(map['status'] as String?),
      generatedAt: map['generated_at'] != null
          ? DateTime.parse(map['generated_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isReady => status == SummaryStatus.done && summary != null;

  DiwanSummary copyWith({SummaryStatus? status, String? summary}) {
    return DiwanSummary(
      id: id,
      diwanId: diwanId,
      transcript: transcript,
      summary: summary ?? this.summary,
      keyPoints: keyPoints,
      status: status ?? this.status,
      generatedAt: generatedAt,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiwanSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
