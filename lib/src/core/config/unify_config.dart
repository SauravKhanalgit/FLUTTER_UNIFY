/// 🛠️ Flutter Unify Configuration
///
/// Central configuration system that allows developers to customize
/// behavior across all unified APIs. This is the control center
/// for your entire app's unified functionality.

import 'package:meta/meta.dart';

/// Main configuration class for Flutter Unify
///
/// This follows the same philosophy as BlocConfig - centralized
/// configuration that affects the entire system behavior.
///
/// Example:
/// ```dart
/// await Unify.initialize(
///   config: UnifyConfig(
///     enableOfflineSync: true,
///     enableAnalytics: false,
///     authConfig: AuthConfig(
///       enableBiometrics: true,
///       sessionTimeout: Duration(days: 30),
///     ),
///   ),
/// );
/// ```
@immutable
class UnifyConfig {
  const UnifyConfig({
    this.enableDebugMode = false,
    this.enableOfflineSync = true,
    this.enableAnalytics = false,
    this.enablePerformanceMonitoring = true,
    this.enableDevTools = true,
    this.logLevel = UnifyLogLevel.info,
    this.authConfig = const AuthConfig(),
    this.storageConfig = const StorageConfig(),
    this.networkingConfig = const NetworkingConfig(),
    this.notificationsConfig = const NotificationsConfig(),
    this.filesConfig = const FilesConfig(),
    this.systemConfig = const SystemConfig(),
    this.desktopConfig = const DesktopConfig(),
    this.webConfig = const WebConfig(),
    this.mobileConfig = const MobileConfig(),
    this.aiConfig = const AIConfig(),
    this.themingConfig = const ThemingConfig(),
    this.securityConfig = const SecurityConfig(),
    this.testingConfig = const TestingConfig(),
  });

  /// Enable debug mode for enhanced logging and development tools
  final bool enableDebugMode;

  /// Enable offline synchronization capabilities
  final bool enableOfflineSync;

  /// Enable analytics collection (respects user privacy)
  final bool enableAnalytics;

  /// Enable performance monitoring and metrics
  final bool enablePerformanceMonitoring;

  /// Enable DevTools integration
  final bool enableDevTools;

  /// Global log level for all Unify operations
  final UnifyLogLevel logLevel;

  /// Authentication module configuration
  final AuthConfig authConfig;

  /// Storage module configuration
  final StorageConfig storageConfig;

  /// Networking module configuration
  final NetworkingConfig networkingConfig;

  /// Notifications module configuration
  final NotificationsConfig notificationsConfig;

  /// Files module configuration
  final FilesConfig filesConfig;

  /// System monitoring configuration
  final SystemConfig systemConfig;

  /// Desktop-specific configuration
  final DesktopConfig desktopConfig;

  /// Web-specific configuration
  final WebConfig webConfig;

  /// Mobile-specific configuration
  final MobileConfig mobileConfig;

  /// AI integration configuration
  final AIConfig aiConfig;

  /// Theming system configuration
  final ThemingConfig themingConfig;

  /// Security configuration
  final SecurityConfig securityConfig;

  /// Testing configuration
  final TestingConfig testingConfig;

  /// Create a copy of this config with updated values
  UnifyConfig copyWith({
    bool? enableDebugMode,
    bool? enableOfflineSync,
    bool? enableAnalytics,
    bool? enablePerformanceMonitoring,
    bool? enableDevTools,
    UnifyLogLevel? logLevel,
    AuthConfig? authConfig,
    StorageConfig? storageConfig,
    NetworkingConfig? networkingConfig,
    NotificationsConfig? notificationsConfig,
    FilesConfig? filesConfig,
    SystemConfig? systemConfig,
    DesktopConfig? desktopConfig,
    WebConfig? webConfig,
    MobileConfig? mobileConfig,
    AIConfig? aiConfig,
    ThemingConfig? themingConfig,
    SecurityConfig? securityConfig,
    TestingConfig? testingConfig,
  }) {
    return UnifyConfig(
      enableDebugMode: enableDebugMode ?? this.enableDebugMode,
      enableOfflineSync: enableOfflineSync ?? this.enableOfflineSync,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enablePerformanceMonitoring:
          enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      enableDevTools: enableDevTools ?? this.enableDevTools,
      logLevel: logLevel ?? this.logLevel,
      authConfig: authConfig ?? this.authConfig,
      storageConfig: storageConfig ?? this.storageConfig,
      networkingConfig: networkingConfig ?? this.networkingConfig,
      notificationsConfig: notificationsConfig ?? this.notificationsConfig,
      filesConfig: filesConfig ?? this.filesConfig,
      systemConfig: systemConfig ?? this.systemConfig,
      desktopConfig: desktopConfig ?? this.desktopConfig,
      webConfig: webConfig ?? this.webConfig,
      mobileConfig: mobileConfig ?? this.mobileConfig,
      aiConfig: aiConfig ?? this.aiConfig,
      themingConfig: themingConfig ?? this.themingConfig,
      securityConfig: securityConfig ?? this.securityConfig,
      testingConfig: testingConfig ?? this.testingConfig,
    );
  }
}

/// Global log levels for Flutter Unify
enum UnifyLogLevel {
  /// No logging
  none,

  /// Error messages only
  error,

  /// Error and warning messages
  warning,

  /// Error, warning, and info messages
  info,

  /// All messages including debug
  debug,

  /// Everything including verbose internal details
  verbose,
}

/// Authentication module configuration
@immutable
class AuthConfig {
  const AuthConfig({
    this.enableBiometrics = true,
    this.enableRememberMe = true,
    this.persistSession = true,
    this.sessionTimeout = const Duration(days: 30),
    this.maxLoginAttempts = 5,
    this.enableMultiFactorAuth = false,
    this.enableSocialLogin = true,
    this.enableAnonymousAuth = true,
    this.autoRefreshTokens = true,
    this.enableOfflineAuth = true,
  });

  final bool enableBiometrics;
  final bool enableRememberMe;
  final bool persistSession;
  final Duration sessionTimeout;
  final int maxLoginAttempts;
  final bool enableMultiFactorAuth;
  final bool enableSocialLogin;
  final bool enableAnonymousAuth;
  final bool autoRefreshTokens;
  final bool enableOfflineAuth;
}

/// Storage module configuration
@immutable
class StorageConfig {
  const StorageConfig({
    this.enableEncryption = true,
    this.maxCacheSize = const Size.megabytes(100),
    this.enableCompression = true,
    this.enableBackup = true,
    this.enableSync = true,
    this.cleanupInterval = const Duration(days: 7),
  });

  final bool enableEncryption;
  final Size maxCacheSize;
  final bool enableCompression;
  final bool enableBackup;
  final bool enableSync;
  final Duration cleanupInterval;
}

/// Networking module configuration
@immutable
class NetworkingConfig {
  const NetworkingConfig({
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableOfflineQueue = true,
    this.enableCaching = true,
    this.enableCompression = true,
    this.enableMetrics = true,
    this.maxCacheSize = const Size.megabytes(50),
  });

  final Duration timeout;
  final int maxRetries;
  final bool enableOfflineQueue;
  final bool enableCaching;
  final bool enableCompression;
  final bool enableMetrics;
  final Size maxCacheSize;
}

/// Notifications module configuration
@immutable
class NotificationsConfig {
  const NotificationsConfig({
    this.enableLocalNotifications = true,
    this.enablePushNotifications = true,
    this.enableBadgeCount = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableAutoCancel = true,
    this.defaultChannelId = 'flutter_unify_default',
    this.defaultChannelName = 'Flutter Unify',
  });

  final bool enableLocalNotifications;
  final bool enablePushNotifications;
  final bool enableBadgeCount;
  final bool enableSound;
  final bool enableVibration;
  final bool enableAutoCancel;
  final String defaultChannelId;
  final String defaultChannelName;
}

/// Files module configuration
@immutable
class FilesConfig {
  const FilesConfig({
    this.enableBackgroundDownloads = true,
    this.enableProgressTracking = true,
    this.enableResumeDownloads = true,
    this.enableFileWatcher = true,
    this.maxConcurrentDownloads = 3,
    this.defaultDownloadPath,
  });

  final bool enableBackgroundDownloads;
  final bool enableProgressTracking;
  final bool enableResumeDownloads;
  final bool enableFileWatcher;
  final int maxConcurrentDownloads;
  final String? defaultDownloadPath;
}

/// System monitoring configuration
@immutable
class SystemConfig {
  const SystemConfig({
    this.enableBatteryMonitoring = true,
    this.enableConnectivityMonitoring = true,
    this.enableMemoryMonitoring = true,
    this.enablePerformanceMonitoring = true,
    this.monitoringInterval = const Duration(seconds: 30),
  });

  final bool enableBatteryMonitoring;
  final bool enableConnectivityMonitoring;
  final bool enableMemoryMonitoring;
  final bool enablePerformanceMonitoring;
  final Duration monitoringInterval;
}

/// Desktop-specific configuration
@immutable
class DesktopConfig {
  const DesktopConfig({
    this.enableSystemTray = true,
    this.enableGlobalShortcuts = true,
    this.enableWindowManagement = true,
    this.enableDragAndDrop = true,
    this.enableAutoStart = false,
    this.enableSystemIntegration = true,
  });

  final bool enableSystemTray;
  final bool enableGlobalShortcuts;
  final bool enableWindowManagement;
  final bool enableDragAndDrop;
  final bool enableAutoStart;
  final bool enableSystemIntegration;
}

/// Web-specific configuration
@immutable
class WebConfig {
  const WebConfig({
    this.enableSEO = true,
    this.enableServiceWorker = true,
    this.enableOfflineSupport = true,
    this.enableWebAssembly = false,
    this.enableProgressiveWebApp = true,
    this.enableWebShare = true,
  });

  final bool enableSEO;
  final bool enableServiceWorker;
  final bool enableOfflineSupport;
  final bool enableWebAssembly;
  final bool enableProgressiveWebApp;
  final bool enableWebShare;
}

/// Mobile-specific configuration
@immutable
class MobileConfig {
  const MobileConfig({
    this.enableDeepLinking = true,
    this.enableBiometrics = true,
    this.enableHaptics = true,
    this.enableBatteryOptimization = true,
    this.enableBackgroundProcessing = true,
  });

  final bool enableDeepLinking;
  final bool enableBiometrics;
  final bool enableHaptics;
  final bool enableBatteryOptimization;
  final bool enableBackgroundProcessing;
}

/// AI integration configuration
@immutable
class AIConfig {
  const AIConfig({
    this.enableSmartFeatures = false,
    this.enableMLKit = false,
    this.enableTextToSpeech = false,
    this.enableSpeechToText = false,
    this.enableImageRecognition = false,
    this.enablePredictiveText = false,
  });

  final bool enableSmartFeatures;
  final bool enableMLKit;
  final bool enableTextToSpeech;
  final bool enableSpeechToText;
  final bool enableImageRecognition;
  final bool enablePredictiveText;
}

/// Theming system configuration
@immutable
class ThemingConfig {
  const ThemingConfig({
    this.enableAdaptiveTheming = true,
    this.enableSystemTheme = true,
    this.enableColorExtraction = true,
    this.enableAnimatedTransitions = true,
    this.enableMaterial3 = true,
    this.enableCustomBranding = true,
  });

  final bool enableAdaptiveTheming;
  final bool enableSystemTheme;
  final bool enableColorExtraction;
  final bool enableAnimatedTransitions;
  final bool enableMaterial3;
  final bool enableCustomBranding;
}

/// Security configuration
@immutable
class SecurityConfig {
  const SecurityConfig({
    this.enableEncryption = true,
    this.enableCertificatePinning = false,
    this.enableTamperDetection = false,
    this.enableSecureStorage = true,
    this.enableBiometricAuth = true,
    this.encryptionLevel = EncryptionLevel.aes256,
  });

  final bool enableEncryption;
  final bool enableCertificatePinning;
  final bool enableTamperDetection;
  final bool enableSecureStorage;
  final bool enableBiometricAuth;
  final EncryptionLevel encryptionLevel;
}

/// Testing configuration
@immutable
class TestingConfig {
  const TestingConfig({
    this.enableMockAdapters = false,
    this.enableTestMode = false,
    this.enablePerformanceProfiling = false,
    this.enableIntegrationTesting = false,
    this.enableScreenshotTesting = false,
  });

  final bool enableMockAdapters;
  final bool enableTestMode;
  final bool enablePerformanceProfiling;
  final bool enableIntegrationTesting;
  final bool enableScreenshotTesting;
}

/// Data size utility class
@immutable
class Size {
  const Size.bytes(int bytes) : _bytes = bytes;
  const Size.kilobytes(int kb) : _bytes = kb * 1024;
  const Size.megabytes(int mb) : _bytes = mb * 1024 * 1024;
  const Size.gigabytes(int gb) : _bytes = gb * 1024 * 1024 * 1024;

  final int _bytes;

  int get bytes => _bytes;
  double get kilobytes => _bytes / 1024;
  double get megabytes => _bytes / (1024 * 1024);
  double get gigabytes => _bytes / (1024 * 1024 * 1024);

  @override
  String toString() {
    if (_bytes >= 1024 * 1024 * 1024) {
      return '${gigabytes.toStringAsFixed(1)} GB';
    } else if (_bytes >= 1024 * 1024) {
      return '${megabytes.toStringAsFixed(1)} MB';
    } else if (_bytes >= 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    } else {
      return '$_bytes bytes';
    }
  }
}

/// Encryption levels for security
enum EncryptionLevel {
  /// No encryption
  none,

  /// Basic encryption
  basic,

  /// AES-128 encryption
  aes128,

  /// AES-256 encryption (recommended)
  aes256,

  /// Military-grade encryption
  military,
}
