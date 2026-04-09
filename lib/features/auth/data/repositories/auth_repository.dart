import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/profile.dart';

class AuthRepository {
  final SupabaseClient _client;

  const AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> sendOtp(String email) async {
    await _client.auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  Future<User?> verifyOtp(String email, String token) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    return response.user;
  }

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  Future<Profile> upsertProfile(
    String userId, {
    String? displayName,
    String? username,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      'display_name': displayName,
      'username': username,
    }..removeWhere((_, v) => v == null);
    final response = await _client
        .from('profiles')
        .upsert(payload)
        .select()
        .single();
    return Profile.fromMap(response);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
