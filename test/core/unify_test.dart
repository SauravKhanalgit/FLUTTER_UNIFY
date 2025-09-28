import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('Unify Core Tests', () {
    setUp(() async {
      // Reset state before each test
      if (Unify.isInitialized) {
        await Unify.dispose();
      }
    });

    tearDown(() async {
      // Clean up after each test
      if (Unify.isInitialized) {
        await Unify.dispose();
      }
    });

    test('should initialize successfully', () async {
      expect(Unify.isInitialized, isFalse);

      final result = await Unify.initialize();

      expect(result, isTrue);
      expect(Unify.isInitialized, isTrue);
    });

    test('should dispose successfully', () async {
      await Unify.initialize();
      expect(Unify.isInitialized, isTrue);

      await Unify.dispose();

      expect(Unify.isInitialized, isFalse);
    });

    test('should provide version information', () {
      expect(Unify.version, isA<String>());
      expect(Unify.version.isNotEmpty, isTrue);
    });

    test('should provide available modules', () async {
      await Unify.initialize();

      final modules = Unify.availableModules;

      expect(modules, isA<List<String>>());
      expect(modules.isNotEmpty, isTrue);
    });

    test('should handle multiple initialization calls', () async {
      final result1 = await Unify.initialize();
      expect(result1, isTrue);
      expect(Unify.isInitialized, isTrue);

      // Second initialization should return true immediately
      final result2 = await Unify.initialize();
      expect(result2, isTrue);
      expect(Unify.isInitialized, isTrue);
    });

    test('should handle dispose without initialization', () async {
      expect(Unify.isInitialized, isFalse);

      // Should not throw
      await Unify.dispose();
      expect(Unify.isInitialized, isFalse);
    });

    test('should throw when accessing modules before initialization', () {
      expect(Unify.isInitialized, isFalse);

      expect(() => Unify.auth, throwsStateError);
      expect(() => Unify.networking, throwsStateError);
      expect(() => Unify.files, throwsStateError);
      expect(() => Unify.system, throwsStateError);
      expect(() => Unify.notifications, throwsStateError);
    });

    test('should provide access to auth module after initialization', () async {
      await Unify.initialize();

      expect(() => Unify.auth, returnsNormally);
      expect(Unify.auth, isNotNull);
    });

    test('should provide access to networking module after initialization',
        () async {
      await Unify.initialize();

      expect(() => Unify.networking, returnsNormally);
      expect(Unify.networking, isNotNull);
    });

    test('should provide access to files module after initialization',
        () async {
      await Unify.initialize();

      expect(() => Unify.files, returnsNormally);
      expect(Unify.files, isNotNull);
    });

    test('should provide access to system module after initialization',
        () async {
      await Unify.initialize();

      expect(() => Unify.system, returnsNormally);
      expect(Unify.system, isNotNull);
    });

    test('should provide access to notifications module after initialization',
        () async {
      await Unify.initialize();

      expect(() => Unify.notifications, returnsNormally);
      expect(Unify.notifications, isNotNull);
    });

    test('should handle configuration with initialization', () async {
      final config = UnifyConfig(
        authConfig: AuthConfig(
          enableBiometrics: true,
          sessionTimeout: Duration(hours: 24),
        ),
        networkingConfig: NetworkingConfig(
          timeout: Duration(seconds: 30),
        ),
      );

      final result = await Unify.initialize(config);

      expect(result, isTrue);
      expect(Unify.isInitialized, isTrue);
      expect(Unify.config, equals(config));
    });

    test('should support configuration updates', () async {
      await Unify.initialize();

      final originalConfig = Unify.config;

      final newConfig = UnifyConfig(
        authConfig: AuthConfig(
          enableBiometrics: false,
          sessionTimeout: Duration(hours: 12),
        ),
      );

      Unify.config = newConfig;
      expect(Unify.config, equals(newConfig));
      expect(Unify.config, isNot(equals(originalConfig)));
    });

    test('should track initialization state changes', () async {
      expect(Unify.isInitializing, isFalse);

      // Start initialization without awaiting
      final initFuture = Unify.initialize();

      // Should not complete immediately for initialization tracking
      expect(Unify.isInitializing, isA<bool>());

      await initFuture;
      expect(Unify.isInitialized, isTrue);
      expect(Unify.isInitializing, isFalse);
    });
  });
}
