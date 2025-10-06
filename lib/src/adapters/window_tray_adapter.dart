import 'dart:async';
import '../common/platform_detector.dart';
import '../desktop/window_manager.dart' as wm;
import '../desktop/system_tray.dart' as tray;

/// Unified adapter for desktop window & tray management
abstract class WindowTrayAdapter {
  Future<void> initialize({
    bool enableWindowManager = true,
    bool enableSystemTray = true,
  });

  // Window controls
  Future<void> setTitle(String title);
  Future<void> show();
  Future<void> hide();
  Future<void> focus();
  Future<void> setSize(int width, int height);
  Future<void> center();
  Future<void> setAlwaysOnTop(bool value);

  // Tray
  Future<void> createTray({
    required String icon,
    String? tooltip,
    List<tray.SystemTrayMenuItem>? menuItems,
  });
  Future<void> updateTrayMenu(List<tray.SystemTrayMenuItem> menuItems);
}

class DesktopWindowTrayAdapter implements WindowTrayAdapter {
  wm.WindowManager? _wm;
  tray.SystemTrayManager? _tray;
  bool _wmEnabled = false;
  bool _trayEnabled = false;

  @override
  Future<void> initialize({
    bool enableWindowManager = true,
    bool enableSystemTray = true,
  }) async {
    if (!PlatformDetector.isDesktop) return;

    _wmEnabled = enableWindowManager;
    _trayEnabled = enableSystemTray;

    if (_wmEnabled) {
      _wm = wm.WindowManager();
      await _wm!.initialize();
    }
    if (_trayEnabled) {
      _tray = tray.SystemTrayManager();
      await _tray!.initialize();
    }
  }

  @override
  Future<void> setTitle(String title) async {
    if (_wmEnabled && _wm != null) {
      await _wm!.setTitle(title);
    }
  }

  @override
  Future<void> show() async {
    if (_wmEnabled && _wm != null) {
      await _wm!.show();
    }
  }

  @override
  Future<void> hide() async {
    if (_wmEnabled && _wm != null) {
      await _wm!.hide();
    }
  }

  @override
  Future<void> focus() async {
    if (_wmEnabled && _wm != null) {
      await _wm!.focus();
    }
  }

  @override
  Future<void> setSize(int width, int height) async {
    if (_wmEnabled && _wm != null) {
      await _wm!.setSize(width, height);
    }
  }

  @override
  Future<void> center() async {
    if (_wmEnabled && _wm != null) {
      await _wm!.center();
    }
  }

  @override
  Future<void> setAlwaysOnTop(bool value) async {
    if (_wmEnabled && _wm != null) {
      await _wm!.setAlwaysOnTop(value);
    }
  }

  @override
  Future<void> createTray({
    required String icon,
    String? tooltip,
    List<tray.SystemTrayMenuItem>? menuItems,
  }) async {
    if (_trayEnabled && _tray != null) {
      await _tray!.create(icon: icon, tooltip: tooltip, menuItems: menuItems);
    }
  }

  @override
  Future<void> updateTrayMenu(List<tray.SystemTrayMenuItem> menuItems) async {
    if (_trayEnabled && _tray != null) {
      await _tray!.setContextMenu(menuItems);
    }
  }
}
