import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for detecting the current platform and its capabilities
class PlatformDetector {
  static PlatformDetector? _instance;
  static PlatformDetector get instance => _instance ??= PlatformDetector._();

  PlatformDetector._();

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if running on desktop (Windows, macOS, or Linux)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Get the current platform name
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Check if the platform supports system tray
  static bool get supportsSystemTray => isDesktop;

  /// Check if the platform supports global shortcuts
  static bool get supportsGlobalShortcuts => isDesktop;

  /// Check if the platform supports native drag and drop
  static bool get supportsDragDrop => isDesktop || isWeb;

  /// Check if the platform supports window management
  static bool get supportsWindowManagement => isDesktop;

  /// Check if the platform supports file system access
  static bool get supportsFileSystem => isDesktop || isWeb;

  /// Check if the platform supports clipboard access
  static bool get supportsClipboard => true; // All platforms support clipboard

  /// Check if the platform supports notifications
  static bool get supportsNotifications =>
      true; // All platforms support notifications

  /// Get platform-specific capabilities
  Map<String, bool> get capabilities => {
        'systemTray': supportsSystemTray,
        'globalShortcuts': supportsGlobalShortcuts,
        'dragDrop': supportsDragDrop,
        'windowManagement': supportsWindowManagement,
        'fileSystem': supportsFileSystem,
        'clipboard': supportsClipboard,
        'notifications': supportsNotifications,
      };

  /// Check if a specific feature is supported
  bool isFeatureSupported(String feature) {
    return capabilities[feature] ?? false;
  }
}
