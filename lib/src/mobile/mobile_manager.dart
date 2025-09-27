import 'dart:async';
import 'package:flutter/foundation.dart';

import 'native_bridge.dart';
import 'device_info.dart';
import 'mobile_services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Mobile platform integration manager
class MobileManager extends EventEmitter {
  static MobileManager? _instance;
  static MobileManager get instance => _instance ??= MobileManager._();

  MobileManager._();

  late NativeBridgeManager _nativeBridge;
  late DeviceInfoManager _deviceInfo;
  late MobileServicesManager _mobileServices;

  bool _isInitialized = false;
  bool _nativeBridgeEnabled = false;
  bool _deviceInfoEnabled = false;
  bool _mobileServicesEnabled = false;

  /// Get the native bridge manager
  NativeBridgeManager get nativeBridge => _nativeBridge;

  /// Get the device info manager
  DeviceInfoManager get deviceInfo => _deviceInfo;

  /// Get the mobile services manager
  MobileServicesManager get services => _mobileServices;

  /// Check if mobile manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize mobile integrations
  Future<void> initialize({
    bool enableNativeBridge = true,
    bool enableDeviceInfo = true,
    bool enableMobileServices = true,
  }) async {
    if (kIsWeb || !PlatformDetector.isMobile) {
      throw UnsupportedError(
          'MobileManager can only be used on mobile platforms');
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('MobileManager: Already initialized');
      }
      return;
    }

    _nativeBridgeEnabled = enableNativeBridge;
    _deviceInfoEnabled = enableDeviceInfo;
    _mobileServicesEnabled = enableMobileServices;

    // Initialize components
    if (_nativeBridgeEnabled) {
      _nativeBridge = NativeBridgeManager();
      await _nativeBridge.initialize();
    }

    if (_deviceInfoEnabled) {
      _deviceInfo = DeviceInfoManager();
      await _deviceInfo.initialize();
    }

    if (_mobileServicesEnabled) {
      _mobileServices = MobileServicesManager();
      await _mobileServices.initialize();
    }

    _isInitialized = true;
    emit('mobile-initialized');

    if (kDebugMode) {
      print('MobileManager: Initialized with features - '
          'NativeBridge: $_nativeBridgeEnabled, '
          'DeviceInfo: $_deviceInfoEnabled, '
          'MobileServices: $_mobileServicesEnabled');
    }
  }

  /// Get mobile capabilities
  Map<String, bool> getCapabilities() {
    return {
      'nativeBridge': _nativeBridgeEnabled,
      'deviceInfo': _deviceInfoEnabled,
      'mobileServices': _mobileServicesEnabled,
      'camera': PlatformDetector.isMobile,
      'location': PlatformDetector.isMobile,
      'bluetooth': PlatformDetector.isMobile,
      'nfc': PlatformDetector.isAndroid,
      'biometrics': PlatformDetector.isMobile,
      'haptics': PlatformDetector.isMobile,
    };
  }

  /// Check if a specific feature is available
  bool isFeatureAvailable(String feature) {
    return getCapabilities()[feature] ?? false;
  }

  /// Get platform-specific information
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': PlatformDetector.platformName,
      'isAndroid': PlatformDetector.isAndroid,
      'isIOS': PlatformDetector.isIOS,
      'capabilities': getCapabilities(),
    };
  }

  /// Dispose of all mobile resources
  Future<void> dispose() async {
    if (_nativeBridgeEnabled) {
      await _nativeBridge.dispose();
    }

    if (_deviceInfoEnabled) {
      await _deviceInfo.dispose();
    }

    if (_mobileServicesEnabled) {
      await _mobileServices.dispose();
    }

    removeAllListeners();
    _isInitialized = false;

    if (kDebugMode) {
      print('MobileManager: Disposed all resources');
    }
  }
}
