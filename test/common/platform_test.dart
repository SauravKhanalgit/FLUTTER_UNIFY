import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('Flutter Unify Basic Tests', () {
    test('should export core components', () {
      expect(Unify, isNotNull);
      expect(UnifyConfig, isNotNull);
      expect(AuthResult, isNotNull);
      expect(UnifiedNotifications, isNotNull);
    });

    test('should provide version information', () {
      expect(Unify.version, isA<String>());
      expect(Unify.version.isNotEmpty, isTrue);
    });

    test('should handle initialization state', () {
      expect(Unify.isInitialized, isA<bool>());
      expect(Unify.isInitializing, isA<bool>());
    });

    test('should provide available modules before initialization', () {
      final modules = Unify.availableModules;
      expect(modules, isA<List<String>>());
    });
  });

  group('Configuration Tests', () {
    test('should create default configuration', () {
      final config = UnifyConfig();

      expect(config.enableDebugMode, isFalse);
      expect(config.enableOfflineSync, isTrue);
      expect(config.enableAnalytics, isFalse);
      expect(config.logLevel, UnifyLogLevel.info);
    });

    test('should create custom configuration', () {
      final config = UnifyConfig(
        enableDebugMode: true,
        enableAnalytics: true,
        logLevel: UnifyLogLevel.verbose,
      );

      expect(config.enableDebugMode, isTrue);
      expect(config.enableAnalytics, isTrue);
      expect(config.logLevel, UnifyLogLevel.verbose);
    });
  });
}
