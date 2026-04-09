import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/features/auth/data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    repo = AuthRepository(mockClient);
  });

  group('AuthRepository', () {
    test('currentUser delegates to client.auth.currentUser', () {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(repo.currentUser, mockUser);
      verify(() => mockAuth.currentUser).called(1);
    });

    test('currentUser returns null when not authenticated', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(repo.currentUser, isNull);
    });

    test('authStateChanges exposes client.auth.onAuthStateChange', () {
      final stream = const Stream<AuthState>.empty();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => stream);

      expect(repo.authStateChanges, stream);
    });

    test('signOut calls client.auth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repo.signOut();
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
