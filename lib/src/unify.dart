import 'dart:async';
import 'package:flutter/foundation.dart';

import 'common/platform_detector.dart';
import 'common/capability_detector.dart';
import 'web/web_optimizer.dart';
import 'desktop/desktop_manager.dart';
import 'mobile/mobile_manager.dart';
import 'system/system_manager.dart';

/// The main Unify API - single entry point for all platform capabilities
class Unify {
  static Unify? _instance;
  static Unify get instance => _instance ??= Unify._();

  Unify._();

  bool _isInitialized = false;

  /// Check if Unify is initialized
  static bool get isInitialized => instance._isInitialized;

  /// Platform detection utilities
  static PlatformDetector get platform => PlatformDetector.instance;

  /// Capability detection utilities
  static CapabilityDetector get capabilities => CapabilityDetector.instance;

  // Platform-specific managers
  static WebOptimizer? _webManager;
  static DesktopManager? _desktopManager;
  static MobileManager? _mobileManager;
  static SystemManager? _systemManager;

  /// Web-specific APIs (available only on web)
  static WebOptimizer get web {
    if (!kIsWeb) {
      throw UnsupportedError('Web APIs are only available on web platform');
    }
    return _webManager ??= WebOptimizer.instance;
  }

  /// Desktop-specific APIs (available only on desktop)
  static DesktopManager get desktop {
    if (!PlatformDetector.isDesktop) {
      throw UnsupportedError(
          'Desktop APIs are only available on desktop platforms');
    }
    return _desktopManager ??= DesktopManager.instance;
  }

  /// Mobile-specific APIs (available only on mobile)
  static MobileManager get mobile {
    if (!PlatformDetector.isMobile) {
      throw UnsupportedError(
          'Mobile APIs are only available on mobile platforms');
    }
    return _mobileManager ??= MobileManager.instance;
  }

  /// Cross-platform system APIs (available on all platforms)
  static SystemManager get system => _systemManager ??= SystemManager.instance;

  /// Initialize Unify with automatic platform detection
  static Future<void> initialize({
    // Web options
    bool enableSmartBundling = true,
    bool enableSEO = true,
    bool enableProgressiveLoading = false,
    bool enablePolyfills = true,
    // Desktop options
    bool enableSystemTray = true,
    bool enableGlobalShortcuts = true,
    bool enableDragDrop = true,
    bool enableWindowManager = true,
    // Mobile options
    bool enableNativeBridge = true,
    bool enableDeviceInfo = true,
    bool enableMobileServices = true,
    // System options
    bool enableClipboard = true,
    bool enableNotifications = true,
  }) async {
    if (instance._isInitialized) {
      if (kDebugMode) {
        print('Unify: Already initialized');
      }
      return;
    }

    // Initialize capability detection
    await CapabilityDetector.instance.initialize();

    // Initialize system manager (always available)
    await system.initialize(
      enableClipboard: enableClipboard,
      enableNotifications: enableNotifications,
    );

    // Initialize platform-specific managers
    if (kIsWeb) {
      await web.initialize(
        enableSmartBundling: enableSmartBundling,
        enableSEO: enableSEO,
        enableProgressiveLoading: enableProgressiveLoading,
        enablePolyfills: enablePolyfills,
      );
    } else if (PlatformDetector.isDesktop) {
      await desktop.initialize(
        enableSystemTray: enableSystemTray,
        enableGlobalShortcuts: enableGlobalShortcuts,
        enableDragDrop: enableDragDrop,
        enableWindowManager: enableWindowManager,
      );
    } else if (PlatformDetector.isMobile) {
      await mobile.initialize(
        enableNativeBridge: enableNativeBridge,
        enableDeviceInfo: enableDeviceInfo,
        enableMobileServices: enableMobileServices,
      );
    }

    instance._isInitialized = true;

    if (kDebugMode) {
      print('Unify: Initialized for ${PlatformDetector.platformName} platform');
    }
  }

  /// Get platform-specific feature availability
  static Map<String, bool> getFeatureAvailability() {
    final features = <String, bool>{};

    // Web features
    if (kIsWeb) {
      features.addAll({
        'smartBundling': capabilities.supportsServiceWorker,
        'seo': true,
        'progressiveLoading': true,
        'polyfills': true,
      });
    }

    // Desktop features
    if (PlatformDetector.isDesktop) {
      features.addAll({
        'systemTray': capabilities.supportsSystemTray,
        'globalShortcuts': capabilities.supportsGlobalShortcuts,
        'dragDrop': capabilities.supportsDragDrop,
        'windowManager': capabilities.supportsWindowManagement,
      });
    }

    // Mobile features
    if (PlatformDetector.isMobile) {
      features.addAll({
        'nativeBridge': true,
        'deviceInfo': true,
        'mobileServices': true,
      });
    }

    // System features (available on all platforms)
    features.addAll({
      'clipboard': capabilities.supportsClipboard,
      'notifications': capabilities.supportsNotifications,
    });

    return features;
  }

  /// Check if a specific feature is available
  static bool isFeatureAvailable(String feature) {
    return getFeatureAvailability()[feature] ?? false;
  }

  /// Get runtime information about the current environment
  static Map<String, dynamic> getRuntimeInfo() {
    return {
      'platform': PlatformDetector.platformName,
      'isWeb': kIsWeb,
      'isDesktop': PlatformDetector.isDesktop,
      'isMobile': PlatformDetector.isMobile,
      'capabilities': capabilities.getAllCapabilities(),
      'availableFeatures': getFeatureAvailability(),
      'isInitialized': instance._isInitialized,
    };
  }

  /// Dispose of all resources
  static Future<void> dispose() async {
    if (!instance._isInitialized) return;

    // Dispose platform-specific managers
    if (_webManager != null) {
      await _webManager!.dispose();
      _webManager = null;
    }

    if (_desktopManager != null) {
      await _desktopManager!.dispose();
      _desktopManager = null;
    }

    if (_mobileManager != null) {
      await _mobileManager!.dispose();
      _mobileManager = null;
    }

    if (_systemManager != null) {
      await _systemManager!.dispose();
      _systemManager = null;
    }

    instance._isInitialized = false;

    if (kDebugMode) {
      print('Unify: Disposed all resources');
    }
  }
}
