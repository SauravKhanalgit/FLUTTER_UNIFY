import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Annotation for native module generation (similar to unify_flutter)
class UniNativeModule {
  const UniNativeModule();
}

/// Native bridge manager for mobile platforms
class NativeBridgeManager extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/native_bridge');

  bool _isInitialized = false;
  final Map<String, dynamic> _registeredModules = {};

  /// Check if native bridge is initialized
  bool get isInitialized => _isInitialized;

  /// Get registered modules
  Map<String, dynamic> get registeredModules => Map.from(_registeredModules);

  /// Initialize native bridge
  Future<void> initialize() async {
    if (kIsWeb || !PlatformDetector.isMobile) {
      throw UnsupportedError(
          'Native bridge is only supported on mobile platforms');
    }

    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');

      _isInitialized = true;
      emit('native-bridge-initialized');

      if (kDebugMode) {
        print('NativeBridgeManager: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NativeBridgeManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNativeEvent':
        final module = call.arguments['module'] as String;
        final event = call.arguments['event'] as String;
        final data = call.arguments['data'];

        emit('native-event', {
          'module': module,
          'event': event,
          'data': data,
        });
        break;

      default:
        if (kDebugMode) {
          print('NativeBridgeManager: Unknown method call: ${call.method}');
        }
    }
  }

  /// Register a native module
  Future<bool> registerModule(
      String moduleName, Map<String, dynamic> config) async {
    if (!_isInitialized) {
      throw StateError('NativeBridgeManager must be initialized first');
    }

    try {
      final result = await _channel.invokeMethod('registerModule', {
        'moduleName': moduleName,
        'config': config,
      }) as bool?;

      if (result == true) {
        _registeredModules[moduleName] = config;
        emit('module-registered', moduleName);

        if (kDebugMode) {
          print('NativeBridgeManager: Registered module: $moduleName');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('NativeBridgeManager: Failed to register module $moduleName: $e');
      }
      return false;
    }
  }

  /// Call native method
  Future<T?> callNativeMethod<T>(
    String moduleName,
    String methodName,
    Map<String, dynamic> arguments,
  ) async {
    if (!_isInitialized) return null;
    if (!_registeredModules.containsKey(moduleName)) {
      throw ArgumentError('Module $moduleName is not registered');
    }

    try {
      final result = await _channel.invokeMethod('callNativeMethod', {
        'moduleName': moduleName,
        'methodName': methodName,
        'arguments': arguments,
      });

      return result as T?;
    } catch (e) {
      if (kDebugMode) {
        print(
            'NativeBridgeManager: Failed to call $moduleName.$methodName: $e');
      }
      return null;
    }
  }

  /// Check if module is registered
  bool isModuleRegistered(String moduleName) {
    return _registeredModules.containsKey(moduleName);
  }

  /// Unregister module
  Future<bool> unregisterModule(String moduleName) async {
    if (!_isInitialized) return false;
    if (!_registeredModules.containsKey(moduleName)) return false;

    try {
      final result = await _channel.invokeMethod('unregisterModule', {
        'moduleName': moduleName,
      }) as bool?;

      if (result == true) {
        _registeredModules.remove(moduleName);
        emit('module-unregistered', moduleName);

        if (kDebugMode) {
          print('NativeBridgeManager: Unregistered module: $moduleName');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'NativeBridgeManager: Failed to unregister module $moduleName: $e');
      }
      return false;
    }
  }

  /// Get available native capabilities
  Future<List<String>> getAvailableCapabilities() async {
    if (!_isInitialized) return [];

    try {
      final result = await _channel.invokeMethod('getAvailableCapabilities')
          as List<dynamic>?;
      return result?.cast<String>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('NativeBridgeManager: Failed to get capabilities: $e');
      }
      return [];
    }
  }

  /// Dispose native bridge
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      _registeredModules.clear();
      removeAllListeners();

      if (kDebugMode) {
        print('NativeBridgeManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NativeBridgeManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// Example device module implementation
@UniNativeModule()
abstract class DeviceModule {
  Future<String> platformVersion();
  Future<String> deviceModel();
  Future<Map<String, dynamic>> systemInfo();
}

/// Example camera module implementation
@UniNativeModule()
abstract class CameraModule {
  Future<bool> hasCamera();
  Future<List<String>> getAvailableCameras();
  Future<String?> takePicture({String? quality});
  Future<String?> recordVideo({int? maxDuration});
}

/// Example location module implementation
@UniNativeModule()
abstract class LocationModule {
  Future<bool> hasLocationPermission();
  Future<bool> requestLocationPermission();
  Future<Map<String, double>?> getCurrentLocation();
  Future<void> startLocationTracking();
  Future<void> stopLocationTracking();
}
