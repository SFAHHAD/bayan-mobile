import 'dart:async';
import 'package:bayan/core/models/remote_config.dart';
import 'package:bayan/core/repositories/config_repository.dart';

/// ConfigService provides typed, cached access to remote feature flags.
///
/// Caches configs in-memory after the first [load]. Realtime updates
/// from the `remote_configs` table are merged automatically via [watchAll].
///
/// Usage:
///   final gifting = configService.getBool('enable_gifting', fallback: true);
class ConfigService {
  final ConfigRepository _repo;

  final Map<String, RemoteConfig> _cache = {};
  StreamSubscription<List<RemoteConfig>>? _sub;
  bool _loaded = false;

  ConfigService(this._repo);

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Fetch all configs and start the realtime subscription.
  Future<void> load() async {
    final configs = await _repo.fetchAll();
    for (final c in configs) {
      _cache[c.key] = c;
    }
    _loaded = true;
    _sub ??= _repo.watchAll().listen((list) {
      for (final c in list) {
        _cache[c.key] = c;
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  // -------------------------------------------------------------------------
  // Typed getters
  // -------------------------------------------------------------------------

  bool getBool(String key, {bool fallback = false}) {
    final c = _cache[key];
    if (c == null || !_loaded) return fallback;
    return c.asBool;
  }

  int getInt(String key, {int fallback = 0}) {
    final c = _cache[key];
    if (c == null || !_loaded) return fallback;
    return c.asInt;
  }

  double getDouble(String key, {double fallback = 0.0}) {
    final c = _cache[key];
    if (c == null || !_loaded) return fallback;
    return c.asDouble;
  }

  String getString(String key, {String fallback = ''}) {
    final c = _cache[key];
    if (c == null || !_loaded) return fallback;
    return c.asString;
  }

  Map<String, dynamic> getJson(
    String key, {
    Map<String, dynamic> fallback = const {},
  }) {
    final c = _cache[key];
    if (c == null || !_loaded) return fallback;
    return c.asJson;
  }

  /// Returns the raw [RemoteConfig] for a key, or null if not loaded.
  RemoteConfig? getConfig(String key) => _cache[key];

  bool get isLoaded => _loaded;

  List<RemoteConfig> get allConfigs => _cache.values.toList();

  // -------------------------------------------------------------------------
  // Feature flag shorthands (add more as features grow)
  // -------------------------------------------------------------------------

  bool get giftingEnabled => getBool('enable_gifting', fallback: true);
  bool get searchEnabled => getBool('enable_search', fallback: true);
  bool get premiumDiwansEnabled =>
      getBool('enable_premium_diwans', fallback: true);
  bool get referralRewardsEnabled =>
      getBool('enable_referral_rewards', fallback: true);
  bool get contentModerationEnabled =>
      getBool('enable_content_moderation', fallback: true);
  bool get seriesEnabled => getBool('enable_series', fallback: true);
  bool get verificationEnabled =>
      getBool('enable_verification', fallback: true);

  int get feedPageSize => getInt('feed_page_size', fallback: 20);
  int get maxPollOptions => getInt('max_poll_options', fallback: 4);
  int get platformFeePercent => getInt('platform_fee_percent', fallback: 10);
  int get minFollowersForVerify =>
      getInt('min_followers_for_verify', fallback: 100);
  int get maxDiwanDurationHours =>
      getInt('max_diwan_duration_hours', fallback: 8);

  double get moderationConfidenceBlock =>
      getDouble('moderation_confidence_block', fallback: 0.75);

  String get appMinVersion => getString('app_min_version', fallback: '1.0.0');
  String get maintenanceMessage =>
      getString('maintenance_message', fallback: '');
  String get welcomeBannerAr => getString('welcome_banner_ar', fallback: '');

  bool get isMaintenanceMode => maintenanceMessage.isNotEmpty;
}
