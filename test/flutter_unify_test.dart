import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('Flutter Unify Core Tests', () {
    test('package exports are accessible', () {
      // Test that main exports are available
      expect(Unify, isNotNull);
      expect(PlatformDetector, isNotNull);
      expect(CapabilityDetector, isNotNull);
    });

    test('platform detection works', () {
      // These should not throw
      expect(() => PlatformDetector.isWeb, returnsNormally);
      expect(() => PlatformDetector.isDesktop, returnsNormally);
      expect(() => PlatformDetector.isMobile, returnsNormally);
      expect(() => PlatformDetector.isAndroid, returnsNormally);
      expect(() => PlatformDetector.isIOS, returnsNormally);
      expect(() => PlatformDetector.isLinux, returnsNormally);
      expect(() => PlatformDetector.isMacOS, returnsNormally);
      expect(() => PlatformDetector.isWindows, returnsNormally);

      // Platform name should be a string
      expect(PlatformDetector.platformName, isA<String>());
      expect(PlatformDetector.platformName.isNotEmpty, isTrue);
    });

    test('capability detection works', () {
      final detector = CapabilityDetector.instance;

      // These should not throw
      expect(() => detector.supportsClipboard, returnsNormally);
      expect(() => detector.supportsNotifications, returnsNormally);
      expect(() => detector.supportsDragDrop, returnsNormally);
      expect(() => detector.supportsSystemTray, returnsNormally);
      expect(() => detector.supportsWindowManagement, returnsNormally);

      // Should return capabilities map
      final capabilities = detector.getAllCapabilities();
      expect(capabilities, isA<Map<String, bool>>());
      expect(capabilities.isNotEmpty, isTrue);
    });

    test('unify initialization works', () async {
      // Should not throw during initialization
      expect(() async => await Unify.initialize(), returnsNormally);

      // After initialization, should be marked as initialized
      await Unify.initialize();
      expect(Unify.isInitialized, isTrue);

      // Should provide runtime info
      final info = Unify.getRuntimeInfo();
      expect(info, isA<Map<String, dynamic>>());
      expect(info['isInitialized'], isTrue);
      expect(info['platform'], isA<String>());
    });

    test('platform managers are accessible when supported', () {
      // Test that managers can be accessed without throwing
      // Note: These may throw UnsupportedError on unsupported platforms, which is expected
      expect(() => Unify.system, returnsNormally);

      // On supported platforms, should not throw
      if (kIsWeb) {
        expect(() => Unify.web, returnsNormally);
      }
      if (PlatformDetector.isDesktop) {
        expect(() => Unify.desktop, returnsNormally);
      }
      if (PlatformDetector.isMobile) {
        expect(() => Unify.mobile, returnsNormally);
      }
    });

    test('feature availability works correctly', () {
      final features = Unify.getFeatureAvailability();
      expect(features, isA<Map<String, bool>>());

      // Should have expected feature keys
      expect(features.containsKey('web'), isTrue);
      expect(features.containsKey('desktop'), isTrue);
      expect(features.containsKey('mobile'), isTrue);
      expect(features.containsKey('system'), isTrue);
    });

    test('dispose works properly', () async {
      await Unify.initialize();
      expect(Unify.isInitialized, isTrue);

      // Should dispose without error
      expect(() async => await Unify.dispose(), returnsNormally);
      await Unify.dispose();

      expect(Unify.isInitialized, isFalse);
    });
  });

  group('Platform Specific Manager Tests', () {
    setUp(() async {
      await Unify.initialize();
    });

    tearDown(() async {
      await Unify.dispose();
    });

    test('web manager provides expected interface', () {
      if (!kIsWeb) return; // Skip on non-web platforms

      final web = Unify.web;

      // Should have web-specific properties
      expect(() => web.seo, returnsNormally);
      expect(() => web.progressiveLoader, returnsNormally);
      expect(() => web.polyfills, returnsNormally);
      expect(() => web.isInitialized, returnsNormally);
    });

    test('desktop manager provides expected interface', () {
      if (!PlatformDetector.isDesktop) return; // Skip on non-desktop platforms

      final desktop = Unify.desktop;

      // Should have desktop-specific properties
      expect(() => desktop.systemTray, returnsNormally);
      expect(() => desktop.windowManager, returnsNormally);
      expect(() => desktop.dragDrop, returnsNormally);
      expect(() => desktop.shortcuts, returnsNormally);
      expect(() => desktop.systemServices, returnsNormally);
    });

    test('mobile manager provides expected interface', () {
      if (!PlatformDetector.isMobile) return; // Skip on non-mobile platforms

      final mobile = Unify.mobile;

      // Should have mobile-specific properties
      expect(() => mobile.nativeBridge, returnsNormally);
      expect(() => mobile.deviceInfo, returnsNormally);
      expect(() => mobile.services, returnsNormally);
    });

    test('system manager provides expected interface', () {
      final system = Unify.system;

      // Should have system-specific methods
      expect(() => system.clipboardWriteText('test'), returnsNormally);
      expect(() => system.clipboardReadText(), returnsNormally);
      expect(() => system.showNotification(title: 'Test', body: 'Message'),
          returnsNormally);
    });
  });
}
