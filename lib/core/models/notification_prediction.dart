/// Result of the predictive notification analysis for a single user.
///
/// [bestHour] is a 24-hour value (0–23) in the user's local timezone.
/// [confidence] is a 0.0–1.0 ratio of activity concentrated in that hour.
/// [isPredicted] is false when there is insufficient data (< 5 events).
class NotificationPrediction {
  final int bestHour;
  final double confidence;
  final int totalEvents;
  final Map<int, int> hourDistribution;
  final bool isPredicted;

  const NotificationPrediction({
    required this.bestHour,
    required this.confidence,
    required this.totalEvents,
    required this.hourDistribution,
    required this.isPredicted,
  });

  // -------------------------------------------------------------------------
  // Computed helpers
  // -------------------------------------------------------------------------

  /// Confidence threshold above which we consider the prediction reliable.
  static const double highConfidenceThreshold = 0.3;

  bool get isHighConfidence => confidence >= highConfidenceThreshold;

  /// Human-readable label, e.g. "6:00 PM" or "09:00 AM".
  String get bestTimeLabel {
    final hour = bestHour % 24;
    final period = hour < 12 ? 'AM' : 'PM';
    final display = hour == 0
        ? 12
        : hour <= 12
        ? hour
        : hour - 12;
    final padded = display.toString().padLeft(2, '0');
    return '$padded:00 $period';
  }

  /// True if [at] falls within ±1 hour of [bestHour].
  bool isWithinOptimalWindow({DateTime? at}) {
    final now = at ?? DateTime.now();
    final currentHour = now.hour;
    final diff = ((currentHour - bestHour) % 24).abs();
    return diff <= 1 || diff >= 23;
  }

  // -------------------------------------------------------------------------
  // Factory
  // -------------------------------------------------------------------------

  factory NotificationPrediction.fromMap(Map<String, dynamic> map) {
    final rawDist = map['hour_distribution'];
    final Map<int, int> dist = {};
    if (rawDist is Map) {
      rawDist.forEach((k, v) {
        final key = int.tryParse(k.toString());
        final val = v is int ? v : int.tryParse(v.toString()) ?? 0;
        if (key != null) dist[key] = val;
      });
    }
    return NotificationPrediction(
      bestHour: (map['best_hour'] as int?) ?? 18,
      confidence: ((map['confidence'] as num?) ?? 0.0).toDouble(),
      totalEvents: (map['total_events'] as int?) ?? 0,
      hourDistribution: dist,
      isPredicted: (map['is_predicted'] as bool?) ?? false,
    );
  }

  factory NotificationPrediction.defaultPrediction() =>
      const NotificationPrediction(
        bestHour: 18,
        confidence: 0.0,
        totalEvents: 0,
        hourDistribution: {},
        isPredicted: false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPrediction &&
          runtimeType == other.runtimeType &&
          bestHour == other.bestHour &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(bestHour, confidence);
}
