import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sakina_ac/admin_access.dart';

class _MockUser extends Mock implements User {
  @override
  String? email;

  @override
  bool emailVerified;

  _MockUser({required this.email, required this.emailVerified});
}

void main() {
  group('isSakinaAdminEmail', () {
    test('allows configured admin email case-insensitively', () {
      expect(isSakinaAdminEmail('Payefatou97@gmail.com'), isTrue);
    });

    test('rejects an email not configured as admin', () {
      expect(isSakinaAdminEmail('student@example.com'), isFalse);
    });

    test('rejects a missing email', () {
      expect(isSakinaAdminEmail(null), isFalse);
    });
  });

  group('isSakinaAdmin', () {
    test('allows a verified authorized admin email case-insensitively', () {
      final user = _MockUser(
        email: 'Payefatou97@gmail.com',
        emailVerified: true,
      );

      expect(isSakinaAdmin(user), isTrue);
    });

    test('rejects an authorized address until its email is verified', () {
      final user = _MockUser(
        email: 'adamambacke19@gmail.com',
        emailVerified: false,
      );

      expect(isSakinaAdmin(user), isFalse);
    });

    test('rejects a verified account not listed as an admin', () {
      final user = _MockUser(
        email: 'student@example.com',
        emailVerified: true,
      );

      expect(isSakinaAdmin(user), isFalse);
    });

    test('rejects an unauthenticated user', () {
      expect(isSakinaAdmin(null), isFalse);
    });
  });
}
