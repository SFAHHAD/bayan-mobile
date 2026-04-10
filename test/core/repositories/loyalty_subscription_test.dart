import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/user_activity_metrics.dart';
import 'package:bayan/core/models/subscription_tier.dart';
import 'package:bayan/core/models/user_subscription.dart';
import 'package:bayan/core/models/semantic_result.dart';

void main() {
  final now = DateTime(2026, 4, 10, 15, 0);

  // =========================================================================
  // levelFromXp helpers
  // =========================================================================
  group('levelFromXp / xpForLevel', () {
    test('level 1 starts at 0 XP', () {
      expect(levelFromXp(0), 1);
      expect(levelFromXp(99), 1);
    });
    test('level 2 starts at 100 XP', () {
      expect(levelFromXp(100), 2);
      expect(levelFromXp(399), 2);
    });
    test('level 3 starts at 400 XP', () {
      expect(levelFromXp(400), 3);
      expect(levelFromXp(899), 3);
    });
    test('level 4 starts at 900 XP', () {
      expect(levelFromXp(900), 4);
    });
    test('level 5 starts at 1600 XP', () {
      expect(levelFromXp(1600), 5);
    });
    test('level 10 starts at 8100 XP', () {
      expect(levelFromXp(8100), 10);
    });
    test('xpForLevel is inverse of levelFromXp', () {
      for (int n = 1; n <= 10; n++) {
        expect(
          levelFromXp(xpForLevel(n)),
          n,
          reason: 'level $n: xpForLevel=${{xpForLevel(n)}}',
        );
      }
    });
    test('xpForLevel(1) = 0', () => expect(xpForLevel(1), 0));
    test('xpForLevel(2) = 100', () => expect(xpForLevel(2), 100));
    test('xpForLevel(3) = 400', () => expect(xpForLevel(3), 400));
    test('xpForLevel negative XP clamps to level 1', () {
      expect(levelFromXp(-10), 1);
    });
  });

  // =========================================================================
  // UserLevel enum
  // =========================================================================
  group('UserLevel enum', () {
    test('fromLevel(1) = listener', () {
      expect(UserLevel.fromLevel(1), UserLevel.listener);
    });
    test('fromLevel(2) = conversationalist', () {
      expect(UserLevel.fromLevel(2), UserLevel.conversationalist);
    });
    test('fromLevel(3) = orator', () {
      expect(UserLevel.fromLevel(3), UserLevel.orator);
    });
    test('fromLevel(4) = thinker', () {
      expect(UserLevel.fromLevel(4), UserLevel.thinker);
    });
    test('fromLevel(5) = sage', () {
      expect(UserLevel.fromLevel(5), UserLevel.sage);
    });
    test('fromLevel(6) = masterOfDiwan', () {
      expect(UserLevel.fromLevel(6), UserLevel.masterOfDiwan);
    });
    test('fromLevel(100) = masterOfDiwan (clamped to highest)', () {
      expect(UserLevel.fromLevel(100), UserLevel.masterOfDiwan);
    });
    test('all levels have Arabic labels', () {
      for (final level in UserLevel.values) {
        expect(
          level.label.isNotEmpty,
          isTrue,
          reason: '${level.name} has no label',
        );
      }
    });
    test('minLevel values are distinct and ascending', () {
      final mins = UserLevel.values.map((l) => l.minLevel).toList();
      for (int i = 1; i < mins.length; i++) {
        expect(mins[i], greaterThan(mins[i - 1]));
      }
    });
  });

  // =========================================================================
  // UserActivityMetrics model
  // =========================================================================
  group('UserActivityMetrics model', () {
    Map<String, dynamic> metricsMap({
      int dailyStreak = 5,
      int longestStreak = 10,
      int totalMinutes = 120,
      int xp = 450,
      int level = 3,
      String? lastCheckin,
      int prestige = 15,
    }) => {
      'user_id': 'user-001',
      'daily_streak': dailyStreak,
      'longest_streak': longestStreak,
      'total_minutes_listened': totalMinutes,
      'engagement_xp': xp,
      'current_level': level,
      'last_checkin_date': lastCheckin,
      'prestige_tokens': prestige,
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final m = UserActivityMetrics.fromMap(
        metricsMap(lastCheckin: '2026-04-09'),
      );
      expect(m.userId, 'user-001');
      expect(m.dailyStreak, 5);
      expect(m.longestStreak, 10);
      expect(m.totalMinutesListened, 120);
      expect(m.engagementXp, 450);
      expect(m.currentLevel, 3);
      expect(m.lastCheckinDate, DateTime(2026, 4, 9));
      expect(m.prestigeTokens, 15);
      expect(m.updatedAt, now);
    });

    test('nullable lastCheckinDate parses as null', () {
      final m = UserActivityMetrics.fromMap(metricsMap());
      expect(m.lastCheckinDate, isNull);
    });

    test('defaults for missing fields', () {
      final m = UserActivityMetrics.fromMap({
        'user_id': 'user-002',
        'updated_at': now.toIso8601String(),
      });
      expect(m.dailyStreak, 0);
      expect(m.longestStreak, 0);
      expect(m.totalMinutesListened, 0);
      expect(m.engagementXp, 0);
      expect(m.currentLevel, 1);
      expect(m.prestigeTokens, 0);
    });

    test('userLevel matches levelFromXp', () {
      final m = UserActivityMetrics.fromMap(metricsMap(xp: 450, level: 3));
      expect(m.userLevel, UserLevel.orator);
    });

    test('xpWithinLevel is correct', () {
      // level 3 starts at 400 XP; with 450 XP, within-level = 50
      final m = UserActivityMetrics.fromMap(metricsMap(xp: 450, level: 3));
      expect(m.xpWithinLevel, 50);
    });

    test('xpRangeForLevel is correct (level 3 → 4 = 500 XP)', () {
      final m = UserActivityMetrics.fromMap(metricsMap(xp: 450, level: 3));
      // level 3: 400–899 → range = 900-400 = 500
      expect(m.xpRangeForLevel, 500);
    });

    test('levelProgress is 0.1 at level 3 with 450 XP', () {
      final m = UserActivityMetrics.fromMap(metricsMap(xp: 450, level: 3));
      expect(m.levelProgress, closeTo(0.1, 0.001));
    });

    test('xpToNextLevel is correct', () {
      final m = UserActivityMetrics.fromMap(metricsMap(xp: 450, level: 3));
      expect(m.xpToNextLevel, xpForLevel(4) - 450); // 900 - 450 = 450
    });

    test('hasCheckedInToday false when lastCheckinDate is null', () {
      final m = UserActivityMetrics.fromMap(metricsMap());
      expect(m.hasCheckedInToday, isFalse);
    });

    test('hasCheckedInToday false for past date', () {
      final m = UserActivityMetrics.fromMap(
        metricsMap(lastCheckin: '2026-01-01'),
      );
      expect(m.hasCheckedInToday, isFalse);
    });

    test('equality by userId', () {
      final a = UserActivityMetrics.fromMap(metricsMap(xp: 100));
      final b = UserActivityMetrics.fromMap(metricsMap(xp: 999));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different userIds not equal', () {
      final a = UserActivityMetrics.fromMap(metricsMap());
      final b = UserActivityMetrics.fromMap({
        ...metricsMap(),
        'user_id': 'user-002',
      });
      expect(a, isNot(equals(b)));
    });

    test('toString includes userId and level', () {
      final m = UserActivityMetrics.fromMap(metricsMap());
      expect(m.toString(), contains('user-001'));
      expect(m.toString(), contains('3'));
    });
  });

  // =========================================================================
  // CheckinResult model
  // =========================================================================
  group('CheckinResult model', () {
    test('fromMap parses fresh check-in', () {
      final r = CheckinResult.fromMap({
        'already_checked_in': false,
        'streak': 7,
        'xp': 45,
        'leveled_up': true,
        'new_level': 4,
        'prestige_tokens': 20,
      });
      expect(r.alreadyCheckedIn, isFalse);
      expect(r.newStreak, 7);
      expect(r.xpAwarded, 45);
      expect(r.leveledUp, isTrue);
      expect(r.newLevel, 4);
      expect(r.prestigeTokensAwarded, 20);
    });

    test('fromMap parses already-checked-in', () {
      final r = CheckinResult.fromMap({
        'already_checked_in': true,
        'streak': 5,
        'xp': 0,
        'leveled_up': false,
        'new_level': 3,
        'prestige_tokens': 0,
      });
      expect(r.alreadyCheckedIn, isTrue);
      expect(r.xpAwarded, 0);
      expect(r.leveledUp, isFalse);
      expect(r.prestigeTokensAwarded, 0);
    });

    test('fromMap defaults for missing fields', () {
      final r = CheckinResult.fromMap({});
      expect(r.alreadyCheckedIn, isFalse);
      expect(r.xpAwarded, 0);
      expect(r.newStreak, 1);
      expect(r.leveledUp, isFalse);
      expect(r.newLevel, 1);
      expect(r.prestigeTokensAwarded, 0);
    });

    test('equality checks all fields', () {
      final base = CheckinResult.fromMap({
        'already_checked_in': false,
        'streak': 3,
        'xp': 25,
        'leveled_up': false,
        'new_level': 2,
        'prestige_tokens': 0,
      });
      final same = CheckinResult.fromMap({
        'already_checked_in': false,
        'streak': 3,
        'xp': 25,
        'leveled_up': false,
        'new_level': 2,
        'prestige_tokens': 0,
      });
      final different = CheckinResult.fromMap({
        'already_checked_in': true,
        'streak': 3,
        'xp': 25,
        'leveled_up': false,
        'new_level': 2,
        'prestige_tokens': 0,
      });
      expect(base, equals(same));
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(equals(different)));
    });
  });

  // =========================================================================
  // SubscriptionTier model
  // =========================================================================
  group('SubscriptionTier model', () {
    Map<String, dynamic> tierMap({
      String type = 'gold',
      int priceTokens = 500,
      int? durationDays = 30,
      bool isActive = true,
    }) => {
      'id': 'tier-001',
      'name': 'بيان الذهب',
      'type': type,
      'price_tokens': priceTokens,
      'duration_days': durationDays,
      'features': {
        'private_rooms': true,
        'advanced_analytics': false,
        'priority_support': false,
        'badge_color': '#D4AF37',
      },
      'is_active': isActive,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses gold tier', () {
      final t = SubscriptionTier.fromMap(tierMap());
      expect(t.id, 'tier-001');
      expect(t.name, 'بيان الذهب');
      expect(t.type, TierType.gold);
      expect(t.priceTokens, 500);
      expect(t.durationDays, 30);
      expect(t.isActive, isTrue);
    });

    test('parses all TierType values', () {
      for (final entry in {
        'gold': TierType.gold,
        'platinum': TierType.platinum,
        'founder': TierType.founder,
        null: TierType.gold,
      }.entries) {
        final t = SubscriptionTier.fromMap({...tierMap(), 'type': entry.key});
        expect(t.type, entry.value, reason: 'type=${entry.key}');
      }
    });

    test('typeToString round-trips', () {
      for (final entry in {
        TierType.gold: 'gold',
        TierType.platinum: 'platinum',
        TierType.founder: 'founder',
      }.entries) {
        expect(SubscriptionTier.typeToString(entry.key), entry.value);
        expect(tierTypeFromString(entry.value), entry.key);
      }
    });

    test('tierRank order: gold < platinum < founder', () {
      expect(SubscriptionTier.tierRank(TierType.gold), 1);
      expect(SubscriptionTier.tierRank(TierType.platinum), 2);
      expect(SubscriptionTier.tierRank(TierType.founder), 3);
    });

    test('isLifetime true when durationDays is null', () {
      final t = SubscriptionTier.fromMap(tierMap(durationDays: null));
      expect(t.isLifetime, isTrue);
    });

    test('isLifetime false when durationDays is set', () {
      final t = SubscriptionTier.fromMap(tierMap(durationDays: 30));
      expect(t.isLifetime, isFalse);
    });

    test('features parsed correctly', () {
      final t = SubscriptionTier.fromMap(tierMap());
      expect(t.hasPrivateRooms, isTrue);
      expect(t.hasAdvancedAnalytics, isFalse);
      expect(t.hasPrioritySupport, isFalse);
      expect(t.badgeColor, '#D4AF37');
    });

    test('features defaults when empty map', () {
      final t = SubscriptionTier.fromMap({
        ...tierMap(),
        'features': <String, dynamic>{},
      });
      expect(t.hasPrivateRooms, isFalse);
      expect(t.hasAdvancedAnalytics, isFalse);
      expect(t.hasPrioritySupport, isFalse);
      expect(t.badgeColor, '#D4AF37');
    });

    test('grantsAccessTo: gold grants gold only', () {
      final gold = SubscriptionTier.fromMap(tierMap(type: 'gold'));
      expect(gold.grantsAccessTo(TierType.gold), isTrue);
      expect(gold.grantsAccessTo(TierType.platinum), isFalse);
      expect(gold.grantsAccessTo(TierType.founder), isFalse);
    });

    test('grantsAccessTo: platinum grants gold and platinum', () {
      final platinum = SubscriptionTier.fromMap(tierMap(type: 'platinum'));
      expect(platinum.grantsAccessTo(TierType.gold), isTrue);
      expect(platinum.grantsAccessTo(TierType.platinum), isTrue);
      expect(platinum.grantsAccessTo(TierType.founder), isFalse);
    });

    test('grantsAccessTo: founder grants all', () {
      final founder = SubscriptionTier.fromMap(tierMap(type: 'founder'));
      expect(founder.grantsAccessTo(TierType.gold), isTrue);
      expect(founder.grantsAccessTo(TierType.platinum), isTrue);
      expect(founder.grantsAccessTo(TierType.founder), isTrue);
    });

    test('equality by id', () {
      final a = SubscriptionTier.fromMap(tierMap(type: 'gold'));
      final b = SubscriptionTier.fromMap(tierMap(type: 'platinum'));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids not equal', () {
      final a = SubscriptionTier.fromMap(tierMap());
      final b = SubscriptionTier.fromMap({...tierMap(), 'id': 'tier-002'});
      expect(a, isNot(equals(b)));
    });

    test('features parsed from generic Map (non-String-dynamic)', () {
      final t = SubscriptionTier.fromMap({
        ...tierMap(),
        'features': {'private_rooms': true},
      });
      expect(t.hasPrivateRooms, isTrue);
    });

    test('isActive defaults to true when null', () {
      final t = SubscriptionTier.fromMap({...tierMap(), 'is_active': null});
      expect(t.isActive, isTrue);
    });
  });

  // =========================================================================
  // UserSubscription model
  // =========================================================================
  group('UserSubscription model', () {
    Map<String, dynamic> subMap({
      String status = 'active',
      String? expiresAt,
      String? tierType,
    }) => {
      'id': 'sub-001',
      'user_id': 'user-001',
      'tier_id': 'tier-001',
      'status': status,
      'starts_at': now.toIso8601String(),
      'expires_at': expiresAt,
      'payment_reference': 'PAY-123',
      'created_at': now.toIso8601String(),
      'tier_type': tierType,
    };

    test('fromMap parses all fields', () {
      final s = UserSubscription.fromMap(
        subMap(
          expiresAt: DateTime(2026, 5, 10).toIso8601String(),
          tierType: 'gold',
        ),
      );
      expect(s.id, 'sub-001');
      expect(s.userId, 'user-001');
      expect(s.tierId, 'tier-001');
      expect(s.status, SubscriptionStatus.active);
      expect(s.expiresAt, isNotNull);
      expect(s.paymentReference, 'PAY-123');
      expect(s.tierType, TierType.gold);
    });

    test('parses all SubscriptionStatus values', () {
      for (final entry in {
        'active': SubscriptionStatus.active,
        'expired': SubscriptionStatus.expired,
        'cancelled': SubscriptionStatus.cancelled,
        'pending': SubscriptionStatus.pending,
        null: SubscriptionStatus.pending,
      }.entries) {
        final s = UserSubscription.fromMap({...subMap(), 'status': entry.key});
        expect(s.status, entry.value, reason: 'status=${entry.key}');
      }
    });

    test('statusToString round-trips', () {
      for (final entry in {
        SubscriptionStatus.active: 'active',
        SubscriptionStatus.expired: 'expired',
        SubscriptionStatus.cancelled: 'cancelled',
        SubscriptionStatus.pending: 'pending',
      }.entries) {
        expect(UserSubscription.statusToString(entry.key), entry.value);
      }
    });

    test('isActive: true for active + future expiry', () {
      final s = UserSubscription.fromMap(
        subMap(
          expiresAt: DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
        ),
      );
      expect(s.isActive, isTrue);
    });

    test('isActive: false for expired status', () {
      final s = UserSubscription.fromMap(
        subMap(
          status: 'expired',
          expiresAt: DateTime.now()
              .add(const Duration(days: 10))
              .toIso8601String(),
        ),
      );
      expect(s.isActive, isFalse);
    });

    test('isActive: false for past expiresAt even if status is active', () {
      final s = UserSubscription.fromMap(
        subMap(expiresAt: DateTime(2020, 1, 1).toIso8601String()),
      );
      expect(s.isActive, isFalse);
    });

    test('isLifetime: true when expiresAt is null', () {
      final s = UserSubscription.fromMap(subMap());
      expect(s.isLifetime, isTrue);
    });

    test('isLifetime: false when expiresAt is set', () {
      final s = UserSubscription.fromMap(
        subMap(expiresAt: DateTime(2027, 1, 1).toIso8601String()),
      );
      expect(s.isLifetime, isFalse);
    });

    test('isExpired: true for past expiresAt', () {
      final s = UserSubscription.fromMap(
        subMap(expiresAt: DateTime(2020, 1, 1).toIso8601String()),
      );
      expect(s.isExpired, isTrue);
    });

    test('remainingDays: null for lifetime', () {
      final s = UserSubscription.fromMap(subMap());
      expect(s.remainingDays, isNull);
    });

    test('remainingDays: positive for future expiry', () {
      final future = DateTime.now()
          .add(const Duration(days: 10))
          .toIso8601String();
      final s = UserSubscription.fromMap(subMap(expiresAt: future));
      expect(s.remainingDays! >= 9, isTrue);
    });

    test('grantsAccessTo: active gold grants gold', () {
      final future = DateTime.now()
          .add(const Duration(days: 10))
          .toIso8601String();
      final s = UserSubscription.fromMap(
        subMap(expiresAt: future, tierType: 'gold'),
      );
      expect(s.grantsAccessTo(TierType.gold), isTrue);
      expect(s.grantsAccessTo(TierType.platinum), isFalse);
    });

    test('grantsAccessTo: active founder grants all tiers', () {
      final s = UserSubscription.fromMap(subMap(tierType: 'founder'));
      expect(s.grantsAccessTo(TierType.gold), isTrue);
      expect(s.grantsAccessTo(TierType.platinum), isTrue);
      expect(s.grantsAccessTo(TierType.founder), isTrue);
    });

    test('grantsAccessTo: inactive subscription grants nothing', () {
      final s = UserSubscription.fromMap(
        subMap(status: 'expired', tierType: 'founder'),
      );
      expect(s.grantsAccessTo(TierType.gold), isFalse);
    });

    test('tierType from joined tier_type field', () {
      final s = UserSubscription.fromMap({
        ...subMap(),
        'tier_type': 'platinum',
      });
      expect(s.tierType, TierType.platinum);
    });

    test('tierType from joined type field fallback', () {
      final s = UserSubscription.fromMap({...subMap(), 'type': 'founder'});
      expect(s.tierType, TierType.founder);
    });

    test('equality by id', () {
      final a = UserSubscription.fromMap(subMap(status: 'active'));
      final b = UserSubscription.fromMap(subMap(status: 'cancelled'));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids not equal', () {
      final a = UserSubscription.fromMap(subMap());
      final b = UserSubscription.fromMap({...subMap(), 'id': 'sub-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // =========================================================================
  // SemanticResult model
  // =========================================================================
  group('SemanticResult model', () {
    Map<String, dynamic> resultMap({
      double similarity = 0.85,
      bool isLive = true,
      bool isPremium = false,
      int entryFee = 0,
      String? seriesId,
    }) => {
      'id': 'diwan-001',
      'similarity': similarity,
      'title': 'الديوان السياسي',
      'description': 'نقاشات سياسية معمّقة',
      'owner_id': 'owner-001',
      'host_name': 'أحمد',
      'cover_url': 'https://example.com/cover.jpg',
      'is_live': isLive,
      'is_premium': isPremium,
      'entry_fee': entryFee,
      'listener_count': 42,
      'series_id': seriesId,
    };

    test('fromMap parses all fields', () {
      final r = SemanticResult.fromMap(resultMap());
      expect(r.diwanId, 'diwan-001');
      expect(r.similarity, closeTo(0.85, 0.001));
      expect(r.title, 'الديوان السياسي');
      expect(r.isLive, isTrue);
      expect(r.listenerCount, 42);
    });

    test('similarity accepts int, double, string', () {
      expect(
        SemanticResult.fromMap({...resultMap(), 'similarity': 1}).similarity,
        1.0,
      );
      expect(
        SemanticResult.fromMap({...resultMap(), 'similarity': 0.9}).similarity,
        0.9,
      );
      expect(
        SemanticResult.fromMap({
          ...resultMap(),
          'similarity': '0.75',
        }).similarity,
        0.75,
      );
      expect(
        SemanticResult.fromMap({...resultMap(), 'similarity': null}).similarity,
        0.0,
      );
    });

    test('isFree: true when entryFee=0 and not premium', () {
      final r = SemanticResult.fromMap(
        resultMap(entryFee: 0, isPremium: false),
      );
      expect(r.isFree, isTrue);
    });

    test('isFree: false when premium', () {
      final r = SemanticResult.fromMap(resultMap(isPremium: true));
      expect(r.isFree, isFalse);
    });

    test('isFree: false when entryFee > 0', () {
      final r = SemanticResult.fromMap(resultMap(entryFee: 100));
      expect(r.isFree, isFalse);
    });

    test('isPartOfSeries: true when seriesId set', () {
      final r = SemanticResult.fromMap(resultMap(seriesId: 'series-001'));
      expect(r.isPartOfSeries, isTrue);
    });

    test('isPartOfSeries: false when seriesId null', () {
      final r = SemanticResult.fromMap(resultMap());
      expect(r.isPartOfSeries, isFalse);
    });

    test('similarityPercent formats correctly', () {
      expect(
        SemanticResult.fromMap(resultMap(similarity: 0.85)).similarityPercent,
        '85%',
      );
      expect(
        SemanticResult.fromMap(resultMap(similarity: 1.0)).similarityPercent,
        '100%',
      );
      expect(
        SemanticResult.fromMap(resultMap(similarity: 0.0)).similarityPercent,
        '0%',
      );
    });

    test('diwan_id field as fallback key', () {
      final r = SemanticResult.fromMap({
        ...resultMap(),
        'id': null,
        'diwan_id': 'diwan-002',
      });
      expect(r.diwanId, 'diwan-002');
    });

    test('equality by diwanId', () {
      final a = SemanticResult.fromMap(resultMap(similarity: 0.9));
      final b = SemanticResult.fromMap(resultMap(similarity: 0.5));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different diwanIds not equal', () {
      final a = SemanticResult.fromMap(resultMap());
      final b = SemanticResult.fromMap({...resultMap(), 'id': 'diwan-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // =========================================================================
  // tierTypeFromString top-level function
  // =========================================================================
  group('tierTypeFromString', () {
    test('maps all valid strings', () {
      expect(tierTypeFromString('gold'), TierType.gold);
      expect(tierTypeFromString('platinum'), TierType.platinum);
      expect(tierTypeFromString('founder'), TierType.founder);
    });
    test('null/unknown defaults to gold', () {
      expect(tierTypeFromString(null), TierType.gold);
      expect(tierTypeFromString('unknown'), TierType.gold);
    });
  });
}
