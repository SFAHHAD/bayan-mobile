import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/diwan_series.dart';
import 'package:bayan/core/models/series_subscription.dart';
import 'package:bayan/core/models/user_interest.dart';
import 'package:bayan/core/models/activity_log.dart';
import 'package:bayan/core/models/feed_item.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/models/deep_link.dart';
import 'package:bayan/core/models/app_notification.dart';

void main() {
  final now = DateTime(2026, 4, 10, 12, 0);

  // -------------------------------------------------------------------------
  // DiwanSeries model
  // -------------------------------------------------------------------------
  group('DiwanSeries model', () {
    Map<String, dynamic> seriesMap({
      int episodeCount = 3,
      bool isActive = true,
      String? category,
    }) => {
      'id': 'series-001',
      'host_id': 'user-001',
      'title': 'سلسلة الفلسفة',
      'description': 'رحلة في الفكر',
      'cover_url': 'https://cdn.bayan.app/series/001.jpg',
      'category': category,
      'episode_count': episodeCount,
      'is_active': isActive,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final s = DiwanSeries.fromMap(seriesMap(category: 'philosophy'));
      expect(s.id, 'series-001');
      expect(s.hostId, 'user-001');
      expect(s.title, 'سلسلة الفلسفة');
      expect(s.description, 'رحلة في الفكر');
      expect(s.coverUrl, 'https://cdn.bayan.app/series/001.jpg');
      expect(s.category, 'philosophy');
      expect(s.episodeCount, 3);
      expect(s.isActive, isTrue);
      expect(s.createdAt, now);
    });

    test('episodeCount defaults to 0 when null', () {
      final map = Map<String, dynamic>.from(seriesMap())
        ..['episode_count'] = null;
      expect(DiwanSeries.fromMap(map).episodeCount, 0);
    });

    test('isActive defaults to true when null', () {
      final map = Map<String, dynamic>.from(seriesMap())..['is_active'] = null;
      expect(DiwanSeries.fromMap(map).isActive, isTrue);
    });

    test('isEmpty / hasEpisodes helpers', () {
      expect(DiwanSeries.fromMap(seriesMap(episodeCount: 0)).isEmpty, isTrue);
      expect(
        DiwanSeries.fromMap(seriesMap(episodeCount: 0)).hasEpisodes,
        isFalse,
      );
      expect(
        DiwanSeries.fromMap(seriesMap(episodeCount: 1)).hasEpisodes,
        isTrue,
      );
      expect(DiwanSeries.fromMap(seriesMap(episodeCount: 1)).isEmpty, isFalse);
    });

    test('category is nullable', () {
      expect(DiwanSeries.fromMap(seriesMap()).category, isNull);
    });

    test('copyWith updates selected fields only', () {
      final s = DiwanSeries.fromMap(seriesMap(episodeCount: 2));
      final updated = s.copyWith(title: 'سلسلة جديدة', episodeCount: 10);
      expect(updated.title, 'سلسلة جديدة');
      expect(updated.episodeCount, 10);
      expect(updated.id, s.id);
      expect(updated.hostId, s.hostId);
      expect(updated.isActive, s.isActive);
    });

    test('toMap excludes id and host_id (server-generated)', () {
      final s = DiwanSeries.fromMap(seriesMap());
      final m = s.toMap();
      expect(m.containsKey('id'), isFalse);
      expect(m['host_id'], 'user-001');
      expect(m['title'], 'سلسلة الفلسفة');
    });

    test('equality by id', () {
      final a = DiwanSeries.fromMap(seriesMap(episodeCount: 1));
      final b = DiwanSeries.fromMap(seriesMap(episodeCount: 99));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids not equal', () {
      final a = DiwanSeries.fromMap(seriesMap());
      final b = DiwanSeries.fromMap({...seriesMap(), 'id': 'series-002'});
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // SeriesSubscription model
  // -------------------------------------------------------------------------
  group('SeriesSubscription model', () {
    Map<String, dynamic> subMap({bool notifyNew = true}) => {
      'id': 'sub-001',
      'user_id': 'user-001',
      'series_id': 'series-001',
      'notify_new': notifyNew,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final s = SeriesSubscription.fromMap(subMap());
      expect(s.id, 'sub-001');
      expect(s.userId, 'user-001');
      expect(s.seriesId, 'series-001');
      expect(s.notifyNew, isTrue);
    });

    test('notifyNew defaults to true when null', () {
      final map = Map<String, dynamic>.from(subMap())..['notify_new'] = null;
      expect(SeriesSubscription.fromMap(map).notifyNew, isTrue);
    });

    test('notifyNew = false preserved', () {
      expect(
        SeriesSubscription.fromMap(subMap(notifyNew: false)).notifyNew,
        isFalse,
      );
    });

    test('copyWith updates notifyNew', () {
      final s = SeriesSubscription.fromMap(subMap());
      final updated = s.copyWith(notifyNew: false);
      expect(updated.notifyNew, isFalse);
      expect(updated.id, s.id);
    });

    test('toMap returns correct fields', () {
      final s = SeriesSubscription.fromMap(subMap(notifyNew: false));
      final m = s.toMap();
      expect(m['series_id'], 'series-001');
      expect(m['notify_new'], isFalse);
    });

    test('equality by id', () {
      final a = SeriesSubscription.fromMap(subMap(notifyNew: true));
      final b = SeriesSubscription.fromMap(subMap(notifyNew: false));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // UserInterest model
  // -------------------------------------------------------------------------
  group('UserInterest model', () {
    Map<String, dynamic> interestMap({
      dynamic weight = 3.5,
      String source = 'explicit',
    }) => {
      'id': 'int-001',
      'user_id': 'user-001',
      'category': 'philosophy',
      'weight': weight,
      'source': source,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromMap parses double weight', () {
      expect(UserInterest.fromMap(interestMap(weight: 3.5)).weight, 3.5);
    });

    test('fromMap parses int weight', () {
      expect(UserInterest.fromMap(interestMap(weight: 5)).weight, 5.0);
    });

    test('fromMap parses string weight', () {
      expect(UserInterest.fromMap(interestMap(weight: '7.25')).weight, 7.25);
    });

    test('fromMap defaults weight to 1.0 on null', () {
      final map = Map<String, dynamic>.from(interestMap())..['weight'] = null;
      expect(UserInterest.fromMap(map).weight, 1.0);
    });

    test('weight is clamped 0–10', () {
      expect(UserInterest.fromMap(interestMap(weight: 99.0)).weight, 10.0);
      expect(UserInterest.fromMap(interestMap(weight: -5.0)).weight, 0.0);
    });

    test('source enum parsed correctly for all values', () {
      for (final entry in {
        'explicit': InterestSource.explicit,
        'implicit': InterestSource.implicit,
        'admin': InterestSource.admin,
        null: InterestSource.explicit,
      }.entries) {
        final map = Map<String, dynamic>.from(interestMap())
          ..['source'] = entry.key;
        expect(
          UserInterest.fromMap(map).source,
          entry.value,
          reason: 'Failed for source: ${entry.key}',
        );
      }
    });

    test('sourceString round-trips', () {
      for (final s in ['explicit', 'implicit', 'admin']) {
        final map = Map<String, dynamic>.from(interestMap())..['source'] = s;
        expect(UserInterest.fromMap(map).sourceString, s);
      }
    });

    test('isExplicit / isImplicit helpers', () {
      expect(
        UserInterest.fromMap(interestMap(source: 'explicit')).isExplicit,
        isTrue,
      );
      expect(
        UserInterest.fromMap(interestMap(source: 'explicit')).isImplicit,
        isFalse,
      );
      expect(
        UserInterest.fromMap(interestMap(source: 'implicit')).isImplicit,
        isTrue,
      );
    });

    test('copyWith clamps weight', () {
      final i = UserInterest.fromMap(interestMap(weight: 5.0));
      expect(i.copyWith(weight: 15.0).weight, 10.0);
      expect(i.copyWith(weight: -1.0).weight, 0.0);
    });

    test('copyWith preserves unchanged fields', () {
      final i = UserInterest.fromMap(interestMap());
      final updated = i.copyWith(weight: 8.0);
      expect(updated.category, i.category);
      expect(updated.userId, i.userId);
      expect(updated.id, i.id);
    });

    test('equality by id', () {
      final a = UserInterest.fromMap(interestMap(weight: 1.0));
      final b = UserInterest.fromMap(interestMap(weight: 9.0));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // ActivityLog model
  // -------------------------------------------------------------------------
  group('ActivityLog model', () {
    Map<String, dynamic> logMap(String type) => {
      'id': 'log-001',
      'user_id': 'user-001',
      'action_type': type,
      'metadata': {'diwan_id': 'diwan-001'},
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all action types', () {
      final typeMap = {
        'joined_diwan': ActivityLogType.joinedDiwan,
        'left_diwan': ActivityLogType.leftDiwan,
        'purchased_ticket': ActivityLogType.purchasedTicket,
        'followed_user': ActivityLogType.followedUser,
        'unfollowed_user': ActivityLogType.unfollowedUser,
        'upvoted_question': ActivityLogType.upvotedQuestion,
        'voted_poll': ActivityLogType.votedPoll,
        'sent_gift': ActivityLogType.sentGift,
        'viewed_profile': ActivityLogType.viewedProfile,
      };
      for (final entry in typeMap.entries) {
        final log = ActivityLog.fromMap(logMap(entry.key));
        expect(log.actionType, entry.value, reason: 'Failed for: ${entry.key}');
      }
    });

    test('actionTypeString round-trips', () {
      final types = [
        'joined_diwan',
        'left_diwan',
        'purchased_ticket',
        'followed_user',
        'unfollowed_user',
        'upvoted_question',
        'voted_poll',
        'sent_gift',
        'viewed_profile',
      ];
      for (final t in types) {
        expect(ActivityLog.fromMap(logMap(t)).actionTypeString, t);
      }
    });

    test('metadata parsed as Map<String, dynamic>', () {
      final log = ActivityLog.fromMap(logMap('joined_diwan'));
      expect(log.metadata['diwan_id'], 'diwan-001');
    });

    test('metadata defaults to empty map on null', () {
      final map = Map<String, dynamic>.from(logMap('joined_diwan'))
        ..['metadata'] = null;
      expect(ActivityLog.fromMap(map).metadata, isEmpty);
    });

    test('equality by id', () {
      final a = ActivityLog.fromMap(logMap('joined_diwan'));
      final b = ActivityLog.fromMap(logMap('purchased_ticket'));
      expect(a, equals(b));
    });

    test('different ids not equal', () {
      final a = ActivityLog.fromMap(logMap('joined_diwan'));
      final b = ActivityLog.fromMap({
        ...logMap('joined_diwan'),
        'id': 'log-002',
      });
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // FeedItem model
  // -------------------------------------------------------------------------
  group('FeedItem model', () {
    Map<String, dynamic> feedMap({
      bool isLive = true,
      bool isPremium = false,
      int entryFee = 0,
      String? seriesId,
      dynamic score = 3.75,
    }) => {
      'diwan_id': 'diwan-001',
      'title': 'ديوان الفلسفة',
      'description': 'نقاش فلسفي',
      'owner_id': 'user-002',
      'host_name': 'أحمد',
      'cover_url': null,
      'is_live': isLive,
      'is_premium': isPremium,
      'entry_fee': entryFee,
      'listener_count': 42,
      'series_id': seriesId,
      'moderation_status': 'approved',
      'score': score,
      'score_interests': 1.5,
      'score_social': 0.9,
      'score_trending': 1.35,
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses all fields', () {
      final f = FeedItem.fromMap(feedMap(seriesId: 'series-001'));
      expect(f.diwanId, 'diwan-001');
      expect(f.title, 'ديوان الفلسفة');
      expect(f.isLive, isTrue);
      expect(f.listenerCount, 42);
      expect(f.seriesId, 'series-001');
      expect(f.score, 3.75);
      expect(f.scoreInterests, 1.5);
      expect(f.scoreSocial, 0.9);
      expect(f.scoreTrending, 1.35);
    });

    test('score parses from int', () {
      expect(FeedItem.fromMap(feedMap(score: 5)).score, 5.0);
    });

    test('score parses from string', () {
      expect(FeedItem.fromMap(feedMap(score: '2.5')).score, 2.5);
    });

    test('score defaults to 0.0 on null', () {
      final map = Map<String, dynamic>.from(feedMap())..['score'] = null;
      expect(FeedItem.fromMap(map).score, 0.0);
    });

    test('isFree when not premium', () {
      expect(FeedItem.fromMap(feedMap(isPremium: false)).isFree, isTrue);
    });

    test('isFree when premium but entryFee=0', () {
      expect(
        FeedItem.fromMap(feedMap(isPremium: true, entryFee: 0)).isFree,
        isTrue,
      );
    });

    test('isFree is false when premium and entryFee > 0', () {
      expect(
        FeedItem.fromMap(feedMap(isPremium: true, entryFee: 50)).isFree,
        isFalse,
      );
    });

    test('isPartOfSeries when seriesId present', () {
      expect(
        FeedItem.fromMap(feedMap(seriesId: 'series-001')).isPartOfSeries,
        isTrue,
      );
      expect(FeedItem.fromMap(feedMap()).isPartOfSeries, isFalse);
    });

    test('equality by diwanId', () {
      final a = FeedItem.fromMap(feedMap(score: 1.0));
      final b = FeedItem.fromMap(feedMap(score: 9.9));
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // Diwan model — seriesId + episodeNumber fields
  // -------------------------------------------------------------------------
  group('Diwan model — series fields', () {
    Map<String, dynamic> diwanMap({String? seriesId, int? episodeNumber}) => {
      'id': 'diwan-001',
      'title': 'ديوان الفلسفة',
      'series_id': seriesId,
      'episode_number': episodeNumber,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('seriesId and episodeNumber default to null', () {
      final d = Diwan.fromMap(diwanMap());
      expect(d.seriesId, isNull);
      expect(d.episodeNumber, isNull);
    });

    test('fromMap parses series fields', () {
      final d = Diwan.fromMap(
        diwanMap(seriesId: 'series-001', episodeNumber: 3),
      );
      expect(d.seriesId, 'series-001');
      expect(d.episodeNumber, 3);
    });

    test('toMap includes series_id and episode_number', () {
      final d = Diwan.fromMap(diwanMap(seriesId: 's-1', episodeNumber: 1));
      expect(d.toMap()['series_id'], 's-1');
      expect(d.toMap()['episode_number'], 1);
    });

    test('copyWith updates series fields independently', () {
      final d = Diwan.fromMap(diwanMap());
      final ep = d.copyWith(seriesId: 'series-001', episodeNumber: 2);
      expect(ep.seriesId, 'series-001');
      expect(ep.episodeNumber, 2);
      expect(ep.id, d.id);
    });
  });

  // -------------------------------------------------------------------------
  // DeepLink — new targets
  // -------------------------------------------------------------------------
  group('DeepLink — v1.4 targets', () {
    test('bayan://series/{id} parses to series target', () {
      final link = DeepLink.fromUri(Uri.parse('bayan://series/series-001'));
      expect(link?.target, DeepLinkTarget.series);
      expect(link?.id, 'series-001');
    });

    test('bayan://join/{diwanId} parses to joinDiwan target', () {
      final link = DeepLink.fromUri(Uri.parse('bayan://join/diwan-001'));
      expect(link?.target, DeepLinkTarget.joinDiwan);
      expect(link?.id, 'diwan-001');
    });

    test('bayan://referral/{code} parses to referral target', () {
      final link = DeepLink.fromUri(Uri.parse('bayan://referral/ABCD1234'));
      expect(link?.target, DeepLinkTarget.referral);
      expect(link?.id, 'ABCD1234');
    });

    test('existing diwan target still works', () {
      final link = DeepLink.fromUri(Uri.parse('bayan://diwan/diwan-001'));
      expect(link?.target, DeepLinkTarget.diwan);
    });

    test('unknown scheme returns null', () {
      expect(DeepLink.fromUri(Uri.parse('https://bayan.app/diwan/x')), isNull);
    });

    test('returns null when id is empty', () {
      expect(DeepLink.fromUri(Uri.parse('bayan://series/')), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AppNotification — new fields
  // -------------------------------------------------------------------------
  group('AppNotification — v1.4 fields', () {
    Map<String, dynamic> notifMap({
      String type = 'series_new_episode',
      String? actionUrl,
      String? actionType,
    }) => {
      'id': 'notif-001',
      'user_id': 'user-001',
      'type': type,
      'title': 'حلقة جديدة',
      'body': 'تحقق من آخر حلقة في السلسلة',
      'is_read': false,
      'action_url': actionUrl,
      'action_type': actionType,
      'metadata': {'series_id': 'series-001'},
      'created_at': now.toIso8601String(),
    };

    test('fromMap parses series_new_episode type', () {
      final n = AppNotification.fromMap(notifMap());
      expect(n.type, NotificationType.seriesNewEpisode);
    });

    test('actionUrl parsed when present', () {
      final n = AppNotification.fromMap(
        notifMap(actionUrl: 'bayan://diwan/diwan-001'),
      );
      expect(n.actionUrl, 'bayan://diwan/diwan-001');
    });

    test('actionUrl is null when absent', () {
      expect(AppNotification.fromMap(notifMap()).actionUrl, isNull);
    });

    test('actionType parsed correctly', () {
      final n = AppNotification.fromMap(notifMap(actionType: 'join_diwan'));
      expect(n.actionType, 'join_diwan');
    });

    test('metadata parsed correctly', () {
      final n = AppNotification.fromMap(notifMap());
      expect(n.metadata['series_id'], 'series-001');
    });

    test('copyWith updates actionUrl independently', () {
      final n = AppNotification.fromMap(notifMap());
      final updated = n.copyWith(actionUrl: 'bayan://series/s-1');
      expect(updated.actionUrl, 'bayan://series/s-1');
      expect(updated.id, n.id);
      expect(updated.isRead, n.isRead);
    });
  });
}
