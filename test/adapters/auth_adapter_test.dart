import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/adapters/auth_adapter.dart';
import 'package:flutter_unify/src/models/auth_models.dart';

void main() {
  group('MockAuthAdapter', () {
    late MockAuthAdapter adapter;

    setUp(() {
      adapter = MockAuthAdapter();
    });

    test('should initialize', () async {
      final result = await adapter.initialize();
      expect(result, isTrue);
    });

    test('should have correct name and version', () {
      expect(adapter.name, equals('MockAuthAdapter'));
      expect(adapter.version, equals('1.0.0'));
    });

    test('should support all providers', () {
      expect(adapter.supportedProviders, containsAll(AuthProvider.values));
    });

    test('should sign in anonymously', () async {
      await adapter.initialize();
      final result = await adapter.signInAnonymously();
      
      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user?.isAnonymous, isTrue);
    });

    test('should sign in with email and password', () async {
      await adapter.initialize();
      final result = await adapter.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );
      
      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user?.email, equals('test@example.com'));
    });

    test('should handle failed authentication', () async {
      final failingAdapter = MockAuthAdapter(shouldSucceed: false);
      await failingAdapter.initialize();
      
      final result = await failingAdapter.signInWithEmailAndPassword(
        'test@example.com',
        'wrong',
      );
      
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should sign out', () async {
      await adapter.initialize();
      await adapter.signInAnonymously();
      
      await adapter.signOut();
      // MockAuthAdapter doesn't expose getCurrentUser directly
      // Check via auth state stream instead
      final subscription = adapter.onAuthStateChanged.listen((event) {
        expect(event.user, isNull);
      });
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();
    });

    test('should emit auth state changes', () async {
      await adapter.initialize();
      
      var stateChanges = <AuthStateChangeEvent>[];
      final subscription = adapter.onAuthStateChanged.listen((event) {
        stateChanges.add(event);
      });

      await adapter.signInAnonymously();
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(stateChanges.length, greaterThan(0));
      expect(stateChanges.last.user, isNotNull);
      
      await subscription.cancel();
    });

    tearDown(() async {
      await adapter.dispose();
    });
  });
}

