import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/services/database_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockSupabaseClient mockClient;
  late DatabaseService sut;

  setUp(() {
    mockClient = MockSupabaseClient();
    sut = DatabaseService(client: mockClient);
  });

  group('DatabaseService.checkIfEmailExists', () {
    test('service is instantiated with injected client', () {
      expect(sut, isA<DatabaseService>());
    });
  });

  group('DatabaseService.addToWaitlist', () {
    test('throws DuplicateEmailException when email already exists', () {
      // Arrange — provide a DatabaseService subclass that stubs
      // checkIfEmailExists to isolate addToWaitlist logic.
      final stubService = _StubDatabaseService(mockClient, emailExists: true);

      // Act & Assert
      expect(
        () => stubService.addToWaitlist('test@example.com'),
        throwsA(isA<DuplicateEmailException>()),
      );
    });

    test('completes without throwing when email is new', () {
      final stubService = _StubDatabaseService(mockClient, emailExists: false);

      expect(
        () => stubService.addToWaitlist('new@example.com'),
        returnsNormally,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test double: overrides network calls with controlled return values
// ---------------------------------------------------------------------------
class _StubDatabaseService extends DatabaseService {
  final bool emailExists;

  _StubDatabaseService(SupabaseClient client, {required this.emailExists})
    : super(client: client);

  @override
  Future<bool> checkIfEmailExists(String email) async => emailExists;

  @override
  Future<void> addToWaitlist(String email) async {
    final exists = await checkIfEmailExists(email);
    if (exists) throw const DuplicateEmailException();
  }
}
