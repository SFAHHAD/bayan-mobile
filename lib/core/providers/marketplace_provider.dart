import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/ticket.dart';
import 'package:bayan/core/models/diwan_report.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/repositories/marketplace_repository.dart';

// -------------------------------------------------------------------------
// Ticket access check (per-diwan, cached per session)
// -------------------------------------------------------------------------
final diwanAccessProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  diwanId,
) {
  return ref.read(marketplaceRepositoryProvider).checkAccess(diwanId);
});

// -------------------------------------------------------------------------
// My ticket for a specific diwan
// -------------------------------------------------------------------------
final myTicketProvider = FutureProvider.autoDispose.family<Ticket?, String>((
  ref,
  diwanId,
) {
  return ref.read(marketplaceRepositoryProvider).getMyTicket(diwanId);
});

// -------------------------------------------------------------------------
// All tickets purchased by me
// -------------------------------------------------------------------------
final myTicketsProvider = FutureProvider.autoDispose<List<Ticket>>((ref) {
  return ref.read(marketplaceRepositoryProvider).getMyTickets();
});

// -------------------------------------------------------------------------
// Tickets sold for a diwan (host dashboard)
// -------------------------------------------------------------------------
final diwanTicketsSoldProvider = FutureProvider.autoDispose
    .family<List<Ticket>, String>((ref, diwanId) {
      return ref
          .read(marketplaceRepositoryProvider)
          .getDiwanTicketsSold(diwanId);
    });

// -------------------------------------------------------------------------
// Live stream of diwan tickets (host realtime dashboard)
// -------------------------------------------------------------------------
final diwanTicketsStreamProvider = StreamProvider.autoDispose
    .family<List<Ticket>, String>((ref, diwanId) {
      return ref.read(marketplaceRepositoryProvider).watchDiwanTickets(diwanId);
    });

// -------------------------------------------------------------------------
// Purchase state (per-diwan)
// -------------------------------------------------------------------------
class PurchaseState {
  final bool isLoading;
  final PurchaseResult? result;
  final String? error;

  const PurchaseState({this.isLoading = false, this.result, this.error});

  PurchaseState copyWith({
    bool? isLoading,
    PurchaseResult? result,
    String? error,
    bool clearError = false,
  }) => PurchaseState(
    isLoading: isLoading ?? this.isLoading,
    result: result ?? this.result,
    error: clearError ? null : (error ?? this.error),
  );

  bool get isSuccess =>
      result == PurchaseResult.success ||
      result == PurchaseResult.alreadyPurchased;
}

class PurchaseNotifier
    extends AutoDisposeFamilyNotifier<PurchaseState, String> {
  @override
  PurchaseState build(String diwanId) => const PurchaseState();

  Future<void> purchase() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await ref
        .read(marketplaceRepositoryProvider)
        .purchaseTicket(arg);
    final error = _errorMessage(result);
    state = state.copyWith(isLoading: false, result: result, error: error);
    if (result == PurchaseResult.success) {
      // Invalidate access + ticket caches
      ref.invalidate(diwanAccessProvider(arg));
      ref.invalidate(myTicketProvider(arg));
    }
  }

  static String? _errorMessage(PurchaseResult r) {
    switch (r) {
      case PurchaseResult.success:
      case PurchaseResult.alreadyPurchased:
        return null;
      case PurchaseResult.insufficientBalance:
        return 'رصيدك غير كافٍ لشراء التذكرة';
      case PurchaseResult.notPremium:
        return 'هذا الديوان مجاني';
      case PurchaseResult.hostCannotBuy:
        return 'لا يمكن للمضيف شراء تذكرة ديوانه';
      case PurchaseResult.diwanNotFound:
        return 'الديوان غير موجود';
      case PurchaseResult.unknown:
        return 'تعذّر إتمام الشراء، حاول مجدداً';
    }
  }
}

final purchaseProvider = NotifierProvider.autoDispose
    .family<PurchaseNotifier, PurchaseState, String>(PurchaseNotifier.new);

// -------------------------------------------------------------------------
// Analytics Report (host, per-diwan)
// -------------------------------------------------------------------------
class ReportState {
  final DiwanReport? report;
  final bool isLoading;
  final String? error;

  const ReportState({this.report, this.isLoading = false, this.error});

  ReportState copyWith({
    DiwanReport? report,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => ReportState(
    report: report ?? this.report,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

class ReportNotifier extends AutoDisposeFamilyNotifier<ReportState, String> {
  @override
  ReportState build(String diwanId) => const ReportState();

  Future<void> generate() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final report = await ref
          .read(marketplaceRepositoryProvider)
          .generateReport(arg);
      state = state.copyWith(isLoading: false, report: report);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذّر إنشاء التقرير');
    }
  }
}

final reportProvider = NotifierProvider.autoDispose
    .family<ReportNotifier, ReportState, String>(ReportNotifier.new);

// -------------------------------------------------------------------------
// Content Moderation
// -------------------------------------------------------------------------
class ModerationState {
  final Map<String, dynamic>? result;
  final bool isLoading;
  final String? error;

  const ModerationState({this.result, this.isLoading = false, this.error});

  ModerationState copyWith({
    Map<String, dynamic>? result,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => ModerationState(
    result: result ?? this.result,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );

  String? get verdict => result?['verdict'] as String?;
  bool get isApproved => verdict == 'approved';
  bool get isBlocked => verdict == 'blocked';
}

class ModerationNotifier
    extends AutoDisposeFamilyNotifier<ModerationState, String> {
  @override
  ModerationState build(String diwanId) => const ModerationState();

  Future<void> moderate({required String title, String? description}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(marketplaceRepositoryProvider)
          .moderateContent(
            diwanId: arg,
            title: title,
            description: description,
          );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تدقيق المحتوى');
    }
  }
}

final moderationProvider = NotifierProvider.autoDispose
    .family<ModerationNotifier, ModerationState, String>(
      ModerationNotifier.new,
    );
