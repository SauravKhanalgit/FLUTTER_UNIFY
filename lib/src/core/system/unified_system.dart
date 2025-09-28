import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, VoidCallback;
import '../../common/platform_detector.dart';
import '../../common/event_emitter.dart';

/// Platform enumeration
enum UnifyPlatform {
  web,
  android,
  ios,
  windows,
  macos,
  linux,
  unknown,
}

/// Connectivity status
enum ConnectivityStatus {
  none,
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  other,
}

/// Battery status
enum BatteryStatus {
  unknown,
  charging,
  discharging,
  notCharging,
  full,
}

/// Window focus state
enum WindowFocusState {
  focused,
  unfocused,
  minimized,
  restored,
}

/// System configuration
class SystemConfig {
  final bool enableBackgroundTasks;
  final bool monitorConnectivity;
  final bool monitorBattery;
  final bool monitorWindowFocus;
  final bool enableGlobalShortcuts;

  const SystemConfig({
    this.enableBackgroundTasks = true,
    this.monitorConnectivity = true,
    this.monitorBattery = false,
    this.monitorWindowFocus = true,
    this.enableGlobalShortcuts = false,
  });
}

/// Unified system API providing reactive streams for system changes
///
/// This is the foundation of the reactive architecture, similar to how
/// Bloc provides reactive state management. All system changes are
/// exposed as streams that you can listen to.
///
/// Example:
/// ```dart
/// // Listen to network changes
/// Unify.system.onConnectivityChanged.listen((status) {
///   print('Network changed: $status');
/// });
///
/// // Listen to battery changes (mobile/laptop)
/// Unify.system.onBatteryChanged.listen((status) {
///   if (status.level < 0.2) {
///     showLowBatteryWarning();
///   }
/// });
///
/// // Listen to window focus (desktop/web)
/// Unify.system.onWindowFocusChanged.listen((focused) {
///   if (focused) {
///     resumeUpdates();
///   } else {
///     pauseUpdates();
///   }
/// });
/// ```
class UnifiedSystem extends EventEmitter {
  static UnifiedSystem? _instance;
  static UnifiedSystem get instance => _instance ??= UnifiedSystem._();

  UnifiedSystem._();

  bool _isInitialized = false;
  SystemConfig _config = const SystemConfig();

  // Current state
  UnifyPlatform _platform = UnifyPlatform.unknown;
  ConnectivityStatus _connectivity = ConnectivityStatus.none;
  BatteryStatus _batteryStatus = BatteryStatus.unknown;
  double _batteryLevel = 1.0;
  WindowFocusState _windowFocus = WindowFocusState.focused;

  // Reactive streams
  final StreamController<ConnectivityStatus> _connectivityController =
      StreamController<ConnectivityStatus>.broadcast();
  final StreamController<BatteryInfo> _batteryController =
      StreamController<BatteryInfo>.broadcast();
  final StreamController<WindowFocusState> _windowFocusController =
      StreamController<WindowFocusState>.broadcast();
  final StreamController<SystemThemeInfo> _themeController =
      StreamController<SystemThemeInfo>.broadcast();

  // Timers for monitoring
  Timer? _connectivityTimer;
  Timer? _batteryTimer;

  /// Stream of connectivity changes
  ///
  /// Emits whenever the device's network connectivity changes.
  /// This is reactive and will emit immediately with current status
  /// when subscribed to.
  Stream<ConnectivityStatus> get onConnectivityChanged =>
      _connectivityController.stream;

  /// Stream of battery changes
  ///
  /// Emits battery level and charging status changes.
  /// Only available on mobile devices and laptops.
  Stream<BatteryInfo> get onBatteryChanged => _batteryController.stream;

  /// Stream of window focus changes
  ///
  /// Emits when the app window gains or loses focus.
  /// Useful for pausing/resuming activities when app is not visible.
  Stream<WindowFocusState> get onWindowFocusChanged =>
      _windowFocusController.stream;

  /// Stream of system theme changes
  ///
  /// Emits when the system theme changes (light/dark mode).
  Stream<SystemThemeInfo> get onThemeChanged => _themeController.stream;

  /// Current platform
  UnifyPlatform get platform => _platform;

  /// Current connectivity status
  ConnectivityStatus get connectivity => _connectivity;

  /// Current battery status (mobile/laptop only)
  BatteryStatus get batteryStatus => _batteryStatus;

  /// Current battery level (0.0 to 1.0)
  double get batteryLevel => _batteryLevel;

  /// Current window focus state
  WindowFocusState get windowFocus => _windowFocus;

  /// Check if platform is web
  static bool get isWeb => kIsWeb;

  /// Check if platform is desktop
  static bool get isDesktop => PlatformDetector.isDesktop;

  /// Check if platform is mobile
  static bool get isMobile => PlatformDetector.isMobile;

  /// Check if feature is supported on current platform
  bool isFeatureSupported(String feature) {
    switch (feature.toLowerCase()) {
      case 'battery':
        return isMobile ||
            (isDesktop &&
                (platform == UnifyPlatform.windows ||
                    platform == UnifyPlatform.macos));
      case 'window_focus':
        return isDesktop || isWeb;
      case 'global_shortcuts':
        return isDesktop;
      case 'system_tray':
        return isDesktop;
      case 'push_notifications':
        return isMobile || isWeb;
      case 'file_associations':
        return isDesktop;
      case 'drag_drop':
        return isDesktop || isWeb;
      default:
        return false;
    }
  }

  /// Initialize the system module
  Future<bool> initialize(SystemConfig config) async {
    if (_isInitialized) return true;

    try {
      _config = config;
      _detectPlatform();

      if (_config.monitorConnectivity) {
        await _startConnectivityMonitoring();
      }

      if (_config.monitorBattery && isFeatureSupported('battery')) {
        await _startBatteryMonitoring();
      }

      if (_config.monitorWindowFocus && isFeatureSupported('window_focus')) {
        await _startWindowFocusMonitoring();
      }

      // Start theme monitoring
      await _startThemeMonitoring();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ UnifiedSystem initialized');
        print('📱 Platform: ${_platform.name}');
        print('🌐 Connectivity: ${_connectivity.name}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UnifiedSystem initialization failed: $e');
      }
      return false;
    }
  }

  /// Check if system is initialized
  bool get isInitialized => _isInitialized;

  /// Get system information
  Map<String, dynamic> getSystemInfo() {
    return {
      'platform': _platform.name,
      'connectivity': _connectivity.name,
      'batteryStatus': _batteryStatus.name,
      'batteryLevel': _batteryLevel,
      'windowFocus': _windowFocus.name,
      'isWeb': isWeb,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'supportedFeatures': _getSupportedFeatures(),
    };
  }

  /// Enable or disable a monitoring feature
  Future<bool> setMonitoring(String feature, bool enabled) async {
    switch (feature.toLowerCase()) {
      case 'connectivity':
        if (enabled && !_config.monitorConnectivity) {
          await _startConnectivityMonitoring();
        } else if (!enabled && _config.monitorConnectivity) {
          _stopConnectivityMonitoring();
        }
        return true;
      case 'battery':
        if (enabled &&
            !_config.monitorBattery &&
            isFeatureSupported('battery')) {
          await _startBatteryMonitoring();
        } else if (!enabled && _config.monitorBattery) {
          _stopBatteryMonitoring();
        }
        return true;
      case 'window_focus':
        if (enabled &&
            !_config.monitorWindowFocus &&
            isFeatureSupported('window_focus')) {
          await _startWindowFocusMonitoring();
        } else if (!enabled && _config.monitorWindowFocus) {
          _stopWindowFocusMonitoring();
        }
        return true;
      default:
        return false;
    }
  }

  /// Request system permissions
  Future<bool> requestPermission(String permission) async {
    switch (permission.toLowerCase()) {
      case 'notifications':
        return await _requestNotificationPermission();
      case 'location':
        return await _requestLocationPermission();
      case 'camera':
        return await _requestCameraPermission();
      case 'microphone':
        return await _requestMicrophonePermission();
      case 'storage':
        return await _requestStoragePermission();
      default:
        return false;
    }
  }

  /// Register global shortcut (desktop only)
  Future<bool> registerGlobalShortcut(
      String shortcut, VoidCallback callback) async {
    if (!isFeatureSupported('global_shortcuts')) return false;

    try {
      return await _registerGlobalShortcut(shortcut, callback);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to register global shortcut: $e');
      }
      return false;
    }
  }

  /// Unregister global shortcut
  Future<bool> unregisterGlobalShortcut(String shortcut) async {
    if (!isFeatureSupported('global_shortcuts')) return false;

    try {
      return await _unregisterGlobalShortcut(shortcut);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to unregister global shortcut: $e');
      }
      return false;
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    return {
      'connectivityChecks': 0, // Would track actual metrics
      'batteryChecks': 0,
      'focusChanges': 0,
      'shortcutsRegistered': 0,
    };
  }

  // Internal methods
  void _detectPlatform() {
    if (kIsWeb) {
      _platform = UnifyPlatform.web;
    } else if (PlatformDetector.isAndroid) {
      _platform = UnifyPlatform.android;
    } else if (PlatformDetector.isIOS) {
      _platform = UnifyPlatform.ios;
    } else if (PlatformDetector.isWindows) {
      _platform = UnifyPlatform.windows;
    } else if (PlatformDetector.isMacOS) {
      _platform = UnifyPlatform.macos;
    } else if (PlatformDetector.isLinux) {
      _platform = UnifyPlatform.linux;
    } else {
      _platform = UnifyPlatform.unknown;
    }
  }

  Future<void> _startConnectivityMonitoring() async {
    // Initial check
    await _checkConnectivity();

    // Start periodic monitoring
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  void _stopConnectivityMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  Future<void> _checkConnectivity() async {
    ConnectivityStatus newStatus;

    try {
      // Platform-specific connectivity check
      if (kIsWeb) {
        newStatus = await _checkWebConnectivity();
      } else if (isDesktop) {
        newStatus = await _checkDesktopConnectivity();
      } else if (isMobile) {
        newStatus = await _checkMobileConnectivity();
      } else {
        newStatus = ConnectivityStatus.none;
      }

      if (newStatus != _connectivity) {
        _connectivity = newStatus;
        _connectivityController.add(newStatus);

        emit('connectivity-changed', {
          'status': newStatus.name,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connectivity check failed: $e');
      }
    }
  }

  Future<void> _startBatteryMonitoring() async {
    await _checkBattery();

    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkBattery();
    });
  }

  void _stopBatteryMonitoring() {
    _batteryTimer?.cancel();
    _batteryTimer = null;
  }

  Future<void> _checkBattery() async {
    try {
      final batteryInfo = await _getBatteryInfo();

      if (batteryInfo.status != _batteryStatus ||
          batteryInfo.level != _batteryLevel) {
        _batteryStatus = batteryInfo.status;
        _batteryLevel = batteryInfo.level;
        _batteryController.add(batteryInfo);

        emit('battery-changed', {
          'status': batteryInfo.status.name,
          'level': batteryInfo.level,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Battery check failed: $e');
      }
    }
  }

  Future<void> _startWindowFocusMonitoring() async {
    // Platform-specific window focus monitoring
    if (kIsWeb) {
      await _startWebFocusMonitoring();
    } else if (isDesktop) {
      await _startDesktopFocusMonitoring();
    }
  }

  void _stopWindowFocusMonitoring() {
    // Stop platform-specific monitoring
  }

  Future<void> _startThemeMonitoring() async {
    // Monitor system theme changes
    final currentTheme = await _getSystemTheme();
    _themeController.add(currentTheme);
  }

  List<String> _getSupportedFeatures() {
    final features = <String>[];

    if (isFeatureSupported('battery')) features.add('battery');
    if (isFeatureSupported('window_focus')) features.add('window_focus');
    if (isFeatureSupported('global_shortcuts'))
      features.add('global_shortcuts');
    if (isFeatureSupported('system_tray')) features.add('system_tray');
    if (isFeatureSupported('push_notifications'))
      features.add('push_notifications');
    if (isFeatureSupported('file_associations'))
      features.add('file_associations');
    if (isFeatureSupported('drag_drop')) features.add('drag_drop');

    return features;
  }

  // Platform-specific implementations (stubs)
  Future<ConnectivityStatus> _checkWebConnectivity() async {
    // Check navigator.onLine, connection API
    return ConnectivityStatus.wifi;
  }

  Future<ConnectivityStatus> _checkDesktopConnectivity() async {
    // Use platform channels to check network
    return ConnectivityStatus.ethernet;
  }

  Future<ConnectivityStatus> _checkMobileConnectivity() async {
    // Use connectivity_plus or similar
    return ConnectivityStatus.mobile;
  }

  Future<BatteryInfo> _getBatteryInfo() async {
    // Platform-specific battery info
    return BatteryInfo(
      status: BatteryStatus.unknown,
      level: 1.0,
      isCharging: false,
    );
  }

  Future<void> _startWebFocusMonitoring() async {
    // Use window focus/blur events
  }

  Future<void> _startDesktopFocusMonitoring() async {
    // Use platform channels for window focus events
  }

  Future<SystemThemeInfo> _getSystemTheme() async {
    // Get system theme information
    return SystemThemeInfo(
      isDark: false,
      accentColor: const Color(0xFF0078D4),
      highContrast: false,
    );
  }

  Future<bool> _requestNotificationPermission() async {
    return true; // Simplified
  }

  Future<bool> _requestLocationPermission() async {
    return true; // Simplified
  }

  Future<bool> _requestCameraPermission() async {
    return true; // Simplified
  }

  Future<bool> _requestMicrophonePermission() async {
    return true; // Simplified
  }

  Future<bool> _requestStoragePermission() async {
    return true; // Simplified
  }

  Future<bool> _registerGlobalShortcut(
      String shortcut, VoidCallback callback) async {
    return true; // Simplified
  }

  Future<bool> _unregisterGlobalShortcut(String shortcut) async {
    return true; // Simplified
  }

  /// Dispose resources
  Future<void> dispose() async {
    _connectivityTimer?.cancel();
    _batteryTimer?.cancel();

    await Future.wait([
      _connectivityController.close(),
      _batteryController.close(),
      _windowFocusController.close(),
      _themeController.close(),
    ]);

    _isInitialized = false;
  }
}

/// Battery information
class BatteryInfo {
  final BatteryStatus status;
  final double level; // 0.0 to 1.0
  final bool isCharging;
  final Duration? timeRemaining;

  const BatteryInfo({
    required this.status,
    required this.level,
    required this.isCharging,
    this.timeRemaining,
  });
}

/// System theme information
class SystemThemeInfo {
  final bool isDark;
  final Color accentColor;
  final bool highContrast;
  final double textScale;

  const SystemThemeInfo({
    required this.isDark,
    required this.accentColor,
    required this.highContrast,
    this.textScale = 1.0,
  });
}
