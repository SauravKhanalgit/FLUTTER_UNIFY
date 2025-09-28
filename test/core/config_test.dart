import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('UnifyConfig Tests', () {
    test('should create default configuration', () {
      final config = UnifyConfig();

      expect(config.enableDebugMode, isFalse);
      expect(config.enableOfflineSync, isTrue);
      expect(config.enableAnalytics, isFalse);
      expect(config.enablePerformanceMonitoring, isTrue);
      expect(config.enableDevTools, isTrue);
      expect(config.logLevel, UnifyLogLevel.info);
    });

    test('should create custom configuration', () {
      final config = UnifyConfig(
        enableDebugMode: true,
        enableOfflineSync: false,
        enableAnalytics: true,
        logLevel: UnifyLogLevel.debug,
      );

      expect(config.enableDebugMode, isTrue);
      expect(config.enableOfflineSync, isFalse);
      expect(config.enableAnalytics, isTrue);
      expect(config.logLevel, UnifyLogLevel.debug);
    });

    test('should support copyWith functionality', () {
      final original = UnifyConfig(
        enableDebugMode: false,
        enableAnalytics: false,
      );

      final updated = original.copyWith(
        enableDebugMode: true,
        logLevel: UnifyLogLevel.verbose,
      );

      expect(updated.enableDebugMode, isTrue);
      expect(updated.enableAnalytics, isFalse); // Should remain unchanged
      expect(updated.logLevel, UnifyLogLevel.verbose);
    });

    group('AuthConfig Tests', () {
      test('should create default auth configuration', () {
        final config = AuthConfig();

        expect(config.enableBiometrics, isTrue);
        expect(config.enableRememberMe, isTrue);
        expect(config.sessionTimeout, Duration(days: 30));
        expect(config.maxLoginAttempts, 5);
        expect(config.enableMultiFactorAuth, isFalse);
        expect(config.enableSocialLogin, isTrue);
        expect(config.enableAnonymousAuth, isTrue);
        expect(config.autoRefreshTokens, isTrue);
        expect(config.enableOfflineAuth, isTrue);
      });

      test('should create custom auth configuration', () {
        final config = AuthConfig(
          enableBiometrics: false,
          sessionTimeout: Duration(hours: 2),
          maxLoginAttempts: 3,
          enableMultiFactorAuth: true,
        );

        expect(config.enableBiometrics, isFalse);
        expect(config.sessionTimeout, Duration(hours: 2));
        expect(config.maxLoginAttempts, 3);
        expect(config.enableMultiFactorAuth, isTrue);
      });
    });

    group('NetworkingConfig Tests', () {
      test('should create default networking configuration', () {
        final config = NetworkingConfig();

        expect(config.timeout, Duration(seconds: 30));
        expect(config.maxRetries, 3);
        expect(config.enableOfflineQueue, isTrue);
        expect(config.enableCaching, isTrue);
        expect(config.enableCompression, isTrue);
        expect(config.enableMetrics, isTrue);
      });

      test('should create custom networking configuration', () {
        final config = NetworkingConfig(
          timeout: Duration(seconds: 60),
          maxRetries: 5,
          enableOfflineQueue: false,
        );

        expect(config.timeout, Duration(seconds: 60));
        expect(config.maxRetries, 5);
        expect(config.enableOfflineQueue, isFalse);
      });
    });

    group('StorageConfig Tests', () {
      test('should create default storage configuration', () {
        final config = StorageConfig();

        expect(config.enableEncryption, isTrue);
        expect(config.maxCacheSize, Size.megabytes(100));
        expect(config.enableCompression, isTrue);
        expect(config.enableBackup, isTrue);
        expect(config.enableSync, isTrue);
        expect(config.cleanupInterval, Duration(days: 7));
      });

      test('should create custom storage configuration', () {
        final config = StorageConfig(
          enableEncryption: false,
          maxCacheSize: Size.megabytes(50),
          cleanupInterval: Duration(days: 3),
        );

        expect(config.enableEncryption, isFalse);
        expect(config.maxCacheSize.megabytes, 50);
        expect(config.cleanupInterval, Duration(days: 3));
      });
    });

    group('Size Utility Tests', () {
      test('should create sizes in different units', () {
        final bytes = Size.bytes(1024);
        final kb = Size.kilobytes(1);
        final mb = Size.megabytes(1);
        final gb = Size.gigabytes(1);

        expect(bytes.bytes, 1024);
        expect(kb.bytes, 1024);
        expect(mb.bytes, 1024 * 1024);
        expect(gb.bytes, 1024 * 1024 * 1024);
      });

      test('should convert between units correctly', () {
        final size = Size.megabytes(1);

        expect(size.bytes, 1024 * 1024);
        expect(size.kilobytes, 1024);
        expect(size.megabytes, 1);
        expect(size.gigabytes, 1 / 1024);
      });

      test('should provide meaningful string representation', () {
        expect(Size.bytes(512).toString(), '512 bytes');
        expect(Size.kilobytes(1).toString(), '1.0 KB');
        expect(Size.megabytes(1).toString(), '1.0 MB');
        expect(Size.gigabytes(1).toString(), '1.0 GB');
      });
    });

    group('Enum Tests', () {
      test('should have all log levels', () {
        expect(UnifyLogLevel.none, isNotNull);
        expect(UnifyLogLevel.error, isNotNull);
        expect(UnifyLogLevel.warning, isNotNull);
        expect(UnifyLogLevel.info, isNotNull);
        expect(UnifyLogLevel.debug, isNotNull);
        expect(UnifyLogLevel.verbose, isNotNull);
      });

      test('should have all encryption levels', () {
        expect(EncryptionLevel.none, isNotNull);
        expect(EncryptionLevel.basic, isNotNull);
        expect(EncryptionLevel.aes128, isNotNull);
        expect(EncryptionLevel.aes256, isNotNull);
        expect(EncryptionLevel.military, isNotNull);
      });
    });

    group('Security Config Tests', () {
      test('should create default security configuration', () {
        final config = SecurityConfig();

        expect(config.enableEncryption, isTrue);
        expect(config.enableCertificatePinning, isFalse);
        expect(config.enableTamperDetection, isFalse);
        expect(config.enableSecureStorage, isTrue);
        expect(config.enableBiometricAuth, isTrue);
        expect(config.encryptionLevel, EncryptionLevel.aes256);
      });

      test('should create custom security configuration', () {
        final config = SecurityConfig(
          enableCertificatePinning: true,
          enableTamperDetection: true,
          encryptionLevel: EncryptionLevel.military,
        );

        expect(config.enableCertificatePinning, isTrue);
        expect(config.enableTamperDetection, isTrue);
        expect(config.encryptionLevel, EncryptionLevel.military);
      });
    });

    group('Platform-Specific Config Tests', () {
      test('should create desktop configuration', () {
        final config = DesktopConfig(
          enableSystemTray: false,
          enableAutoStart: true,
        );

        expect(config.enableSystemTray, isFalse);
        expect(config.enableAutoStart, isTrue);
        expect(config.enableGlobalShortcuts, isTrue); // default
      });

      test('should create web configuration', () {
        final config = WebConfig(
          enableSEO: false,
          enableWebAssembly: true,
        );

        expect(config.enableSEO, isFalse);
        expect(config.enableWebAssembly, isTrue);
        expect(config.enableServiceWorker, isTrue); // default
      });

      test('should create mobile configuration', () {
        final config = MobileConfig(
          enableHaptics: false,
          enableBatteryOptimization: false,
        );

        expect(config.enableHaptics, isFalse);
        expect(config.enableBatteryOptimization, isFalse);
        expect(config.enableDeepLinking, isTrue); // default
      });
    });
  });
}
