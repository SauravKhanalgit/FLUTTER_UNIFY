import 'dart:async';
import 'package:flutter/foundation.dart';

import 'common/platform_detector.dart';
import 'common/capability_detector.dart';
import 'web/web_optimizer.dart';
import 'desktop/desktop_manager.dart';
import 'mobile/mobile_manager.dart';
import 'system/system_manager.dart';
import 'analytics/analytics_adapter.dart';
import 'bridge/bridge_channel.dart';
import 'bridge/bridge_store.dart';
import 'bridge/hybrid_navigation.dart';
import 'media/media_core.dart';
import 'media/ar_adapter.dart';
import 'media/ml_pipeline.dart';
import 'background/background_scheduler.dart';
import 'desktop/device_bridge.dart';
import 'security/crypto_envelope.dart';
import 'security/privacy_toolkit.dart';
import 'security/anomaly_detector.dart';
import 'ai/modules/recommendation_engine.dart';
import 'ai/modules/chat_orchestrator.dart';
import 'ai/modules/predictive_flows.dart';
import 'dev/dev_events_dashboard.dart';
import 'dev/scenario_scripting.dart';
import 'dev/multi_platform_test_harness.dart';
import 'roadmap/phase_tracker.dart';

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
  static UnifiedAnalytics? _analytics;
  static BridgeStore? _bridgeStore;
  static BridgeTransport?
      _bridgeTransport; // requires import; create abstract here
  static HybridNavigator? _hybridNav;
  static UnifiedMedia? _media;
  static ArAdapter? _ar;
  static MlPipeline? _mlPipeline;
  static BackgroundScheduler? _background;
  static DeviceBridge? _deviceBridge;
  static CryptoEnvelopeService? _crypto;
  static PrivacyToolkit? _privacy;
  static AnomalyDetector? _anomaly;
  static RecommendationEngine? _reco;
  static ChatOrchestrator? _chat;
  static PredictiveFlowEngine? _predictive;
  static DevEventsDashboard? _devDash;
  static ScenarioRunner? _scenarioRunner;
  static MultiPlatformTestHarness? _testHarness;
  static PhaseTracker? _phaseTracker;

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

  /// Analytics facade (must be initialized explicitly)
  static UnifiedAnalytics get analytics =>
      _analytics ??= UnifiedAnalytics.instance;

  /// Hybrid navigation (native <-> Flutter) experimental facade
  static HybridNavigator get page => _hybridNav ??= HybridNavigator.instance;

  /// Unified media APIs (camera/mic/gallery/screen) experimental
  static UnifiedMedia get media => _media ??= UnifiedMedia.instance;

  /// AR adapter (experimental, feature-gated)
  static ArAdapter get ar {
    _ar ??= MockArAdapter();
    return _ar!;
  }

  /// ML pipeline (experimental, feature-gated)
  static MlPipeline get mlPipeline {
    _mlPipeline ??= MlPipeline();
    return _mlPipeline!;
  }

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

  /// Access shared bridge store (initializes lazily)
  static BridgeStore get bridgeStore => _bridgeStore ??= BridgeStore.instance;

  /// Create / get a bridge channel (memory transport fallback)
  static BridgeChannel bridgeChannel(String name) {
    _bridgeTransport ??= MemoryBridgeTransport();
    return BridgeChannel(name, _bridgeTransport!);
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

    if (_analytics != null) {
      await _analytics!.dispose();
      _analytics = null;
    }

    if (_bridgeStore != null) {
      await _bridgeStore!.dispose();
      _bridgeStore = null;
    }
    if (_bridgeTransport != null) {
      await _bridgeTransport!.dispose();
      _bridgeTransport = null;
    }
    if (_hybridNav != null) {
      await _hybridNav!.dispose();
      _hybridNav = null;
    }
    if (_media != null) {
      await _media!.dispose();
      _media = null;
    }
    if (_background != null) {
      await _background!.dispose();
      _background = null;
    }
    if (_deviceBridge != null) {
      // No dispose method yet
      _deviceBridge = null;
    }
    _crypto = null; // stateless singletons for now
    _privacy = null;
    _anomaly = null;
    _reco = null;
    _chat = null;
    _predictive = null;
    _devDash = null;
    _scenarioRunner = null;
    _testHarness = null;
    _phaseTracker = null;

    instance._isInitialized = false;

    if (kDebugMode) {
      print('Unify: Disposed all resources');
    }
  }

  /// Security services (experimental)
  static CryptoEnvelopeService get crypto =>
      _crypto ??= CryptoEnvelopeService.instance;
  static PrivacyToolkit get privacy => _privacy ??= PrivacyToolkit.instance;
  static AnomalyDetector get anomaly => _anomaly ??= AnomalyDetector.instance;

  /// AI module facades (experimental)
  static RecommendationEngine get recommendations =>
      _reco ??= RecommendationEngine.instance;
  static ChatOrchestrator get chat => _chat ??= ChatOrchestrator.instance;
  static PredictiveFlowEngine get predictive =>
      _predictive ??= PredictiveFlowEngine.instance;

  /// Developer ergonomics facades (experimental)
  static DevEventsDashboard get devDashboard =>
      _devDash ??= DevEventsDashboard.instance;
  static ScenarioRunner get scenarios =>
      _scenarioRunner ??= ScenarioRunner.instance;
  static MultiPlatformTestHarness get tests =>
      _testHarness ??= MultiPlatformTestHarness.instance;

  /// Phase tracking (experimental)
  static PhaseTracker get phaseTracker =>
      _phaseTracker ??= PhaseTracker.instance;
}
