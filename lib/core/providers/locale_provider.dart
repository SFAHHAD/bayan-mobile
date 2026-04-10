import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists the chosen locale in Hive ('app_prefs' box, key 'locale').
/// Supported values: 'ar' (Classical) and 'ar_KW' (Kuwaiti).
class LocaleNotifier extends Notifier<Locale> {
  static const _boxName = 'app_prefs';
  static const _key = 'locale';

  static const Locale classical = Locale('ar');
  static const Locale kuwaiti = Locale('ar', 'KW');

  @override
  Locale build() {
    _loadFromHive();
    return kuwaiti;
  }

  Future<void> _loadFromHive() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    final stored = box.get(_key) as String?;
    if (stored == 'ar') {
      state = classical;
    } else {
      state = kuwaiti;
    }
  }

  Future<void> setClassical() async => _persist(classical);
  Future<void> setKuwaiti() async => _persist(kuwaiti);

  Future<void> toggle() async {
    if (state == classical) {
      await setKuwaiti();
    } else {
      await setClassical();
    }
  }

  bool get isKuwaiti => state == kuwaiti;
  bool get isClassical => state == classical;

  Future<void> _persist(Locale locale) async {
    state = locale;
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    await box.put(
      _key,
      locale.countryCode?.isNotEmpty == true
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode,
    );
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
