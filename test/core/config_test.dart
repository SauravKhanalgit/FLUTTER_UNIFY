import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/core/config/unify_config.dart';

void main() {
  group('UnifyConfig', () {
    test('should create default config', () {
      final config = UnifyConfig();
      expect(config.enableOfflineSync, isTrue); // Default is true
      expect(config.enableAnalytics, isFalse);
      expect(config.enableDebugMode, isFalse);
    });

    test('should create config with custom values', () {
      final config = UnifyConfig(
        enableOfflineSync: true,
        enableAnalytics: true,
        enableDebugMode: true,
      );
      expect(config.enableOfflineSync, isTrue);
      expect(config.enableAnalytics, isTrue);
      expect(config.enableDebugMode, isTrue);
    });

    test('should copy config with modifications', () {
      final original = UnifyConfig(enableOfflineSync: true);
      final copied = original.copyWith(enableAnalytics: true);
      
      expect(copied.enableOfflineSync, isTrue);
      expect(copied.enableAnalytics, isTrue);
      expect(original.enableAnalytics, isFalse);
    });
  });
}

