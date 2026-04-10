import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/wallet.dart';
import 'package:bayan/core/models/wallet_transaction.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class WalletState {
  final Wallet? wallet;
  final List<WalletTransaction> recentGifts;
  final bool isLoading;
  final bool isSendingGift;
  final String? error;

  const WalletState({
    this.wallet,
    this.recentGifts = const [],
    this.isLoading = false,
    this.isSendingGift = false,
    this.error,
  });

  int get balance => wallet?.balance ?? 0;

  WalletState copyWith({
    Wallet? wallet,
    List<WalletTransaction>? recentGifts,
    bool? isLoading,
    bool? isSendingGift,
    String? error,
    bool clearError = false,
  }) => WalletState(
    wallet: wallet ?? this.wallet,
    recentGifts: recentGifts ?? this.recentGifts,
    isLoading: isLoading ?? this.isLoading,
    isSendingGift: isSendingGift ?? this.isSendingGift,
    error: clearError ? null : (error ?? this.error),
  );
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class WalletNotifier extends StateNotifier<WalletState> {
  final Ref _ref;
  StreamSubscription<Wallet?>? _walletSub;
  StreamSubscription<List<WalletTransaction>>? _giftSub;

  WalletNotifier(this._ref) : super(const WalletState()) {
    _init();
  }

  String? get _myId => _ref.read(userProvider).user?.id;

  void _init() {
    final userId = _myId;
    if (userId == null) return;
    final repo = _ref.read(walletRepositoryProvider);

    _walletSub = repo.watchWallet(userId).listen((wallet) {
      if (mounted) state = state.copyWith(wallet: wallet);
    });

    _giftSub = repo.watchRecentGifts(userId).listen((gifts) {
      if (mounted) state = state.copyWith(recentGifts: gifts);
    });
  }

  Future<bool> sendGift({
    required String recipientId,
    required String diwanId,
    required int amount,
    String giftType = 'token',
  }) async {
    final myId = _myId;
    if (myId == null || amount <= 0 || state.balance < amount) return false;

    state = state.copyWith(isSendingGift: true, clearError: true);
    try {
      final newBalance = await _ref
          .read(walletRepositoryProvider)
          .sendGift(
            giverId: myId,
            recipientId: recipientId,
            diwanId: diwanId,
            amount: amount,
            giftType: giftType,
          );
      state = state.copyWith(
        isSendingGift: false,
        wallet: state.wallet?.copyWith(balance: newBalance),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSendingGift: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> claimDailyBonus() async {
    final myId = _myId;
    if (myId == null) return false;
    final result = await _ref
        .read(walletRepositoryProvider)
        .claimDailyBonus(myId);
    return result['success'] == true;
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _giftSub?.cancel();
    super.dispose();
  }
}

// -------------------------------------------------------------------------
// Providers
// -------------------------------------------------------------------------
final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(ref),
);

/// Paginated transaction history (infinite scroll).
class TransactionHistoryNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<WalletTransaction>, String> {
  static const _pageSize = 20;
  DateTime? _cursor;
  bool _hasMore = true;

  @override
  Future<List<WalletTransaction>> build(String userId) => _fetch(reset: true);

  bool get hasMore => _hasMore;

  Future<void> fetchNextPage() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    final next = await _fetch(reset: false);
    state = AsyncData([...current, ...next]);
  }

  Future<List<WalletTransaction>> _fetch({required bool reset}) async {
    if (reset) _cursor = null;
    final items = await ref
        .read(walletRepositoryProvider)
        .getTransactionHistory(arg, before: _cursor, limit: _pageSize);
    _hasMore = items.length >= _pageSize;
    if (items.isNotEmpty) _cursor = items.last.createdAt;
    return items;
  }
}

final transactionHistoryProvider = AsyncNotifierProvider.family
    .autoDispose<TransactionHistoryNotifier, List<WalletTransaction>, String>(
      TransactionHistoryNotifier.new,
    );
