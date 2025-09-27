import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Mobile services manager (camera, location, sensors, etc.)
class MobileServicesManager extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/mobile_services');

  bool _isInitialized = false;

  /// Check if mobile services manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize mobile services manager
  Future<void> initialize() async {
    if (kIsWeb || !PlatformDetector.isMobile) {
      throw UnsupportedError(
          'Mobile services are only supported on mobile platforms');
    }

    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');

      _isInitialized = true;
      emit('mobile-services-initialized');

      if (kDebugMode) {
        print('MobileServicesManager: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLocationUpdate':
        final location = LocationData.fromMap(call.arguments);
        emit('location-update', location);
        break;

      case 'onSensorUpdate':
        final sensorType = call.arguments['type'] as String;
        final data = call.arguments['data'] as List<dynamic>;
        emit('sensor-update', {
          'type': sensorType,
          'data': data.cast<double>(),
        });
        break;

      case 'onPermissionResult':
        final permission = call.arguments['permission'] as String;
        final granted = call.arguments['granted'] as bool;
        emit('permission-result', {
          'permission': permission,
          'granted': granted,
        });
        break;

      default:
        if (kDebugMode) {
          print('MobileServicesManager: Unknown method call: ${call.method}');
        }
    }
  }

  // PERMISSION SERVICES

  /// Request permission
  Future<bool> requestPermission(String permission) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('requestPermission', {
        'permission': permission,
      }) as bool?;

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'MobileServicesManager: Failed to request permission $permission: $e');
      }
      return false;
    }
  }

  /// Check if permission is granted
  Future<bool> hasPermission(String permission) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('hasPermission', {
        'permission': permission,
      }) as bool?;

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'MobileServicesManager: Failed to check permission $permission: $e');
      }
      return false;
    }
  }

  // CAMERA SERVICES

  /// Check if camera is available
  Future<bool> isCameraAvailable() async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('isCameraAvailable') as bool?;
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to check camera availability: $e');
      }
      return false;
    }
  }

  /// Take a photo
  Future<String?> takePhoto({
    CameraOptions? options,
  }) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('takePhoto', {
        'options': options?.toMap() ?? {},
      }) as String?;

      if (result != null) {
        emit('photo-taken', result);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to take photo: $e');
      }
      return null;
    }
  }

  /// Record video
  Future<String?> recordVideo({
    VideoOptions? options,
  }) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('recordVideo', {
        'options': options?.toMap() ?? {},
      }) as String?;

      if (result != null) {
        emit('video-recorded', result);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to record video: $e');
      }
      return null;
    }
  }

  // LOCATION SERVICES

  /// Get current location
  Future<LocationData?> getCurrentLocation({
    LocationOptions? options,
  }) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('getCurrentLocation', {
        'options': options?.toMap() ?? {},
      }) as Map<dynamic, dynamic>?;

      if (result != null) {
        final location = LocationData.fromMap(result.cast<String, dynamic>());
        emit('location-received', location);
        return location;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to get current location: $e');
      }
      return null;
    }
  }

  /// Start location tracking
  Future<bool> startLocationTracking({
    LocationOptions? options,
  }) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('startLocationTracking', {
        'options': options?.toMap() ?? {},
      }) as bool?;

      if (result == true) {
        emit('location-tracking-started');
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to start location tracking: $e');
      }
      return false;
    }
  }

  /// Stop location tracking
  Future<bool> stopLocationTracking() async {
    if (!_isInitialized) return false;

    try {
      final result =
          await _channel.invokeMethod('stopLocationTracking') as bool?;

      if (result == true) {
        emit('location-tracking-stopped');
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to stop location tracking: $e');
      }
      return false;
    }
  }

  // SENSOR SERVICES

  /// Start sensor monitoring
  Future<bool> startSensorMonitoring(
    String sensorType, {
    int? interval, // milliseconds
  }) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('startSensorMonitoring', {
        'sensorType': sensorType,
        'interval': interval ?? 100,
      }) as bool?;

      if (result == true) {
        emit('sensor-monitoring-started', sensorType);
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to start sensor monitoring: $e');
      }
      return false;
    }
  }

  /// Stop sensor monitoring
  Future<bool> stopSensorMonitoring(String sensorType) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('stopSensorMonitoring', {
        'sensorType': sensorType,
      }) as bool?;

      if (result == true) {
        emit('sensor-monitoring-stopped', sensorType);
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to stop sensor monitoring: $e');
      }
      return false;
    }
  }

  // BIOMETRIC SERVICES

  /// Check if biometrics are available
  Future<bool> isBiometricsAvailable() async {
    if (!_isInitialized) return false;

    try {
      final result =
          await _channel.invokeMethod('isBiometricsAvailable') as bool?;
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'MobileServicesManager: Failed to check biometrics availability: $e');
      }
      return false;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String? reason,
  }) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('authenticateWithBiometrics', {
        'reason': reason ?? 'Please authenticate',
      }) as bool?;

      if (result == true) {
        emit('biometric-authentication-success');
      } else {
        emit('biometric-authentication-failed');
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'MobileServicesManager: Failed to authenticate with biometrics: $e');
      }
      return false;
    }
  }

  // HAPTIC SERVICES

  /// Trigger haptic feedback
  Future<void> triggerHapticFeedback(HapticFeedbackType type) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('triggerHapticFeedback', {
        'type': type.name,
      });

      emit('haptic-feedback-triggered', type.name);
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to trigger haptic feedback: $e');
      }
    }
  }

  /// Get available services
  Future<List<String>> getAvailableServices() async {
    if (!_isInitialized) return [];

    try {
      final result =
          await _channel.invokeMethod('getAvailableServices') as List<dynamic>?;
      return result?.cast<String>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to get available services: $e');
      }
      return [];
    }
  }

  /// Dispose mobile services manager
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      removeAllListeners();

      if (kDebugMode) {
        print('MobileServicesManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MobileServicesManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// Camera options
class CameraOptions {
  final String quality; // low, medium, high
  final bool allowEditing;
  final int? maxWidth;
  final int? maxHeight;

  CameraOptions({
    this.quality = 'medium',
    this.allowEditing = false,
    this.maxWidth,
    this.maxHeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'allowEditing': allowEditing,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
    };
  }
}

/// Video options
class VideoOptions {
  final String quality; // low, medium, high
  final int? maxDuration; // seconds
  final bool allowEditing;

  VideoOptions({
    this.quality = 'medium',
    this.maxDuration,
    this.allowEditing = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'maxDuration': maxDuration,
      'allowEditing': allowEditing,
    };
  }
}

/// Location options
class LocationOptions {
  final String accuracy; // low, balanced, high, best
  final int? timeoutMs;
  final int? maxAgeMs;

  LocationOptions({
    this.accuracy = 'balanced',
    this.timeoutMs,
    this.maxAgeMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy,
      'timeoutMs': timeoutMs,
      'maxAgeMs': maxAgeMs,
    };
  }
}

/// Location data
class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.bearing,
    required this.timestamp,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      altitude: map['altitude']?.toDouble(),
      accuracy: map['accuracy']?.toDouble(),
      speed: map['speed']?.toDouble(),
      bearing: map['bearing']?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'bearing': bearing,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Haptic feedback types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  impact,
  notification,
}

/// Common permission constants
class Permissions {
  static const String camera = 'camera';
  static const String location = 'location';
  static const String locationWhenInUse = 'locationWhenInUse';
  static const String locationAlways = 'locationAlways';
  static const String microphone = 'microphone';
  static const String storage = 'storage';
  static const String contacts = 'contacts';
  static const String calendar = 'calendar';
  static const String photos = 'photos';
  static const String bluetooth = 'bluetooth';
  static const String notification = 'notification';
  static const String biometrics = 'biometrics';
}

/// Sensor types
class SensorTypes {
  static const String accelerometer = 'accelerometer';
  static const String gyroscope = 'gyroscope';
  static const String magnetometer = 'magnetometer';
  static const String proximity = 'proximity';
  static const String ambientLight = 'ambientLight';
  static const String barometer = 'barometer';
  static const String humidity = 'humidity';
  static const String temperature = 'temperature';
}
