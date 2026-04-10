/// Result returned by the [check_rate_limit] RPC.
class RateLimitResult {
  final bool allowed;
  final int count;
  final int limit;
  final int remaining;
  final DateTime? resetAt;

  const RateLimitResult({
    required this.allowed,
    required this.count,
    required this.limit,
    required this.remaining,
    this.resetAt,
  });

  bool get isThrottled => !allowed;

  factory RateLimitResult.fromMap(Map<String, dynamic> map) {
    return RateLimitResult(
      allowed: (map['allowed'] as bool?) ?? true,
      count: (map['count'] as int?) ?? 0,
      limit: (map['limit'] as int?) ?? 10,
      remaining: (map['remaining'] as int?) ?? 10,
      resetAt: map['reset_at'] != null
          ? DateTime.tryParse(map['reset_at'] as String)
          : null,
    );
  }

  factory RateLimitResult.open() =>
      const RateLimitResult(allowed: true, count: 0, limit: 10, remaining: 10);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RateLimitResult &&
          runtimeType == other.runtimeType &&
          allowed == other.allowed &&
          count == other.count;

  @override
  int get hashCode => Object.hash(allowed, count);
}
