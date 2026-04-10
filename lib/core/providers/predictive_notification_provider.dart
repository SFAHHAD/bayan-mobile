import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/notification_prediction.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// Prediction for any user (by ID)
// -------------------------------------------------------------------------

final notificationPredictionProvider = FutureProvider.autoDispose
    .family<NotificationPrediction, String>((ref, userId) async {
      return ref
          .read(predictiveNotificationServiceProvider)
          .getPrediction(userId);
    });

// -------------------------------------------------------------------------
// Prediction for the current signed-in user
// -------------------------------------------------------------------------

final myNotificationPredictionProvider =
    FutureProvider.autoDispose<NotificationPrediction?>((ref) async {
      return ref.read(predictiveNotificationServiceProvider).getMyPrediction();
    });

// -------------------------------------------------------------------------
// Optimal window check for the current user
// -------------------------------------------------------------------------

final isInOptimalWindowProvider = FutureProvider.autoDispose<bool>((ref) async {
  final pred = await ref.watch(myNotificationPredictionProvider.future);
  if (pred == null) return false;
  return pred.isWithinOptimalWindow();
});
