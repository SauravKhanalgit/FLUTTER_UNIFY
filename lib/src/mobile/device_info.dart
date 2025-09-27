import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Device information manager
class DeviceInfoManager extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/device_info');

  bool _isInitialized = false;
  DeviceInfo? _cachedDeviceInfo;

  /// Check if device info manager is initialized
  bool get isInitialized => _isInitialized;

  /// Get cached device information
  DeviceInfo? get cachedDeviceInfo => _cachedDeviceInfo;

  /// Initialize device info manager
  Future<void> initialize() async {
    if (kIsWeb || !PlatformDetector.isMobile) {
      throw UnsupportedError(
          'Device info is only supported on mobile platforms');
    }

    if (_isInitialized) return;

    try {
      await _loadDeviceInfo();

      _isInitialized = true;
      emit('device-info-initialized');

      if (kDebugMode) {
        print('DeviceInfoManager: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Load device information
  Future<void> _loadDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod('getDeviceInfo')
          as Map<dynamic, dynamic>?;
      if (result != null) {
        _cachedDeviceInfo = DeviceInfo.fromMap(result.cast<String, dynamic>());
      }
    } catch (e) {
      // Fallback to basic device info using dart:io
      _cachedDeviceInfo = DeviceInfo(
        platform: PlatformDetector.platformName,
        model: _getBasicModel(),
        manufacturer: _getBasicManufacturer(),
        version: _getBasicVersion(),
        isPhysicalDevice: !_isEmulator(),
      );
    }
  }

  /// Get basic device model
  String _getBasicModel() {
    if (PlatformDetector.isAndroid) {
      return 'Android Device';
    } else if (PlatformDetector.isIOS) {
      return 'iOS Device';
    }
    return 'Unknown Device';
  }

  /// Get basic manufacturer
  String _getBasicManufacturer() {
    if (PlatformDetector.isAndroid) {
      return 'Android';
    } else if (PlatformDetector.isIOS) {
      return 'Apple';
    }
    return 'Unknown';
  }

  /// Get basic OS version
  String _getBasicVersion() {
    try {
      return Platform.operatingSystemVersion;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if running on emulator (basic check)
  bool _isEmulator() {
    try {
      // Basic emulator detection - in real implementation would be more sophisticated
      final version = Platform.operatingSystemVersion.toLowerCase();
      return version.contains('emulator') ||
          version.contains('simulator') ||
          version.contains('test');
    } catch (e) {
      return false;
    }
  }

  /// Get current device info
  Future<DeviceInfo?> getDeviceInfo() async {
    if (!_isInitialized) return null;

    try {
      await _loadDeviceInfo();
      return _cachedDeviceInfo;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to get device info: $e');
      }
      return _cachedDeviceInfo;
    }
  }

  /// Get device capabilities
  Future<DeviceCapabilities?> getDeviceCapabilities() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('getDeviceCapabilities')
          as Map<dynamic, dynamic>?;
      if (result != null) {
        return DeviceCapabilities.fromMap(result.cast<String, dynamic>());
      }

      // Fallback capabilities
      return DeviceCapabilities(
        hasCamera: true,
        hasBluetooth: true,
        hasNFC: PlatformDetector.isAndroid,
        hasBiometrics: true,
        hasGPS: true,
        hasAccelerometer: true,
        hasGyroscope: true,
        hasMagnetometer: true,
        hasBarometer: false,
        hasProximitySensor: true,
        hasAmbientLightSensor: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to get device capabilities: $e');
      }
      return null;
    }
  }

  /// Get battery information
  Future<BatteryInfo?> getBatteryInfo() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('getBatteryInfo')
          as Map<dynamic, dynamic>?;
      if (result != null) {
        return BatteryInfo.fromMap(result.cast<String, dynamic>());
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to get battery info: $e');
      }
      return null;
    }
  }

  /// Get memory information
  Future<MemoryInfo?> getMemoryInfo() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('getMemoryInfo')
          as Map<dynamic, dynamic>?;
      if (result != null) {
        return MemoryInfo.fromMap(result.cast<String, dynamic>());
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to get memory info: $e');
      }
      return null;
    }
  }

  /// Get storage information
  Future<StorageInfo?> getStorageInfo() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('getStorageInfo')
          as Map<dynamic, dynamic>?;
      if (result != null) {
        return StorageInfo.fromMap(result.cast<String, dynamic>());
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to get storage info: $e');
      }
      return null;
    }
  }

  /// Get network information
  Future<NetworkInfo?> getNetworkInfo() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('getNetworkInfo')
          as Map<dynamic, dynamic>?;
      if (result != null) {
        return NetworkInfo.fromMap(result.cast<String, dynamic>());
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to get network info: $e');
      }
      return null;
    }
  }

  /// Dispose device info manager
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      _cachedDeviceInfo = null;
      removeAllListeners();

      if (kDebugMode) {
        print('DeviceInfoManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeviceInfoManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// Device information
class DeviceInfo {
  final String platform;
  final String model;
  final String manufacturer;
  final String version;
  final String? buildNumber;
  final bool isPhysicalDevice;
  final String? deviceId;

  DeviceInfo({
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.version,
    this.buildNumber,
    required this.isPhysicalDevice,
    this.deviceId,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      platform: map['platform'] ?? '',
      model: map['model'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      version: map['version'] ?? '',
      buildNumber: map['buildNumber'],
      isPhysicalDevice: map['isPhysicalDevice'] ?? true,
      deviceId: map['deviceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'model': model,
      'manufacturer': manufacturer,
      'version': version,
      'buildNumber': buildNumber,
      'isPhysicalDevice': isPhysicalDevice,
      'deviceId': deviceId,
    };
  }
}

/// Device capabilities
class DeviceCapabilities {
  final bool hasCamera;
  final bool hasBluetooth;
  final bool hasNFC;
  final bool hasBiometrics;
  final bool hasGPS;
  final bool hasAccelerometer;
  final bool hasGyroscope;
  final bool hasMagnetometer;
  final bool hasBarometer;
  final bool hasProximitySensor;
  final bool hasAmbientLightSensor;

  DeviceCapabilities({
    required this.hasCamera,
    required this.hasBluetooth,
    required this.hasNFC,
    required this.hasBiometrics,
    required this.hasGPS,
    required this.hasAccelerometer,
    required this.hasGyroscope,
    required this.hasMagnetometer,
    required this.hasBarometer,
    required this.hasProximitySensor,
    required this.hasAmbientLightSensor,
  });

  factory DeviceCapabilities.fromMap(Map<String, dynamic> map) {
    return DeviceCapabilities(
      hasCamera: map['hasCamera'] ?? false,
      hasBluetooth: map['hasBluetooth'] ?? false,
      hasNFC: map['hasNFC'] ?? false,
      hasBiometrics: map['hasBiometrics'] ?? false,
      hasGPS: map['hasGPS'] ?? false,
      hasAccelerometer: map['hasAccelerometer'] ?? false,
      hasGyroscope: map['hasGyroscope'] ?? false,
      hasMagnetometer: map['hasMagnetometer'] ?? false,
      hasBarometer: map['hasBarometer'] ?? false,
      hasProximitySensor: map['hasProximitySensor'] ?? false,
      hasAmbientLightSensor: map['hasAmbientLightSensor'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasCamera': hasCamera,
      'hasBluetooth': hasBluetooth,
      'hasNFC': hasNFC,
      'hasBiometrics': hasBiometrics,
      'hasGPS': hasGPS,
      'hasAccelerometer': hasAccelerometer,
      'hasGyroscope': hasGyroscope,
      'hasMagnetometer': hasMagnetometer,
      'hasBarometer': hasBarometer,
      'hasProximitySensor': hasProximitySensor,
      'hasAmbientLightSensor': hasAmbientLightSensor,
    };
  }
}

/// Battery information
class BatteryInfo {
  final int level; // 0-100
  final bool isCharging;
  final String chargingStatus;
  final int? timeToEmpty; // minutes
  final int? timeToFull; // minutes

  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.chargingStatus,
    this.timeToEmpty,
    this.timeToFull,
  });

  factory BatteryInfo.fromMap(Map<String, dynamic> map) {
    return BatteryInfo(
      level: map['level'] ?? 0,
      isCharging: map['isCharging'] ?? false,
      chargingStatus: map['chargingStatus'] ?? 'unknown',
      timeToEmpty: map['timeToEmpty'],
      timeToFull: map['timeToFull'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'isCharging': isCharging,
      'chargingStatus': chargingStatus,
      'timeToEmpty': timeToEmpty,
      'timeToFull': timeToFull,
    };
  }
}

/// Memory information
class MemoryInfo {
  final int totalMemory; // bytes
  final int availableMemory; // bytes
  final int usedMemory; // bytes
  final double memoryUsagePercent;

  MemoryInfo({
    required this.totalMemory,
    required this.availableMemory,
    required this.usedMemory,
    required this.memoryUsagePercent,
  });

  factory MemoryInfo.fromMap(Map<String, dynamic> map) {
    return MemoryInfo(
      totalMemory: map['totalMemory'] ?? 0,
      availableMemory: map['availableMemory'] ?? 0,
      usedMemory: map['usedMemory'] ?? 0,
      memoryUsagePercent: (map['memoryUsagePercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalMemory': totalMemory,
      'availableMemory': availableMemory,
      'usedMemory': usedMemory,
      'memoryUsagePercent': memoryUsagePercent,
    };
  }
}

/// Storage information
class StorageInfo {
  final int totalStorage; // bytes
  final int availableStorage; // bytes
  final int usedStorage; // bytes
  final double storageUsagePercent;

  StorageInfo({
    required this.totalStorage,
    required this.availableStorage,
    required this.usedStorage,
    required this.storageUsagePercent,
  });

  factory StorageInfo.fromMap(Map<String, dynamic> map) {
    return StorageInfo(
      totalStorage: map['totalStorage'] ?? 0,
      availableStorage: map['availableStorage'] ?? 0,
      usedStorage: map['usedStorage'] ?? 0,
      storageUsagePercent: (map['storageUsagePercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalStorage': totalStorage,
      'availableStorage': availableStorage,
      'usedStorage': usedStorage,
      'storageUsagePercent': storageUsagePercent,
    };
  }
}

/// Network information
class NetworkInfo {
  final String connectionType; // wifi, cellular, none
  final String? networkName;
  final String? ipAddress;
  final bool isConnected;
  final bool isMetered;
  final int? signalStrength; // 0-100 for cellular

  NetworkInfo({
    required this.connectionType,
    this.networkName,
    this.ipAddress,
    required this.isConnected,
    required this.isMetered,
    this.signalStrength,
  });

  factory NetworkInfo.fromMap(Map<String, dynamic> map) {
    return NetworkInfo(
      connectionType: map['connectionType'] ?? 'none',
      networkName: map['networkName'],
      ipAddress: map['ipAddress'],
      isConnected: map['isConnected'] ?? false,
      isMetered: map['isMetered'] ?? false,
      signalStrength: map['signalStrength'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'connectionType': connectionType,
      'networkName': networkName,
      'ipAddress': ipAddress,
      'isConnected': isConnected,
      'isMetered': isMetered,
      'signalStrength': signalStrength,
    };
  }
}
