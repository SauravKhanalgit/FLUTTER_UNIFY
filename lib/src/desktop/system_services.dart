import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// System services bridge (clipboard, notifications, file dialogs, etc.)
class SystemServices extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/system_services');

  bool _isInitialized = false;

  /// Check if system services are initialized
  bool get isInitialized => _isInitialized;

  /// Initialize system services
  Future<void> initialize() async {
    if (kIsWeb || !PlatformDetector.isDesktop) {
      throw UnsupportedError(
          'System services are not supported on this platform');
    }

    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');

      _isInitialized = true;
      emit('system-services-initialized');

      if (kDebugMode) {
        print('SystemServices: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationClicked':
        final notificationId = call.arguments['id'] as String;
        emit('notification-clicked', notificationId);
        break;

      case 'onNotificationClosed':
        final notificationId = call.arguments['id'] as String;
        emit('notification-closed', notificationId);
        break;

      default:
        if (kDebugMode) {
          print('SystemServices: Unknown method call: ${call.method}');
        }
    }
  }

  // CLIPBOARD SERVICES

  /// Write text to clipboard
  Future<bool> clipboardWriteText(String text) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('clipboardWriteText', {
        'text': text,
      }) as bool?;

      if (result == true) {
        emit('clipboard-text-written', text);
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to write text to clipboard: $e');
      }
      return false;
    }
  }

  /// Read text from clipboard
  Future<String?> clipboardReadText() async {
    if (!_isInitialized) return null;

    try {
      final result =
          await _channel.invokeMethod('clipboardReadText') as String?;

      if (result != null) {
        emit('clipboard-text-read', result);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to read text from clipboard: $e');
      }
      return null;
    }
  }

  /// Write image to clipboard
  Future<bool> clipboardWriteImage(Uint8List imageData) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('clipboardWriteImage', {
        'imageData': imageData,
      }) as bool?;

      if (result == true) {
        emit('clipboard-image-written', imageData.length);
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to write image to clipboard: $e');
      }
      return false;
    }
  }

  /// Read image from clipboard
  Future<Uint8List?> clipboardReadImage() async {
    if (!_isInitialized) return null;

    try {
      final result =
          await _channel.invokeMethod('clipboardReadImage') as Uint8List?;

      if (result != null) {
        emit('clipboard-image-read', result.length);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to read image from clipboard: $e');
      }
      return null;
    }
  }

  /// Check if clipboard has text
  Future<bool> clipboardHasText() async {
    if (!_isInitialized) return false;

    try {
      return await _channel.invokeMethod('clipboardHasText') as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to check clipboard text: $e');
      }
      return false;
    }
  }

  /// Check if clipboard has image
  Future<bool> clipboardHasImage() async {
    if (!_isInitialized) return false;

    try {
      return await _channel.invokeMethod('clipboardHasImage') as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to check clipboard image: $e');
      }
      return false;
    }
  }

  // NOTIFICATION SERVICES

  /// Show system notification
  Future<String?> showNotification({
    required String title,
    required String body,
    String? icon,
    List<NotificationAction>? actions,
    Duration? duration,
    String? sound,
    bool? silent,
  }) async {
    if (!_isInitialized) return null;

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();

      final result = await _channel.invokeMethod('showNotification', {
        'id': notificationId,
        'title': title,
        'body': body,
        'icon': icon,
        'actions': actions?.map((action) => action.toMap()).toList(),
        'duration': duration?.inMilliseconds,
        'sound': sound,
        'silent': silent,
      }) as bool?;

      if (result == true) {
        emit('notification-shown', {
          'id': notificationId,
          'title': title,
          'body': body,
        });
        return notificationId;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to show notification: $e');
      }
      return null;
    }
  }

  /// Close notification
  Future<bool> closeNotification(String notificationId) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('closeNotification', {
        'id': notificationId,
      }) as bool?;

      if (result == true) {
        emit('notification-closed-by-app', notificationId);
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to close notification: $e');
      }
      return false;
    }
  }

  // FILE DIALOG SERVICES

  /// Show open file dialog
  Future<List<String>?> showOpenFileDialog({
    String? title,
    String? defaultPath,
    List<FileFilter>? filters,
    bool allowMultiple = false,
  }) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('showOpenFileDialog', {
        'title': title,
        'defaultPath': defaultPath,
        'filters': filters?.map((filter) => filter.toMap()).toList(),
        'allowMultiple': allowMultiple,
      }) as List<dynamic>?;

      final files = result?.cast<String>();

      if (files != null && files.isNotEmpty) {
        emit('files-selected', files);
      }

      return files;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to show open file dialog: $e');
      }
      return null;
    }
  }

  /// Show save file dialog
  Future<String?> showSaveFileDialog({
    String? title,
    String? defaultPath,
    String? defaultName,
    List<FileFilter>? filters,
  }) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('showSaveFileDialog', {
        'title': title,
        'defaultPath': defaultPath,
        'defaultName': defaultName,
        'filters': filters?.map((filter) => filter.toMap()).toList(),
      }) as String?;

      if (result != null) {
        emit('save-file-selected', result);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to show save file dialog: $e');
      }
      return null;
    }
  }

  /// Show folder selection dialog
  Future<String?> showFolderDialog({
    String? title,
    String? defaultPath,
  }) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('showFolderDialog', {
        'title': title,
        'defaultPath': defaultPath,
      }) as String?;

      if (result != null) {
        emit('folder-selected', result);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to show folder dialog: $e');
      }
      return null;
    }
  }

  // SCREEN CAPTURE SERVICES

  /// Capture screenshot of entire screen
  Future<Uint8List?> captureScreen() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('captureScreen') as Uint8List?;

      if (result != null) {
        emit('screen-captured', result.length);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to capture screen: $e');
      }
      return null;
    }
  }

  /// Capture screenshot of specific window
  Future<Uint8List?> captureWindow(String windowId) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('captureWindow', {
        'windowId': windowId,
      }) as Uint8List?;

      if (result != null) {
        emit('window-captured', {'windowId': windowId, 'size': result.length});
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to capture window: $e');
      }
      return null;
    }
  }

  /// Capture screenshot of specific region
  Future<Uint8List?> captureRegion({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('captureRegion', {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      }) as Uint8List?;

      if (result != null) {
        emit('region-captured', {
          'bounds': {'x': x, 'y': y, 'width': width, 'height': height},
          'size': result.length,
        });
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to capture region: $e');
      }
      return null;
    }
  }

  // SYSTEM INFO SERVICES

  /// Get system information
  Future<Map<String, dynamic>?> getSystemInfo() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('getSystemInfo')
          as Map<dynamic, dynamic>?;
      return result?.cast<String, dynamic>();
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to get system info: $e');
      }
      return null;
    }
  }

  /// Get available fonts
  Future<List<String>?> getSystemFonts() async {
    if (!_isInitialized) return null;

    try {
      final result =
          await _channel.invokeMethod('getSystemFonts') as List<dynamic>?;
      return result?.cast<String>();
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to get system fonts: $e');
      }
      return null;
    }
  }

  /// Open URL in default browser
  Future<bool> openUrl(String url) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('openUrl', {
        'url': url,
      }) as bool?;

      if (result == true) {
        emit('url-opened', url);
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to open URL: $e');
      }
      return false;
    }
  }

  /// Open file with default application
  Future<bool> openFile(String filePath) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('openFile', {
        'filePath': filePath,
      }) as bool?;

      if (result == true) {
        emit('file-opened', filePath);
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to open file: $e');
      }
      return false;
    }
  }

  /// Dispose system services
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      removeAllListeners();

      if (kDebugMode) {
        print('SystemServices: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemServices: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// Notification action
class NotificationAction {
  final String id;
  final String title;
  final String? icon;

  NotificationAction({
    required this.id,
    required this.title,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
    };
  }

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      icon: map['icon'],
    );
  }
}

/// File filter for dialogs
class FileFilter {
  final String name;
  final List<String> extensions;

  FileFilter({
    required this.name,
    required this.extensions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'extensions': extensions,
    };
  }

  factory FileFilter.fromMap(Map<String, dynamic> map) {
    return FileFilter(
      name: map['name'] ?? '',
      extensions: (map['extensions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Common file filters
  static FileFilter get images => FileFilter(
        name: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp'],
      );

  static FileFilter get documents => FileFilter(
        name: 'Documents',
        extensions: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'],
      );

  static FileFilter get videos => FileFilter(
        name: 'Videos',
        extensions: ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'],
      );

  static FileFilter get audio => FileFilter(
        name: 'Audio',
        extensions: ['mp3', 'wav', 'flac', 'aac', 'ogg', 'wma'],
      );

  static FileFilter get allFiles => FileFilter(
        name: 'All Files',
        extensions: ['*'],
      );
}
