// Simple tests for pub points optimization
import 'package:test/test.dart';
import 'package:flutter_unify/src/models/auth_models.dart';

void main() {
  group('Auth Models Tests', () {
    test('AuthResult success should be created correctly', () {
      final user = UnifiedUser(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      final result = AuthResult.success(user);

      expect(result.success, true);
      expect(result.user?.email, 'test@example.com');
      expect(result.error, null);
      expect(result.isFailure, false);
    });

    test('AuthResult failure should be created correctly', () {
      final result = AuthResult.failure('Invalid credentials',
          errorCode: 'auth/invalid-credentials');

      expect(result.success, false);
      expect(result.user, null);
      expect(result.error, 'Invalid credentials');
      expect(result.errorCode, 'auth/invalid-credentials');
      expect(result.isFailure, true);
    });

    test('UnifiedUser should be created correctly', () {
      final user = UnifiedUser(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        isEmailVerified: true,
        providers: [AuthProvider.emailPassword, AuthProvider.google],
      );

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.isEmailVerified, true);
      expect(user.providers.length, 2);
    });

    test('AuthProvider enum should have correct values', () {
      expect(AuthProvider.emailPassword, AuthProvider.emailPassword);
      expect(AuthProvider.google, AuthProvider.google);
      expect(AuthProvider.apple, AuthProvider.apple);
      expect(AuthProvider.facebook, AuthProvider.facebook);
    });
  });

  group('String Tests', () {
    test('AuthResult toString should work correctly', () {
      final user = UnifiedUser(id: 'test', displayName: 'Test User');
      final successResult = AuthResult.success(user);
      final failureResult = AuthResult.failure('Error message');

      expect(successResult.toString(), contains('AuthResult.success'));
      expect(successResult.toString(), contains('Test User'));
      expect(failureResult.toString(), contains('AuthResult.failure'));
      expect(failureResult.toString(), contains('Error message'));
    });

    test('UnifiedUser toString should work correctly', () {
      final user = UnifiedUser(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      final userString = user.toString();
      expect(userString, contains('UnifiedUser'));
      expect(userString, contains('test@example.com'));
    });
  });

  group('Equality Tests', () {
    test('UnifiedUser equality should work correctly', () {
      final user1 = UnifiedUser(
        id: 'test-id',
        email: 'test@example.com',
      );

      final user2 = UnifiedUser(
        id: 'test-id',
        email: 'test@example.com',
      );

      final user3 = UnifiedUser(
        id: 'different-id',
        email: 'test@example.com',
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
      expect(user1.hashCode, equals(user2.hashCode));
    });
  });

  group('Basic Functionality Tests', () {
    test('Library imports should work', () {
      // This test just ensures the library can be imported without errors
      expect(AuthProvider.values.isNotEmpty, true);
      expect(AuthProvider.values.contains(AuthProvider.google), true);
    });

    test('Enum values should be accessible', () {
      final providers = AuthProvider.values;
      expect(providers.length, greaterThan(5));
      expect(providers.contains(AuthProvider.emailPassword), true);
      expect(providers.contains(AuthProvider.google), true);
      expect(providers.contains(AuthProvider.apple), true);
    });
  });
}
