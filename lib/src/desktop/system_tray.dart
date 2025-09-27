import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// System tray icon and menu management
class SystemTrayManager extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/system_tray');

  bool _isInitialized = false;
  bool _isVisible = false;
  String? _currentIcon;
  String? _currentTooltip;
  List<SystemTrayMenuItem> _menuItems = [];

  /// Check if system tray is initialized
  bool get isInitialized => _isInitialized;

  /// Check if system tray icon is visible
  bool get isVisible => _isVisible;

  /// Get current icon path
  String? get currentIcon => _currentIcon;

  /// Get current tooltip
  String? get currentTooltip => _currentTooltip;

  /// Get menu items
  List<SystemTrayMenuItem> get menuItems => List.from(_menuItems);

  /// Initialize system tray
  Future<void> initialize() async {
    if (kIsWeb || !PlatformDetector.supportsSystemTray) {
      throw UnsupportedError('System tray is not supported on this platform');
    }

    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');

      _isInitialized = true;
      emit('system-tray-initialized');

      if (kDebugMode) {
        print('SystemTrayManager: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTrayIconClicked':
        emit('icon-clicked');
        break;
      case 'onTrayIconRightClicked':
        emit('icon-right-clicked');
        break;
      case 'onMenuItemClicked':
        final itemId = call.arguments['itemId'] as String;
        emit('menu-item-clicked', itemId);
        _handleMenuItemClick(itemId);
        break;
      default:
        if (kDebugMode) {
          print('SystemTrayManager: Unknown method call: ${call.method}');
        }
    }
  }

  /// Create system tray icon
  Future<void> create({
    required String icon,
    String? tooltip,
    List<SystemTrayMenuItem>? menuItems,
  }) async {
    if (!_isInitialized) {
      throw StateError('SystemTrayManager must be initialized first');
    }

    try {
      await _channel.invokeMethod('create', {
        'icon': icon,
        'tooltip': tooltip ?? '',
        'menuItems': menuItems?.map((item) => item.toMap()).toList() ?? [],
      });

      _currentIcon = icon;
      _currentTooltip = tooltip;
      _menuItems = menuItems ?? [];
      _isVisible = true;

      emit('tray-created', {
        'icon': icon,
        'tooltip': tooltip,
        'menuItems': _menuItems.length,
      });

      if (kDebugMode) {
        print(
            'SystemTrayManager: Tray icon created with ${_menuItems.length} menu items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to create tray icon: $e');
      }
      rethrow;
    }
  }

  /// Update tray icon
  Future<void> setIcon(String icon) async {
    if (!_isVisible) return;

    try {
      await _channel.invokeMethod('setIcon', {'icon': icon});
      _currentIcon = icon;
      emit('icon-updated', icon);
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to update icon: $e');
      }
    }
  }

  /// Update tooltip
  Future<void> setTooltip(String tooltip) async {
    if (!_isVisible) return;

    try {
      await _channel.invokeMethod('setTooltip', {'tooltip': tooltip});
      _currentTooltip = tooltip;
      emit('tooltip-updated', tooltip);
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to update tooltip: $e');
      }
    }
  }

  /// Update context menu
  Future<void> setContextMenu(List<SystemTrayMenuItem> menuItems) async {
    if (!_isVisible) return;

    try {
      await _channel.invokeMethod('setContextMenu', {
        'menuItems': menuItems.map((item) => item.toMap()).toList(),
      });

      _menuItems = menuItems;
      emit('menu-updated', _menuItems.length);

      if (kDebugMode) {
        print(
            'SystemTrayManager: Context menu updated with ${_menuItems.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to update context menu: $e');
      }
    }
  }

  /// Add menu item
  Future<void> addMenuItem(SystemTrayMenuItem item) async {
    _menuItems.add(item);
    await setContextMenu(_menuItems);
  }

  /// Remove menu item by ID
  Future<void> removeMenuItem(String itemId) async {
    _menuItems.removeWhere((item) => item.id == itemId);
    await setContextMenu(_menuItems);
  }

  /// Handle menu item click
  void _handleMenuItemClick(String itemId) {
    final item = _menuItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => SystemTrayMenuItem(id: '', label: ''),
    );

    if (item.id.isNotEmpty && item.onClicked != null) {
      item.onClicked!();
    }
  }

  /// Show notification bubble (Windows only)
  Future<void> showNotification({
    required String title,
    required String message,
    String? icon,
    Duration? duration,
  }) async {
    if (!PlatformDetector.isWindows || !_isVisible) return;

    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'message': message,
        'icon': icon,
        'duration': duration?.inMilliseconds ?? 5000,
      });

      emit('notification-shown', {
        'title': title,
        'message': message,
      });
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to show notification: $e');
      }
    }
  }

  /// Hide system tray icon
  Future<void> hide() async {
    if (!_isVisible) return;

    try {
      await _channel.invokeMethod('hide');
      _isVisible = false;
      emit('tray-hidden');
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to hide tray icon: $e');
      }
    }
  }

  /// Show system tray icon
  Future<void> show() async {
    if (_isVisible || _currentIcon == null) return;

    await create(
      icon: _currentIcon!,
      tooltip: _currentTooltip,
      menuItems: _menuItems,
    );
  }

  /// Dispose system tray
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      _isVisible = false;
      _currentIcon = null;
      _currentTooltip = null;
      _menuItems.clear();
      removeAllListeners();

      if (kDebugMode) {
        print('SystemTrayManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemTrayManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// System tray menu item
class SystemTrayMenuItem {
  final String id;
  final String label;
  final String? icon;
  final bool enabled;
  final bool checked;
  final bool isSeparator;
  final List<SystemTrayMenuItem> submenu;
  final VoidCallback? onClicked;

  SystemTrayMenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.enabled = true,
    this.checked = false,
    this.isSeparator = false,
    this.submenu = const [],
    this.onClicked,
  });

  /// Create a separator menu item
  factory SystemTrayMenuItem.separator() {
    return SystemTrayMenuItem(
      id: 'separator_${DateTime.now().millisecondsSinceEpoch}',
      label: '',
      isSeparator: true,
    );
  }

  /// Convert to map for platform channels
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'icon': icon,
      'enabled': enabled,
      'checked': checked,
      'isSeparator': isSeparator,
      'submenu': submenu.map((item) => item.toMap()).toList(),
    };
  }

  /// Create from map
  factory SystemTrayMenuItem.fromMap(Map<String, dynamic> map) {
    return SystemTrayMenuItem(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      icon: map['icon'],
      enabled: map['enabled'] ?? true,
      checked: map['checked'] ?? false,
      isSeparator: map['isSeparator'] ?? false,
      submenu: (map['submenu'] as List<dynamic>?)
              ?.map((item) => SystemTrayMenuItem.fromMap(item))
              .toList() ??
          [],
    );
  }
}
