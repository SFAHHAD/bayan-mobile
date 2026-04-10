import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/remote_config.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/config_service.dart';

// -------------------------------------------------------------------------
// ConfigService singleton (loads + streams on first access)
// -------------------------------------------------------------------------
final configServiceProvider = Provider<ConfigService>((ref) {
  final service = ConfigService(ref.read(configRepositoryProvider));
  ref.onDispose(service.dispose);
  // Trigger load without awaiting; providers below guard with isLoaded
  service.load();
  return service;
});

// -------------------------------------------------------------------------
// All configs stream (realtime)
// -------------------------------------------------------------------------
final allConfigsStreamProvider = StreamProvider.autoDispose<List<RemoteConfig>>(
  (ref) {
    return ref.read(configRepositoryProvider).watchAll();
  },
);

// -------------------------------------------------------------------------
// Single config by key
// -------------------------------------------------------------------------
final configByKeyProvider = FutureProvider.autoDispose
    .family<RemoteConfig?, String>((ref, key) {
      return ref.read(configRepositoryProvider).fetchByKey(key);
    });

// -------------------------------------------------------------------------
// Feature flags — reactive, use these in UI
// -------------------------------------------------------------------------
final giftingEnabledProvider = Provider.autoDispose<bool>((ref) {
  // Watch the stream so this rebuilds on remote changes
  final stream = ref.watch(allConfigsStreamProvider);
  return stream.whenOrNull(
        data: (_) => ref.read(configServiceProvider).giftingEnabled,
      ) ??
      ref.read(configServiceProvider).giftingEnabled;
});

final searchEnabledProvider = Provider.autoDispose<bool>((ref) {
  final stream = ref.watch(allConfigsStreamProvider);
  return stream.whenOrNull(
        data: (_) => ref.read(configServiceProvider).searchEnabled,
      ) ??
      ref.read(configServiceProvider).searchEnabled;
});

final seriesEnabledProvider = Provider.autoDispose<bool>((ref) {
  final stream = ref.watch(allConfigsStreamProvider);
  return stream.whenOrNull(
        data: (_) => ref.read(configServiceProvider).seriesEnabled,
      ) ??
      ref.read(configServiceProvider).seriesEnabled;
});

final isMaintenanceModeProvider = Provider.autoDispose<bool>((ref) {
  final stream = ref.watch(allConfigsStreamProvider);
  return stream.whenOrNull(
        data: (_) => ref.read(configServiceProvider).isMaintenanceMode,
      ) ??
      false;
});

final maintenanceMessageProvider = Provider.autoDispose<String>((ref) {
  final stream = ref.watch(allConfigsStreamProvider);
  return stream.whenOrNull(
        data: (_) => ref.read(configServiceProvider).maintenanceMessage,
      ) ??
      '';
});

// -------------------------------------------------------------------------
// Config management state (admin — force refresh)
// -------------------------------------------------------------------------
class ConfigState {
  final bool isLoading;
  final String? error;
  final DateTime? lastRefreshed;

  const ConfigState({this.isLoading = false, this.error, this.lastRefreshed});

  ConfigState copyWith({
    bool? isLoading,
    String? error,
    DateTime? lastRefreshed,
    bool clearError = false,
  }) => ConfigState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    lastRefreshed: lastRefreshed ?? this.lastRefreshed,
  );
}

class ConfigNotifier extends AutoDisposeNotifier<ConfigState> {
  @override
  ConfigState build() => const ConfigState();

  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(configServiceProvider).load();
      state = state.copyWith(isLoading: false, lastRefreshed: DateTime.now());
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل الإعدادات');
    }
  }
}

final configProvider =
    NotifierProvider.autoDispose<ConfigNotifier, ConfigState>(
      ConfigNotifier.new,
    );
