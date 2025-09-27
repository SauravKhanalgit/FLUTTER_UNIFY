import 'dart:async';
import 'package:flutter/foundation.dart';

import 'web/web_optimizer.dart';
import 'desktop/desktop_manager.dart';
import 'common/platform_detector.dart';

/// Main entry point for Flutter Unify functionality
class FlutterUnify {
  static FlutterUnify? _instance;
  static FlutterUnify get instance => _instance ??= FlutterUnify._();

  FlutterUnify._();

  /// Web optimization tools
  static WebOptimizer get web => WebOptimizer.instance;

  /// Desktop integration tools
  static DesktopManager get desktop => DesktopManager.instance;

  /// Platform detection utilities
  static PlatformDetector get platform => PlatformDetector.instance;

  /// Initialize Flutter Unify for web platforms
  static Future<void> initializeWeb({
    bool enableSmartBundling = true,
    bool enableSEO = true,
    bool enableProgressiveLoading = false,
    bool enablePolyfills = true,
  }) async {
    if (!kIsWeb) {
      if (kDebugMode) {
        print('FlutterUnify: Web initialization skipped - not running on web');
      }
      return;
    }

    await web.initialize(
      enableSmartBundling: enableSmartBundling,
      enableSEO: enableSEO,
      enableProgressiveLoading: enableProgressiveLoading,
      enablePolyfills: enablePolyfills,
    );

    if (kDebugMode) {
      print('FlutterUnify: Web optimizations initialized');
    }
  }

  /// Initialize Flutter Unify for desktop platforms
  static Future<void> initializeDesktop({
    bool enableSystemTray = true,
    bool enableGlobalShortcuts = true,
    bool enableDragDrop = true,
    bool enableWindowManager = true,
  }) async {
    if (kIsWeb || (!PlatformDetector.isDesktop)) {
      if (kDebugMode) {
        print(
            'FlutterUnify: Desktop initialization skipped - not running on desktop');
      }
      return;
    }

    await desktop.initialize(
      enableSystemTray: enableSystemTray,
      enableGlobalShortcuts: enableGlobalShortcuts,
      enableDragDrop: enableDragDrop,
      enableWindowManager: enableWindowManager,
    );

    if (kDebugMode) {
      print('FlutterUnify: Desktop integrations initialized');
    }
  }

  /// Initialize Flutter Unify automatically based on platform
  static Future<void> initializeAuto({
    // Web options
    bool enableSmartBundling = true,
    bool enableSEO = true,
    bool enableProgressiveLoading = false,
    bool enablePolyfills = true,
    // Desktop options
    bool enableSystemTray = true,
    bool enableGlobalShortcuts = true,
    bool enableDragDrop = true,
    bool enableWindowManager = true,
  }) async {
    if (kIsWeb) {
      await initializeWeb(
        enableSmartBundling: enableSmartBundling,
        enableSEO: enableSEO,
        enableProgressiveLoading: enableProgressiveLoading,
        enablePolyfills: enablePolyfills,
      );
    } else if (PlatformDetector.isDesktop) {
      await initializeDesktop(
        enableSystemTray: enableSystemTray,
        enableGlobalShortcuts: enableGlobalShortcuts,
        enableDragDrop: enableDragDrop,
        enableWindowManager: enableWindowManager,
      );
    }
  }

  /// Cleanup resources
  static Future<void> dispose() async {
    if (kIsWeb) {
      await web.dispose();
    } else if (PlatformDetector.isDesktop) {
      await desktop.dispose();
    }
  }
}
