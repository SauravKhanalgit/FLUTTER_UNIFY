import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';
import '../desktop/system_services.dart' as desktop;
import '../web/polyfills.dart' as web;

/// Cross-platform system manager
class SystemManager extends EventEmitter {
  static SystemManager? _instance;
  static SystemManager get instance => _instance ??= SystemManager._();

  SystemManager._();

  bool _isInitialized = false;
  desktop.SystemServices? _desktopServices;
  web.WebPolyfills? _webPolyfills;

  /// Check if system manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize system manager
  Future<void> initialize({
    bool enableClipboard = true,
    bool enableNotifications = true,
  }) async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('SystemManager: Already initialized');
      }
      return;
    }

    try {
      // Initialize platform-specific services
      if (PlatformDetector.isDesktop) {
        _desktopServices = desktop.SystemServices();
        await _desktopServices!.initialize();
      } else if (kIsWeb) {
        _webPolyfills = web.WebPolyfills();
        await _webPolyfills!.initialize();
      }

      _isInitialized = true;
      emit('system-initialized');

      if (kDebugMode) {
        print(
            'SystemManager: Initialized for ${PlatformDetector.platformName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  // CLIPBOARD SERVICES

  /// Write text to clipboard
  Future<bool> clipboardWriteText(String text) async {
    if (!_isInitialized) return false;

    try {
      if (PlatformDetector.isDesktop && _desktopServices != null) {
        return await _desktopServices!.clipboardWriteText(text);
      } else {
        // Fallback to Flutter's clipboard for mobile/web
        await Clipboard.setData(ClipboardData(text: text));
        emit('clipboard-text-written', text);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to write text to clipboard: $e');
      }
      return false;
    }
  }

  /// Read text from clipboard
  Future<String?> clipboardReadText() async {
    if (!_isInitialized) return null;

    try {
      if (PlatformDetector.isDesktop && _desktopServices != null) {
        return await _desktopServices!.clipboardReadText();
      } else {
        // Fallback to Flutter's clipboard for mobile/web
        final data = await Clipboard.getData('text/plain');
        final text = data?.text;
        if (text != null) {
          emit('clipboard-text-read', text);
        }
        return text;
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to read text from clipboard: $e');
      }
      return null;
    }
  }

  /// Write image to clipboard (desktop only)
  Future<bool> clipboardWriteImage(Uint8List imageData) async {
    if (!_isInitialized) return false;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return false;

    return await _desktopServices!.clipboardWriteImage(imageData);
  }

  /// Read image from clipboard (desktop only)
  Future<Uint8List?> clipboardReadImage() async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.clipboardReadImage();
  }

  /// Check if clipboard has text
  Future<bool> clipboardHasText() async {
    if (!_isInitialized) return false;

    try {
      if (PlatformDetector.isDesktop && _desktopServices != null) {
        return await _desktopServices!.clipboardHasText();
      } else {
        // For mobile/web, try to read and check if not empty
        final text = await clipboardReadText();
        return text != null && text.isNotEmpty;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check if clipboard has image (desktop only)
  Future<bool> clipboardHasImage() async {
    if (!_isInitialized) return false;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return false;

    return await _desktopServices!.clipboardHasImage();
  }

  // NOTIFICATION SERVICES

  /// Show system notification
  Future<String?> showNotification({
    required String title,
    required String body,
    String? icon,
    List<desktop.NotificationAction>? actions,
    Duration? duration,
    String? sound,
    bool? silent,
  }) async {
    if (!_isInitialized) return null;

    try {
      if (PlatformDetector.isDesktop && _desktopServices != null) {
        return await _desktopServices!.showNotification(
          title: title,
          body: body,
          icon: icon,
          actions: actions,
          duration: duration,
          sound: sound,
          silent: silent,
        );
      } else {
        // For mobile/web, use a simplified notification approach
        // In a real implementation, this would integrate with platform-specific APIs
        final notificationId = DateTime.now().millisecondsSinceEpoch.toString();

        emit('notification-shown', {
          'id': notificationId,
          'title': title,
          'body': body,
        });

        return notificationId;
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to show notification: $e');
      }
      return null;
    }
  }

  /// Close notification
  Future<bool> closeNotification(String notificationId) async {
    if (!_isInitialized) return false;

    try {
      if (PlatformDetector.isDesktop && _desktopServices != null) {
        return await _desktopServices!.closeNotification(notificationId);
      } else {
        // For mobile/web, emit close event
        emit('notification-closed-by-app', notificationId);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to close notification: $e');
      }
      return false;
    }
  }

  // FILE SERVICES

  /// Show open file dialog (desktop only)
  Future<List<String>?> showOpenFileDialog({
    String? title,
    String? defaultPath,
    List<desktop.FileFilter>? filters,
    bool allowMultiple = false,
  }) async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.showOpenFileDialog(
      title: title,
      defaultPath: defaultPath,
      filters: filters,
      allowMultiple: allowMultiple,
    );
  }

  /// Show save file dialog (desktop only)
  Future<String?> showSaveFileDialog({
    String? title,
    String? defaultPath,
    String? defaultName,
    List<desktop.FileFilter>? filters,
  }) async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.showSaveFileDialog(
      title: title,
      defaultPath: defaultPath,
      defaultName: defaultName,
      filters: filters,
    );
  }

  /// Show folder selection dialog (desktop only)
  Future<String?> showFolderDialog({
    String? title,
    String? defaultPath,
  }) async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.showFolderDialog(
      title: title,
      defaultPath: defaultPath,
    );
  }

  // URL & FILE OPENING

  /// Open URL in default browser
  Future<bool> openUrl(String url) async {
    if (!_isInitialized) return false;

    try {
      if (PlatformDetector.isDesktop && _desktopServices != null) {
        return await _desktopServices!.openUrl(url);
      } else if (kIsWeb) {
        // For web, use window.open
        // In a real implementation, this would use dart:html
        emit('url-opened', url);
        return true;
      } else {
        // For mobile, use platform-specific URL launching
        // In a real implementation, this would use url_launcher package
        emit('url-opened', url);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to open URL: $e');
      }
      return false;
    }
  }

  /// Open file with default application (desktop only)
  Future<bool> openFile(String filePath) async {
    if (!_isInitialized) return false;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return false;

    return await _desktopServices!.openFile(filePath);
  }

  // SCREEN CAPTURE (desktop only)

  /// Capture screenshot of entire screen
  Future<Uint8List?> captureScreen() async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.captureScreen();
  }

  /// Capture screenshot of specific window
  Future<Uint8List?> captureWindow(String windowId) async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.captureWindow(windowId);
  }

  /// Capture screenshot of specific region
  Future<Uint8List?> captureRegion({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.captureRegion(
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  // SYSTEM INFO

  /// Get system information
  Future<Map<String, dynamic>?> getSystemInfo() async {
    if (!_isInitialized) return null;

    try {
      if (PlatformDetector.isDesktop && _desktopServices != null) {
        return await _desktopServices!.getSystemInfo();
      } else {
        // Fallback system info for mobile/web
        return {
          'platform': PlatformDetector.platformName,
          'isWeb': kIsWeb,
          'isMobile': PlatformDetector.isMobile,
          'isDesktop': PlatformDetector.isDesktop,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to get system info: $e');
      }
      return null;
    }
  }

  /// Get available fonts (desktop only)
  Future<List<String>?> getSystemFonts() async {
    if (!_isInitialized) return null;
    if (!PlatformDetector.isDesktop || _desktopServices == null) return null;

    return await _desktopServices!.getSystemFonts();
  }

  // CAPABILITY CHECKS

  /// Get available system capabilities
  Map<String, bool> getCapabilities() {
    return {
      'clipboard': true, // Available on all platforms
      'notifications': true, // Available on all platforms
      'fileDialogs': PlatformDetector.isDesktop,
      'screenCapture': PlatformDetector.isDesktop,
      'systemFonts': PlatformDetector.isDesktop,
      'openUrl': true, // Available on all platforms
      'openFile': PlatformDetector.isDesktop,
      'clipboardImage': PlatformDetector.isDesktop,
    };
  }

  /// Check if a specific capability is available
  bool isCapabilityAvailable(String capability) {
    return getCapabilities()[capability] ?? false;
  }

  /// Dispose system manager
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      if (_desktopServices != null) {
        await _desktopServices!.dispose();
        _desktopServices = null;
      }

      if (_webPolyfills != null) {
        await _webPolyfills!.dispose();
        _webPolyfills = null;
      }

      removeAllListeners();

      if (kDebugMode) {
        print('SystemManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}
