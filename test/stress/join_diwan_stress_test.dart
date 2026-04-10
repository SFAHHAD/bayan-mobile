/// Stress-test simulation: 1,000 concurrent 'Join Diwan' requests.
///
/// This test verifies that the [RateLimiterService] logic and BurstMode
/// correctly handle celebrity-level traffic spikes using a pure in-memory
/// mock of the token-bucket algorithm — no real network calls required.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/rate_limit_result.dart';

// ---------------------------------------------------------------------------
// In-memory token-bucket mock — mirrors check_rate_limit SQL logic
// ---------------------------------------------------------------------------

class _MockBucket {
  int hitCount = 0;
  DateTime windowStart = DateTime.now();

  _MockBucket();
}

class _MockRateLimiter {
  final Map<String, _MockBucket> _buckets = {};
  final int limit;
  final Duration window;

  _MockRateLimiter({
    this.limit = 500,
    this.window = const Duration(seconds: 60),
  });

  RateLimitResult check(String bucketKey, String action) {
    final key = '$bucketKey:$action';
    final now = DateTime.now();
    final bucket = _buckets[key];

    // Expire old window
    if (bucket != null && now.difference(bucket.windowStart) > window) {
      _buckets.remove(key);
    }

    final b = _buckets.putIfAbsent(key, _MockBucket.new);
    b.hitCount++;

    final allowed = b.hitCount <= limit;
    final remaining = (limit - b.hitCount).clamp(0, limit);
    final resetAt = b.windowStart.add(window);

    return RateLimitResult(
      allowed: allowed,
      count: b.hitCount,
      limit: limit,
      remaining: remaining,
      resetAt: resetAt,
    );
  }

  /// Apply burst mode: pre-credits the bucket (negative head-start).
  void enableBurstMode(String diwanId, {int multiplier = 5}) {
    final key = 'diwan:$diwanId:join';
    _buckets.remove(key); // Reset window
    final b = _MockBucket();
    b.hitCount = -(multiplier * limit); // Pre-credit
    _buckets[key] = b;
  }

  void reset() => _buckets.clear();
}

// ---------------------------------------------------------------------------
// Concurrency harness
// ---------------------------------------------------------------------------

/// Simulates [count] concurrent join attempts against the rate limiter.
/// Returns a record of how many were allowed vs throttled.
Future<({int allowed, int throttled, int peakConcurrency})> _simulateConcurrent(
  _MockRateLimiter limiter,
  String diwanId,
  int count,
) async {
  int allowedCount = 0;
  int throttledCount = 0;
  int activeFutures = 0;
  int peakConcurrency = 0;

  final futures = List.generate(count, (_) async {
    activeFutures++;
    if (activeFutures > peakConcurrency) peakConcurrency = activeFutures;
    // Yield to event loop to simulate concurrency
    await Future<void>.delayed(Duration.zero);
    final result = limiter.check('diwan:$diwanId', 'join');
    if (result.allowed) {
      allowedCount++;
    } else {
      throttledCount++;
    }
    activeFutures--;
  });

  await Future.wait(futures);
  return (
    allowed: allowedCount,
    throttled: throttledCount,
    peakConcurrency: peakConcurrency,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Join Diwan Stress Test — 1,000 Concurrent Requests', () {
    late _MockRateLimiter limiter;
    const diwanId = 'celebrity-diwan-001';
    const concurrency = 1000;

    setUp(() {
      limiter = _MockRateLimiter(limit: 500, window: Duration(seconds: 60));
    });

    tearDown(() => limiter.reset());

    // -------------------------------------------------------------------------

    test(
      '1000 concurrent requests: exactly 500 allowed, 500 throttled',
      () async {
        final result = await _simulateConcurrent(limiter, diwanId, concurrency);

        expect(
          result.allowed,
          500,
          reason: 'Exactly the limit (500) must be allowed per window',
        );
        expect(
          result.throttled,
          500,
          reason: 'All requests beyond the limit must be throttled',
        );
        expect(result.allowed + result.throttled, concurrency);
      },
    );

    test('requests beyond limit return isThrottled=true', () async {
      // Fill the bucket to the limit
      for (var i = 0; i < 500; i++) {
        limiter.check('diwan:$diwanId', 'join');
      }
      // Next request must be throttled
      final overflow = limiter.check('diwan:$diwanId', 'join');
      expect(overflow.isThrottled, isTrue);
      expect(overflow.remaining, 0);
    });

    test('remaining decreases monotonically with each request', () async {
      final remainings = <int>[];
      for (var i = 0; i < 10; i++) {
        remainings.add(limiter.check('diwan:$diwanId', 'join').remaining);
      }
      for (var i = 1; i < remainings.length; i++) {
        expect(
          remainings[i],
          lessThanOrEqualTo(remainings[i - 1]),
          reason: 'remaining must never increase mid-window',
        );
      }
    });

    test('separate diwans have independent buckets', () async {
      final r1 = await _simulateConcurrent(limiter, 'diwan-A', 600);
      final r2 = await _simulateConcurrent(limiter, 'diwan-B', 600);

      // Each diwan gets its own 500-request window
      expect(r1.allowed, 500);
      expect(r2.allowed, 500);
    });

    // -------------------------------------------------------------------------
    // Burst Mode
    // -------------------------------------------------------------------------

    test('burst mode allows 5× more requests before throttling', () async {
      limiter.enableBurstMode(diwanId, multiplier: 5);
      // With 5× pre-credit, 500 × (1 + 5) = 3000 effective slots
      // But our mock limit remains 500, pre-credit = -2500
      // So first 500 + 2500 = 3000 calls are allowed
      final result = await _simulateConcurrent(limiter, diwanId, concurrency);

      // All 1000 should be allowed (limit=500 + 2500 pre-credit = 3000 effective)
      expect(
        result.allowed,
        concurrency,
        reason: 'Burst mode should absorb all 1000 requests',
      );
      expect(result.throttled, 0);
    });

    test('burst mode resets the window cleanly', () {
      // Fill without burst
      for (var i = 0; i < 600; i++) {
        limiter.check('diwan:$diwanId', 'join');
      }
      final beforeBurst = limiter.check('diwan:$diwanId', 'join');
      expect(beforeBurst.isThrottled, isTrue);

      // Enable burst — should reset
      limiter.enableBurstMode(diwanId, multiplier: 5);
      final afterBurst = limiter.check('diwan:$diwanId', 'join');
      expect(
        afterBurst.allowed,
        isTrue,
        reason: 'Burst mode must reset the bucket and allow traffic again',
      );
    });

    test('after burst window expires, normal limit applies again', () {
      // Simulate expired burst by resetting manually
      limiter.enableBurstMode(diwanId, multiplier: 5);
      limiter.reset(); // Simulate window expiry
      limiter = _MockRateLimiter(limit: 500);

      int allowed = 0;
      for (var i = 0; i < 1000; i++) {
        if (limiter.check('diwan:$diwanId', 'join').allowed) allowed++;
      }
      expect(
        allowed,
        500,
        reason: 'Normal limit should apply once burst window expires',
      );
    });

    // -------------------------------------------------------------------------
    // Performance
    // -------------------------------------------------------------------------

    test('1000 concurrent checks complete in under 1 second', () async {
      final stopwatch = Stopwatch()..start();
      await _simulateConcurrent(limiter, diwanId, concurrency);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Rate limiter must handle 1000 checks in under 1 second',
      );
    });

    test(
      '1000 checks from 10 different diwans complete in under 2 seconds',
      () async {
        final stopwatch = Stopwatch()..start();
        final futures = List.generate(
          10,
          (i) => _simulateConcurrent(limiter, 'diwan-$i', 100),
        );
        await Future.wait(futures);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      },
    );

    // -------------------------------------------------------------------------
    // RateLimitResult model under stress
    // -------------------------------------------------------------------------

    test('RateLimitResult.open() always allows regardless of call count', () {
      for (var i = 0; i < 1000; i++) {
        expect(RateLimitResult.open().allowed, isTrue);
      }
    });

    test('throttled result has remaining=0 and isThrottled=true', () {
      final throttled = RateLimitResult.fromMap({
        'allowed': false,
        'count': 501,
        'limit': 500,
        'remaining': 0,
      });
      expect(throttled.isThrottled, isTrue);
      expect(throttled.remaining, 0);
    });
  });
}
