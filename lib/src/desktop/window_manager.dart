import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Window management and multi-monitor support
class WindowManager extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/window_manager');

  bool _isInitialized = false;
  WindowInfo? _currentWindowInfo;
  List<MonitorInfo> _monitors = [];

  /// Check if window manager is initialized
  bool get isInitialized => _isInitialized;

  /// Get current window information
  WindowInfo? get currentWindow => _currentWindowInfo;

  /// Get available monitors
  List<MonitorInfo> get monitors => List.from(_monitors);

  /// Initialize window manager
  Future<void> initialize() async {
    if (kIsWeb || !PlatformDetector.supportsWindowManagement) {
      throw UnsupportedError(
          'Window management is not supported on this platform');
    }

    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');

      await _updateWindowInfo();
      await _updateMonitors();

      _isInitialized = true;
      emit('window-manager-initialized');

      if (kDebugMode) {
        print('WindowManager: Initialized with ${_monitors.length} monitors');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWindowMoved':
        await _updateWindowInfo();
        emit('window-moved', _currentWindowInfo);
        break;
      case 'onWindowResized':
        await _updateWindowInfo();
        emit('window-resized', _currentWindowInfo);
        break;
      case 'onWindowMinimized':
        emit('window-minimized');
        break;
      case 'onWindowMaximized':
        emit('window-maximized');
        break;
      case 'onWindowRestored':
        emit('window-restored');
        break;
      case 'onWindowFocused':
        emit('window-focused');
        break;
      case 'onWindowBlurred':
        emit('window-blurred');
        break;
      case 'onMonitorChanged':
        await _updateMonitors();
        emit('monitors-changed', _monitors);
        break;
      default:
        if (kDebugMode) {
          print('WindowManager: Unknown method call: ${call.method}');
        }
    }
  }

  /// Update current window information
  Future<void> _updateWindowInfo() async {
    try {
      final result = await _channel.invokeMethod('getWindowInfo');
      if (result != null) {
        _currentWindowInfo = WindowInfo.fromMap(result);
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to update window info: $e');
      }
    }
  }

  /// Update monitors list
  Future<void> _updateMonitors() async {
    try {
      final result =
          await _channel.invokeMethod('getMonitors') as List<dynamic>?;
      if (result != null) {
        _monitors =
            result.map((monitor) => MonitorInfo.fromMap(monitor)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to update monitors: $e');
      }
    }
  }

  /// Set window position
  Future<void> setPosition(int x, int y) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setPosition', {'x': x, 'y': y});
      await _updateWindowInfo();
      emit('position-changed', {'x': x, 'y': y});
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set position: $e');
      }
    }
  }

  /// Set window size
  Future<void> setSize(int width, int height) async {
    if (!_isInitialized) return;

    try {
      await _channel
          .invokeMethod('setSize', {'width': width, 'height': height});
      await _updateWindowInfo();
      emit('size-changed', {'width': width, 'height': height});
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set size: $e');
      }
    }
  }

  /// Set window bounds (position and size)
  Future<void> setBounds(int x, int y, int width, int height) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setBounds', {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      });
      await _updateWindowInfo();
      emit(
          'bounds-changed', {'x': x, 'y': y, 'width': width, 'height': height});
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set bounds: $e');
      }
    }
  }

  /// Minimize window
  Future<void> minimize() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('minimize');
      emit('window-minimized');
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to minimize window: $e');
      }
    }
  }

  /// Maximize window
  Future<void> maximize() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('maximize');
      emit('window-maximized');
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to maximize window: $e');
      }
    }
  }

  /// Restore window
  Future<void> restore() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('restore');
      emit('window-restored');
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to restore window: $e');
      }
    }
  }

  /// Hide window
  Future<void> hide() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('hide');
      emit('window-hidden');
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to hide window: $e');
      }
    }
  }

  /// Show window
  Future<void> show() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('show');
      emit('window-shown');
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to show window: $e');
      }
    }
  }

  /// Focus window
  Future<void> focus() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('focus');
      emit('window-focused');
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to focus window: $e');
      }
    }
  }

  /// Set window to always on top
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!_isInitialized) return;

    try {
      await _channel
          .invokeMethod('setAlwaysOnTop', {'alwaysOnTop': alwaysOnTop});
      emit('always-on-top-changed', alwaysOnTop);
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set always on top: $e');
      }
    }
  }

  /// Set window title
  Future<void> setTitle(String title) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setTitle', {'title': title});
      emit('title-changed', title);
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set title: $e');
      }
    }
  }

  /// Snap window to position (Windows)
  Future<void> snapToPosition(SnapPosition position) async {
    if (!_isInitialized || !PlatformDetector.isWindows) return;

    try {
      await _channel
          .invokeMethod('snapToPosition', {'position': position.name});
      emit('window-snapped', position.name);
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to snap window: $e');
      }
    }
  }

  /// Move window to monitor
  Future<void> moveToMonitor(int monitorIndex) async {
    if (!_isInitialized || monitorIndex >= _monitors.length) return;

    final monitor = _monitors[monitorIndex];
    final centerX = monitor.x +
        (monitor.width ~/ 2) -
        ((_currentWindowInfo?.width ?? 800) ~/ 2);
    final centerY = monitor.y +
        (monitor.height ~/ 2) -
        ((_currentWindowInfo?.height ?? 600) ~/ 2);

    await setPosition(centerX, centerY);
    emit('moved-to-monitor', monitorIndex);
  }

  /// Center window on current monitor
  Future<void> center() async {
    if (!_isInitialized || _currentWindowInfo == null) return;

    final currentMonitor = getCurrentMonitor();
    if (currentMonitor != null) {
      final centerX = currentMonitor.x +
          (currentMonitor.width ~/ 2) -
          (_currentWindowInfo!.width ~/ 2);
      final centerY = currentMonitor.y +
          (currentMonitor.height ~/ 2) -
          (_currentWindowInfo!.height ~/ 2);
      await setPosition(centerX, centerY);
      emit('window-centered');
    }
  }

  /// Get the monitor that contains the current window
  MonitorInfo? getCurrentMonitor() {
    if (_currentWindowInfo == null) return null;

    for (final monitor in _monitors) {
      if (_currentWindowInfo!.x >= monitor.x &&
          _currentWindowInfo!.x < monitor.x + monitor.width &&
          _currentWindowInfo!.y >= monitor.y &&
          _currentWindowInfo!.y < monitor.y + monitor.height) {
        return monitor;
      }
    }

    return _monitors.isNotEmpty ? _monitors.first : null;
  }

  /// Set minimum window size
  Future<void> setMinimumSize(int width, int height) async {
    if (!_isInitialized) return;

    try {
      await _channel
          .invokeMethod('setMinimumSize', {'width': width, 'height': height});
      emit('minimum-size-changed', {'width': width, 'height': height});
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set minimum size: $e');
      }
    }
  }

  /// Set maximum window size
  Future<void> setMaximumSize(int width, int height) async {
    if (!_isInitialized) return;

    try {
      await _channel
          .invokeMethod('setMaximumSize', {'width': width, 'height': height});
      emit('maximum-size-changed', {'width': width, 'height': height});
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set maximum size: $e');
      }
    }
  }

  /// Set window resizability
  Future<void> setResizable(bool resizable) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setResizable', {'resizable': resizable});
      emit('resizable-changed', resizable);
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to set resizable: $e');
      }
    }
  }

  /// Dispose window manager
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      _currentWindowInfo = null;
      _monitors.clear();
      removeAllListeners();

      if (kDebugMode) {
        print('WindowManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// Window information
class WindowInfo {
  final int x;
  final int y;
  final int width;
  final int height;
  final bool isMaximized;
  final bool isMinimized;
  final bool isVisible;
  final bool isFocused;
  final String title;

  WindowInfo({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isMaximized,
    required this.isMinimized,
    required this.isVisible,
    required this.isFocused,
    required this.title,
  });

  factory WindowInfo.fromMap(Map<String, dynamic> map) {
    return WindowInfo(
      x: map['x'] ?? 0,
      y: map['y'] ?? 0,
      width: map['width'] ?? 800,
      height: map['height'] ?? 600,
      isMaximized: map['isMaximized'] ?? false,
      isMinimized: map['isMinimized'] ?? false,
      isVisible: map['isVisible'] ?? true,
      isFocused: map['isFocused'] ?? false,
      title: map['title'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isMaximized': isMaximized,
      'isMinimized': isMinimized,
      'isVisible': isVisible,
      'isFocused': isFocused,
      'title': title,
    };
  }
}

/// Monitor information
class MonitorInfo {
  final int index;
  final int x;
  final int y;
  final int width;
  final int height;
  final double scaleFactor;
  final bool isPrimary;
  final String name;

  MonitorInfo({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.scaleFactor,
    required this.isPrimary,
    required this.name,
  });

  factory MonitorInfo.fromMap(Map<String, dynamic> map) {
    return MonitorInfo(
      index: map['index'] ?? 0,
      x: map['x'] ?? 0,
      y: map['y'] ?? 0,
      width: map['width'] ?? 1920,
      height: map['height'] ?? 1080,
      scaleFactor: (map['scaleFactor'] ?? 1.0).toDouble(),
      isPrimary: map['isPrimary'] ?? false,
      name: map['name'] ?? 'Unknown Monitor',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'scaleFactor': scaleFactor,
      'isPrimary': isPrimary,
      'name': name,
    };
  }
}

/// Window snap positions (Windows-specific)
enum SnapPosition {
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  maximize,
}
