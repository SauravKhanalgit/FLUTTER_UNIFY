import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/models/auth_models.dart';

void main() {
  group('UnifiedUser', () {
    test('should create user with required fields', () {
      final user = UnifiedUser(
        id: '123',
        email: 'test@example.com',
        providers: [AuthProvider.emailPassword],
      );

      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(user.isAnonymous, isFalse);
    });

    test('should create anonymous user', () {
      final user = UnifiedUser(
        id: 'anon_123',
        providers: [AuthProvider.anonymous],
      );

      expect(user.isAnonymous, isTrue);
      expect(user.email, isNull);
    });

    test('should create user with all fields', () {
      final user = UnifiedUser(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        phoneNumber: '+1234567890',
        isEmailVerified: true,
        providers: [AuthProvider.google],
      );

      expect(user.displayName, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      expect(user.phoneNumber, equals('+1234567890'));
      expect(user.isEmailVerified, isTrue);
      expect(user.isAnonymous, isFalse);
    });
  });

  group('AuthResult', () {
    test('should create success result', () {
      final user = UnifiedUser(id: '123', email: 'test@example.com');
      final result = AuthResult.success(user);

      expect(result.success, isTrue);
      expect(result.user, equals(user));
      expect(result.error, isNull);
    });

    test('should create failure result', () {
      const error = 'Authentication failed';
      final result = const AuthResult.failure(error);

      expect(result.success, isFalse);
      expect(result.user, isNull);
      expect(result.error, equals(error));
    });
  });

  group('AuthProvider', () {
    test('should have all expected providers', () {
      expect(AuthProvider.values, contains(AuthProvider.google));
      expect(AuthProvider.values, contains(AuthProvider.apple));
      expect(AuthProvider.values, contains(AuthProvider.facebook));
      expect(AuthProvider.values, contains(AuthProvider.twitter));
      expect(AuthProvider.values, contains(AuthProvider.github));
      expect(AuthProvider.values, contains(AuthProvider.microsoft));
      expect(AuthProvider.values, contains(AuthProvider.anonymous));
      expect(AuthProvider.values.length, greaterThan(0));
    });
  });
}

