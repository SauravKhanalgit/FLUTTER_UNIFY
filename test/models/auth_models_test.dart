import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/models/auth_models.dart';

void main() {
  group('Authentication Models Tests', () {
    group('AuthResult Tests', () {
      test('should create successful auth result', () {
        final user = UnifiedUser(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
        );
        final result = AuthResult.success(user);

        expect(result.success, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.user, isNotNull);
        expect(result.user!.id, 'test-id');
        expect(result.error, isNull);
      });

      test('should create error auth result', () {
        final result = AuthResult.failure(
          'Invalid credentials',
          errorCode: 'auth/invalid-credential',
        );

        expect(result.success, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.user, isNull);
        expect(result.error, 'Invalid credentials');
        expect(result.errorCode, 'auth/invalid-credential');
      });

      test('should provide meaningful string representation', () {
        final user = UnifiedUser(id: 'test', email: 'test@example.com');
        final successResult = AuthResult.success(user);
        final failureResult = AuthResult.failure('Test error');

        expect(successResult.toString(), contains('AuthResult.success'));
        expect(successResult.toString(), contains('test@example.com'));
        expect(failureResult.toString(), contains('AuthResult.failure'));
        expect(failureResult.toString(), contains('Test error'));
      });
    });

    group('UnifiedUser Tests', () {
      test('should create user with required fields', () {
        final user = UnifiedUser(
          id: 'user-123',
          email: 'user@example.com',
        );

        expect(user.id, 'user-123');
        expect(user.email, 'user@example.com');
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
        expect(user.isEmailVerified, isFalse);
        expect(user.isAnonymous, isTrue); // No providers = anonymous
        expect(user.metadata, isEmpty);
      });

      test('should create user with all fields', () {
        final metadata = {'role': 'admin', 'department': 'IT'};
        final user = UnifiedUser(
          id: 'user-123',
          email: 'admin@example.com',
          displayName: 'Admin User',
          photoUrl: 'https://example.com/avatar.png',
          phoneNumber: '+1234567890',
          isEmailVerified: true,
          isPhoneVerified: true,
          providers: [AuthProvider.emailPassword],
          metadata: metadata,
          createdAt: DateTime(2023, 1, 1),
          lastSignInAt: DateTime(2023, 12, 1),
        );

        expect(user.id, 'user-123');
        expect(user.email, 'admin@example.com');
        expect(user.displayName, 'Admin User');
        expect(user.photoUrl, 'https://example.com/avatar.png');
        expect(user.phoneNumber, '+1234567890');
        expect(user.isEmailVerified, isTrue);
        expect(user.isPhoneVerified, isTrue);
        expect(user.isAnonymous, isFalse);
        expect(user.metadata, metadata);
        expect(user.createdAt, DateTime(2023, 1, 1));
        expect(user.lastSignInAt, DateTime(2023, 12, 1));
      });

      test('should support copyWith functionality', () {
        final original = UnifiedUser(
          id: 'user-123',
          email: 'user@example.com',
          isEmailVerified: false,
        );

        final updated = original.copyWith(
          displayName: 'Updated Name',
          isEmailVerified: true,
        );

        expect(updated.id, 'user-123');
        expect(updated.email, 'user@example.com');
        expect(updated.displayName, 'Updated Name');
        expect(updated.isEmailVerified, isTrue);
      });

      test('should provide primary identifier', () {
        final userWithName = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
        );
        expect(userWithName.primaryIdentifier, 'Test User');

        final userWithEmail = UnifiedUser(
          id: 'user-2',
          email: 'test@example.com',
        );
        expect(userWithEmail.primaryIdentifier, 'test@example.com');

        final userWithPhone = UnifiedUser(
          id: 'user-3',
          phoneNumber: '+1234567890',
        );
        expect(userWithPhone.primaryIdentifier, '+1234567890');

        final userWithIdOnly = UnifiedUser(id: 'user-4');
        expect(userWithIdOnly.primaryIdentifier, 'user-4');
      });

      test('should implement equality correctly', () {
        final user1 = UnifiedUser(id: 'test', email: 'test@example.com');
        final user2 = UnifiedUser(id: 'test', email: 'different@example.com');
        final user3 = UnifiedUser(id: 'different', email: 'test@example.com');

        expect(user1, equals(user2)); // Same ID
        expect(user1, isNot(equals(user3))); // Different ID
        expect(user1.hashCode, equals(user2.hashCode));
      });
    });

    group('AuthProvider Tests', () {
      test('should have all auth providers', () {
        expect(AuthProvider.emailPassword, isNotNull);
        expect(AuthProvider.google, isNotNull);
        expect(AuthProvider.apple, isNotNull);
        expect(AuthProvider.facebook, isNotNull);
        expect(AuthProvider.twitter, isNotNull);
        expect(AuthProvider.github, isNotNull);
        expect(AuthProvider.microsoft, isNotNull);
        expect(AuthProvider.anonymous, isNotNull);
        expect(AuthProvider.phone, isNotNull);
        expect(AuthProvider.biometric, isNotNull);
        expect(AuthProvider.custom, isNotNull);
        expect(AuthProvider.sso, isNotNull);
      });

      test('should convert provider to string', () {
        expect(
            AuthProvider.emailPassword.toString(), contains('emailPassword'));
        expect(AuthProvider.google.toString(), contains('google'));
        expect(AuthProvider.anonymous.toString(), contains('anonymous'));
      });
    });
  });
}
