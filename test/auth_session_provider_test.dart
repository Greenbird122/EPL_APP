import 'package:flutter_test/flutter_test.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';

void main() {
  group('AuthSession', () {
    test('maps storage values to explicit session states', () {
      expect(AuthSession.fromStorage('demo').status, AuthSessionStatus.demo);
      expect(
          AuthSession.fromStorage('mother').status, AuthSessionStatus.mother);
      expect(
        AuthSession.fromStorage('provider').status,
        AuthSessionStatus.provider,
      );
      expect(
        AuthSession.fromStorage('unknown').status,
        AuthSessionStatus.signedOut,
      );
    });

    test('knows logged-in and provider states', () {
      expect(const AuthSession.demo().isLoggedIn, isTrue);
      expect(const AuthSession.mother().isLoggedIn, isTrue);
      expect(const AuthSession.provider().isProvider, isTrue);
      expect(const AuthSession.signedOut().isLoggedIn, isFalse);
    });
  });
}
