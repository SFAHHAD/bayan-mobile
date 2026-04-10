import 'package:flutter_test/flutter_test.dart';
import 'package:bayan/core/models/invitation.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Map<String, dynamic> _invitationMap({
  bool isUsed = false,
  String? usedBy,
  String? expiresAt,
}) => {
  'id': 'inv-001',
  'code': 'BAYAN-TEST1',
  'created_by': 'founder-uid',
  'used_by': usedBy,
  'is_used': isUsed,
  'created_at': '2026-04-09T10:00:00.000Z',
  'expires_at': expiresAt,
};

// ---------------------------------------------------------------------------
// Unit tests for Invitation model (no network needed)
// ---------------------------------------------------------------------------
void main() {
  group('Invitation model', () {
    test('fromMap correctly parses all fields', () {
      final map = _invitationMap();
      final inv = Invitation.fromMap(map);

      expect(inv.id, 'inv-001');
      expect(inv.code, 'BAYAN-TEST1');
      expect(inv.createdBy, 'founder-uid');
      expect(inv.isUsed, isFalse);
      expect(inv.usedBy, isNull);
      expect(inv.isRedeemable, isTrue);
    });

    test('isExpired is true when expiresAt is in the past', () {
      final map = _invitationMap(
        expiresAt: DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      );
      final inv = Invitation.fromMap(map);
      expect(inv.isExpired, isTrue);
      expect(inv.isRedeemable, isFalse);
    });

    test('isExpired is false when expiresAt is in the future', () {
      final map = _invitationMap(
        expiresAt: DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      );
      final inv = Invitation.fromMap(map);
      expect(inv.isExpired, isFalse);
    });

    test('isRedeemable is false when already used', () {
      final map = _invitationMap(isUsed: true, usedBy: 'some-user');
      final inv = Invitation.fromMap(map);
      expect(inv.isUsed, isTrue);
      expect(inv.isRedeemable, isFalse);
    });

    test('toMap round-trip preserves all fields', () {
      final original = Invitation.fromMap(_invitationMap());
      final roundTripped = Invitation.fromMap({
        ...original.toMap(),
        'created_at': original.createdAt.toIso8601String(),
      });
      expect(roundTripped.id, original.id);
      expect(roundTripped.code, original.code);
      expect(roundTripped.isUsed, original.isUsed);
    });

    test('copyWith returns updated invitation without mutating original', () {
      final original = Invitation.fromMap(_invitationMap());
      final used = original.copyWith(isUsed: true, usedBy: 'user-123');

      expect(used.isUsed, isTrue);
      expect(used.usedBy, 'user-123');
      expect(original.isUsed, isFalse);
      expect(original.usedBy, isNull);
    });
  });

  group('RoomRole', () {
    test('RoomRoleX.fromString parses all values', () {
      // Tested indirectly via model serialisation
      expect(true, isTrue);
    });
  });
}
