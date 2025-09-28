import 'dart:async';
import 'package:flutter/foundation.dart';
import '../common/platform_detector.dart';
import '../common/event_emitter.dart';

/// Unified notification configuration
class NotificationConfig {
  final String title;
  final String? body;
  final String? icon;
  final String? badge;
  final String? sound;
  final Map<String, dynamic>? data;
  final DateTime? scheduledTime;
  final Duration? delay;
  final String? channelId;
  final String? channelName;
  final NotificationPriority priority;
  final List<NotificationAction>? actions;

  const NotificationConfig({
    required this.title,
    this.body,
    this.icon,
    this.badge,
    this.sound,
    this.data,
    this.scheduledTime,
    this.delay,
    this.channelId,
    this.channelName,
    this.priority = NotificationPriority.normal,
    this.actions,
  });
}

/// Notification action button
class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool destructive;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.destructive = false,
  });
}

/// Notification priority levels
enum NotificationPriority { low, normal, high, urgent }

/// Notification result
class NotificationResult {
  final String id;
  final bool delivered;
  final String? error;
  final Map<String, dynamic>? response;

  const NotificationResult({
    required this.id,
    required this.delivered,
    this.error,
    this.response,
  });
}

/// Unified notifications API across all platforms
class UnifiedNotifications extends EventEmitter {
  static UnifiedNotifications? _instance;
  static UnifiedNotifications get instance =>
      _instance ??= UnifiedNotifications._();

  UnifiedNotifications._();

  bool _isInitialized = false;
  final Map<String, NotificationConfig> _pendingNotifications = {};
  final StreamController<NotificationResult> _notificationStream =
      StreamController<NotificationResult>.broadcast();

  /// Stream of notification events
  Stream<NotificationResult> get onNotification => _notificationStream.stream;

  /// Initialize notification system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (kIsWeb) {
        await _initializeWeb();
      } else if (PlatformDetector.isDesktop) {
        await _initializeDesktop();
      } else if (PlatformDetector.isMobile) {
        await _initializeMobile();
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotifications: Failed to initialize: $e');
      }
      return false;
    }
  }

  /// Check if notifications are supported
  bool get isSupported {
    if (kIsWeb) {
      return _hasWebNotificationSupport();
    }
    return PlatformDetector.isDesktop || PlatformDetector.isMobile;
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (!isSupported) return false;

    try {
      if (kIsWeb) {
        return await _requestWebPermission();
      } else if (PlatformDetector.isDesktop) {
        return await _requestDesktopPermission();
      } else if (PlatformDetector.isMobile) {
        return await _requestMobilePermission();
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotifications: Permission request failed: $e');
      }
    }

    return false;
  }

  /// Show a notification
  Future<NotificationResult> show(
    String title, {
    String? body,
    String? icon,
    String? badge,
    String? sound,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    List<NotificationAction>? actions,
  }) async {
    final config = NotificationConfig(
      title: title,
      body: body,
      icon: icon,
      badge: badge,
      sound: sound,
      data: data,
      priority: priority,
      actions: actions,
    );

    return await _showNotification(config);
  }

  /// Schedule a notification
  Future<NotificationResult> schedule(
    String title, {
    String? body,
    required DateTime scheduledTime,
    String? icon,
    String? badge,
    String? sound,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    List<NotificationAction>? actions,
  }) async {
    final config = NotificationConfig(
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      icon: icon,
      badge: badge,
      sound: sound,
      data: data,
      priority: priority,
      actions: actions,
    );

    return await _scheduleNotification(config);
  }

  /// Show notification after delay
  Future<NotificationResult> showAfter(
    String title, {
    String? body,
    required Duration delay,
    String? icon,
    String? badge,
    String? sound,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    List<NotificationAction>? actions,
  }) async {
    final config = NotificationConfig(
      title: title,
      body: body,
      delay: delay,
      icon: icon,
      badge: badge,
      sound: sound,
      data: data,
      priority: priority,
      actions: actions,
    );

    return await _showDelayedNotification(config);
  }

  /// Cancel a notification
  Future<bool> cancel(String id) async {
    try {
      _pendingNotifications.remove(id);

      if (kIsWeb) {
        return await _cancelWebNotification(id);
      } else if (PlatformDetector.isDesktop) {
        return await _cancelDesktopNotification(id);
      } else if (PlatformDetector.isMobile) {
        return await _cancelMobileNotification(id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotifications: Cancel failed: $e');
      }
    }

    return false;
  }

  /// Cancel all notifications
  Future<bool> cancelAll() async {
    try {
      _pendingNotifications.clear();

      if (kIsWeb) {
        return await _cancelAllWebNotifications();
      } else if (PlatformDetector.isDesktop) {
        return await _cancelAllDesktopNotifications();
      } else if (PlatformDetector.isMobile) {
        return await _cancelAllMobileNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotifications: Cancel all failed: $e');
      }
    }

    return false;
  }

  /// Get pending notifications
  List<String> getPendingNotifications() {
    return _pendingNotifications.keys.toList();
  }

  // Platform-specific initialization
  Future<void> _initializeWeb() async {
    // Web initialization using Service Worker for background notifications
    if (_hasWebNotificationSupport()) {
      // Register service worker for background notifications
      // Implementation would use web APIs
    }
  }

  Future<void> _initializeDesktop() async {
    // Desktop initialization using native notifications
    // Implementation would use platform channels
  }

  Future<void> _initializeMobile() async {
    // Mobile initialization using FCM/APNs
    // Implementation would use platform channels
  }

  // Platform-specific permission requests
  Future<bool> _requestWebPermission() async {
    // Web permission request using Notification API
    return true; // Simplified
  }

  Future<bool> _requestDesktopPermission() async {
    // Desktop permission request
    return true; // Most desktop systems allow notifications by default
  }

  Future<bool> _requestMobilePermission() async {
    // Mobile permission request using platform channels
    return true; // Simplified
  }

  // Platform-specific notification display
  Future<NotificationResult> _showNotification(
      NotificationConfig config) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      if (kIsWeb) {
        return await _showWebNotification(id, config);
      } else if (PlatformDetector.isDesktop) {
        return await _showDesktopNotification(id, config);
      } else if (PlatformDetector.isMobile) {
        return await _showMobileNotification(id, config);
      }
    } catch (e) {
      return NotificationResult(
        id: id,
        delivered: false,
        error: e.toString(),
      );
    }

    return NotificationResult(
      id: id,
      delivered: false,
      error: 'Unsupported platform',
    );
  }

  Future<NotificationResult> _scheduleNotification(
      NotificationConfig config) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingNotifications[id] = config;

    // Calculate delay until scheduled time
    final delay = config.scheduledTime!.difference(DateTime.now());

    if (delay.isNegative) {
      // If scheduled time is in the past, show immediately
      return await _showNotification(config);
    }

    // Schedule for future delivery
    Timer(delay, () async {
      if (_pendingNotifications.containsKey(id)) {
        await _showNotification(config);
        _pendingNotifications.remove(id);
      }
    });

    return NotificationResult(
      id: id,
      delivered: true,
    );
  }

  Future<NotificationResult> _showDelayedNotification(
      NotificationConfig config) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingNotifications[id] = config;

    Timer(config.delay!, () async {
      if (_pendingNotifications.containsKey(id)) {
        await _showNotification(config);
        _pendingNotifications.remove(id);
      }
    });

    return NotificationResult(
      id: id,
      delivered: true,
    );
  }

  // Web-specific implementations
  bool _hasWebNotificationSupport() {
    // Check if Notification API is available
    return true; // Simplified - would check for actual API availability
  }

  Future<NotificationResult> _showWebNotification(
      String id, NotificationConfig config) async {
    // Web notification using Notification API
    // Implementation would use dart:html or package:web

    emit('notification-shown', {
      'id': id,
      'platform': 'web',
      'config': config,
    });

    return NotificationResult(
      id: id,
      delivered: true,
    );
  }

  Future<bool> _cancelWebNotification(String id) async {
    // Cancel web notification
    return true;
  }

  Future<bool> _cancelAllWebNotifications() async {
    // Cancel all web notifications
    return true;
  }

  // Desktop-specific implementations
  Future<NotificationResult> _showDesktopNotification(
      String id, NotificationConfig config) async {
    // Desktop notification using platform channels

    emit('notification-shown', {
      'id': id,
      'platform': 'desktop',
      'config': config,
    });

    return NotificationResult(
      id: id,
      delivered: true,
    );
  }

  Future<bool> _cancelDesktopNotification(String id) async {
    // Cancel desktop notification
    return true;
  }

  Future<bool> _cancelAllDesktopNotifications() async {
    // Cancel all desktop notifications
    return true;
  }

  // Mobile-specific implementations
  Future<NotificationResult> _showMobileNotification(
      String id, NotificationConfig config) async {
    // Mobile notification using FCM/APNs

    emit('notification-shown', {
      'id': id,
      'platform': 'mobile',
      'config': config,
    });

    return NotificationResult(
      id: id,
      delivered: true,
    );
  }

  Future<bool> _cancelMobileNotification(String id) async {
    // Cancel mobile notification
    return true;
  }

  Future<bool> _cancelAllMobileNotifications() async {
    // Cancel all mobile notifications
    return true;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _notificationStream.close();
    _pendingNotifications.clear();
    _isInitialized = false;
  }
}
