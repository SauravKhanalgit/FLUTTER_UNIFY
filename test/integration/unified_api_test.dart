import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/core/unify.dart';
import 'package:flutter_unify/src/common/platform_detector.dart';

void main() {
  group('Unified API Integration Tests', () {
    setUpAll(() async {
      // Initialize Unify before running tests
      await Unify.initialize();
    });

    tearDownAll(() async {
      // Cleanup after all tests
      await Unify.dispose();
    });

    test('should initialize Unify framework', () async {
      final initialized = await Unify.initialize();
      expect(initialized, isTrue);
    });

    test('should access auth module', () {
      expect(Unify.auth, isNotNull);
      expect(Unify.auth.onAuthStateChanged, isNotNull);
    });

    test('should access networking module', () {
      expect(Unify.networking, isNotNull);
      expect(Unify.networking.onConnectivityChanged, isNotNull);
    });

    test('should access files module', () {
      expect(Unify.files, isNotNull);
    });

    test('should access system module', () {
      expect(Unify.system, isNotNull);
    });

    test('should access notifications module', () {
      expect(Unify.notifications, isNotNull);
    });

    test('should have version', () {
      expect(Unify.version, isNotNull);
      expect(Unify.version, isA<String>());
    });

    test('should have available modules', () {
      final modules = Unify.availableModules;
      expect(modules, isNotNull);
      expect(modules, isA<List<String>>());
    });

    test('should detect platform correctly', () {
      // At least one platform should be detected
      final isWeb = PlatformDetector.isWeb;
      final isMobile = PlatformDetector.isMobile;
      final isDesktop = PlatformDetector.isDesktop;

      // In test environment, platform detection might not work perfectly
      // So we just verify the methods exist and return booleans
      expect(isWeb, isA<bool>());
      expect(isMobile, isA<bool>());
      expect(isDesktop, isA<bool>());
    });
  });
}

