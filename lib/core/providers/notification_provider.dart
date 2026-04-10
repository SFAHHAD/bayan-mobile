import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/app_notification.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/notification_service.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;
  StreamSubscription<List<AppNotification>>? _sub;

  NotificationNotifier(this._ref) : super(const NotificationState()) {
    _init();
  }

  void _init() {
    final userId = _ref.read(userProvider).user?.id;
    if (userId == null) return;

    final service = _ref.read(notificationServiceProvider);

    _sub = service.watchNotifications(userId).listen((notifs) {
      state = state.copyWith(
        notifications: notifs,
        unreadCount: notifs.where((n) => !n.isRead).length,
      );
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _ref.read(notificationServiceProvider).markAsRead(notificationId);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, 9999),
    );
  }

  Future<void> markAllAsRead() async {
    final userId = _ref.read(userProvider).user?.id;
    if (userId == null) return;
    await _ref.read(notificationServiceProvider).markAllAsRead(userId);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
      unreadCount: 0,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.read(supabaseClientProvider)),
);

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
      (ref) => NotificationNotifier(ref),
    );

/// Exposes only the unread badge count for lightweight widget consumption.
final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationProvider).unreadCount,
);
