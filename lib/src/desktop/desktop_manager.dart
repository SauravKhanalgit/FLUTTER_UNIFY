import 'dart:async';
import 'package:flutter/foundation.dart';

import 'system_tray.dart';
import 'window_manager.dart';
import 'drag_drop.dart';
import 'shortcuts.dart';
import 'system_services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Desktop integration manager
class DesktopManager extends EventEmitter {
  static DesktopManager? _instance;
  static DesktopManager get instance => _instance ??= DesktopManager._();

  DesktopManager._();

  late SystemTrayManager _systemTray;
  late WindowManager _windowManager;
  late DragDropManager _dragDrop;
  late ShortcutsManager _shortcuts;
  late SystemServices _systemServices;

  bool _isInitialized = false;
  bool _systemTrayEnabled = false;
  bool _windowManagerEnabled = false;
  bool _dragDropEnabled = false;
  bool _shortcutsEnabled = false;

  /// Get the system tray manager
  SystemTrayManager get systemTray => _systemTray;

  /// Get the window manager
  WindowManager get windowManager => _windowManager;

  /// Get the drag & drop manager
  DragDropManager get dragDrop => _dragDrop;

  /// Get the shortcuts manager
  ShortcutsManager get shortcuts => _shortcuts;

  /// Get the system services
  SystemServices get systemServices => _systemServices;

  /// Check if desktop manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize desktop integrations
  Future<void> initialize({
    bool enableSystemTray = true,
    bool enableGlobalShortcuts = true,
    bool enableDragDrop = true,
    bool enableWindowManager = true,
  }) async {
    if (kIsWeb || !PlatformDetector.isDesktop) {
      throw UnsupportedError(
          'DesktopManager can only be used on desktop platforms');
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('DesktopManager: Already initialized');
      }
      return;
    }

    _systemTrayEnabled = enableSystemTray;
    _windowManagerEnabled = enableWindowManager;
    _dragDropEnabled = enableDragDrop;
    _shortcutsEnabled = enableGlobalShortcuts;

    // Initialize components
    if (_systemTrayEnabled && PlatformDetector.supportsSystemTray) {
      _systemTray = SystemTrayManager();
      await _systemTray.initialize();
    }

    if (_windowManagerEnabled && PlatformDetector.supportsWindowManagement) {
      _windowManager = WindowManager();
      await _windowManager.initialize();
    }

    if (_dragDropEnabled && PlatformDetector.supportsDragDrop) {
      _dragDrop = DragDropManager();
      await _dragDrop.initialize();
    }

    if (_shortcutsEnabled && PlatformDetector.supportsGlobalShortcuts) {
      _shortcuts = ShortcutsManager();
      await _shortcuts.initialize();
    }

    // Always initialize system services
    _systemServices = SystemServices();
    await _systemServices.initialize();

    _isInitialized = true;
    emit('desktop-initialized');

    if (kDebugMode) {
      print('DesktopManager: Initialized with features - '
          'SystemTray: $_systemTrayEnabled, '
          'WindowManager: $_windowManagerEnabled, '
          'DragDrop: $_dragDropEnabled, '
          'Shortcuts: $_shortcutsEnabled');
    }
  }

  /// Get desktop capabilities
  Map<String, bool> getCapabilities() {
    return {
      'systemTray': _systemTrayEnabled && PlatformDetector.supportsSystemTray,
      'windowManager':
          _windowManagerEnabled && PlatformDetector.supportsWindowManagement,
      'dragDrop': _dragDropEnabled && PlatformDetector.supportsDragDrop,
      'shortcuts':
          _shortcutsEnabled && PlatformDetector.supportsGlobalShortcuts,
      'systemServices': true, // Always available on desktop
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
      'isWindows': PlatformDetector.isWindows,
      'isMacOS': PlatformDetector.isMacOS,
      'isLinux': PlatformDetector.isLinux,
      'capabilities': PlatformDetector.instance.capabilities,
    };
  }

  /// Dispose of all desktop resources
  Future<void> dispose() async {
    if (_systemTrayEnabled) {
      await _systemTray.dispose();
    }

    if (_windowManagerEnabled) {
      await _windowManager.dispose();
    }

    if (_dragDropEnabled) {
      await _dragDrop.dispose();
    }

    if (_shortcutsEnabled) {
      await _shortcuts.dispose();
    }

    await _systemServices.dispose();

    removeAllListeners();
    _isInitialized = false;

    if (kDebugMode) {
      print('DesktopManager: Disposed all resources');
    }
  }
}
