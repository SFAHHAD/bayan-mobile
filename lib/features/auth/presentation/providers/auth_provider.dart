import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/profile.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------
class UserSession {
  final User? user;
  final Profile? profile;
  final bool isLoading;
  final String? errorMessage;

  const UserSession({
    this.user,
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  UserSession copyWith({
    User? user,
    Profile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserSession(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// UserNotifier
// ---------------------------------------------------------------------------
class UserNotifier extends StateNotifier<UserSession> {
  final AuthRepository _auth;
  StreamSubscription<AuthState>? _authSub;

  UserNotifier(this._auth) : super(const UserSession()) {
    _init();
  }

  void _init() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      state = UserSession(user: currentUser, isLoading: true);
      _syncProfile(currentUser.id);
    }

    _authSub = _auth.authStateChanges.listen((event) async {
      final user = event.session?.user;
      if (user == null) {
        state = const UserSession();
      } else {
        state = state.copyWith(user: user, isLoading: true);
        await _syncProfile(user.id);
      }
    });
  }

  Future<void> _syncProfile(String userId) async {
    try {
      final profile =
          await _auth.fetchProfile(userId) ?? await _auth.upsertProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _auth.sendOtp(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذّر إرسال الرمز، حاول مرة أخرى',
      );
    }
  }

  Future<bool> verifyOtp(String email, String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _auth.verifyOtp(email, token);
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'رمز غير صحيح أو منتهي الصلاحية',
        );
        return false;
      }
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'رمز غير صحيح أو منتهي الصلاحية',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const UserSession();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(supabaseClientProvider)),
);

final userProvider = StateNotifierProvider<UserNotifier, UserSession>(
  (ref) => UserNotifier(ref.read(authRepositoryProvider)),
);
