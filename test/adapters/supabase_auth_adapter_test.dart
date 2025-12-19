import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('SupabaseAuthAdapter', () {
    late SupabaseAuthAdapter adapter;

    setUp(() {
      adapter = SupabaseAuthAdapter();
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test('should initialize successfully', () async {
      final result = await adapter.initialize();
      expect(result, isTrue);
      expect(adapter.name, 'SupabaseAuthAdapter');
    });

    test('should support multiple auth providers', () {
      expect(adapter.supportedProviders, isNotEmpty);
      expect(adapter.supportedProviders, contains(AuthProvider.emailPassword));
      expect(adapter.supportedProviders, contains(AuthProvider.google));
    });

    test('should sign in with email and password', () async {
      await adapter.initialize();
      
      final result = await adapter.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user?.email, 'test@example.com');
    });

    test('should sign in anonymously', () async {
      await adapter.initialize();
      
      final result = await adapter.signInAnonymously();

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user?.isAnonymous, isTrue);
    });

    test('should sign out', () async {
      await adapter.initialize();
      await adapter.signInAnonymously();
      
      final result = await adapter.signOut();
      
      expect(result, isTrue);
      expect(adapter.currentUser, isNull);
    });

    test('should create user with email and password', () async {
      await adapter.initialize();
      
      final result = await adapter.createUserWithEmailAndPassword(
        'newuser@example.com',
        'password123',
      );

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user?.email, 'newuser@example.com');
    });

    test('should update profile', () async {
      await adapter.initialize();
      await adapter.signInAnonymously();
      
      final result = await adapter.updateProfile(
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
      );

      expect(result.success, isTrue);
      expect(result.user?.displayName, 'Test User');
    });

    test('should send password reset email', () async {
      await adapter.initialize();
      
      final result = await adapter.sendPasswordResetEmail('test@example.com');
      
      expect(result, isTrue);
    });

    test('should convert errors to user-friendly messages', () {
      final error1 = adapter.convertError('invalid_credentials');
      expect(error1, contains('Invalid email or password'));

      final error2 = adapter.convertError('email_not_confirmed');
      expect(error2, contains('verify your email'));

      final error3 = adapter.convertError('user_already_registered');
      expect(error3, contains('already exists'));
    });

    test('should identify recoverable errors', () {
      expect(adapter.isRecoverableError('network_error'), isTrue);
      expect(adapter.isRecoverableError('timeout'), isTrue);
      expect(adapter.isRecoverableError('unavailable'), isTrue);
      expect(adapter.isRecoverableError('invalid_credentials'), isFalse);
    });

    test('should get configuration', () {
      final config = adapter.getConfiguration();
      expect(config['adapter'], 'SupabaseAuthAdapter');
      expect(config['version'], '1.0.0');
    });
  });
}

