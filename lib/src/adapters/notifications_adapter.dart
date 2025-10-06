import 'dart:async';
import 'package:flutter/foundation.dart';
import '../system/system_manager.dart';

/// Unified notifications adapter (local-first, push pluggable later)
abstract class NotificationsAdapter {
  /// Initialize underlying channels/services
  Future<void> initialize();

  /// Ask user/system for permission if applicable
  Future<bool> requestPermission();

  /// Show an immediate local notification and return its id
  Future<String?> show({
    required String title,
    required String body,
    String? payload,
    String? icon,
    Duration? duration,
    bool? silent,
  });

  /// Cancel a notification by id
  Future<bool> cancel(String id);

  /// Cancel all notifications for the app
  Future<void> cancelAll();
}

/// Default adapter delegates to SystemManager (desktop bridge or fallbacks)
class DefaultNotificationsAdapter implements NotificationsAdapter {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // Ensure SystemManager is initialized by Unify before this.
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    // SystemManager handles platform specifics; return true by default.
    return true;
  }

  @override
  Future<String?> show({
    required String title,
    required String body,
    String? payload,
    String? icon,
    Duration? duration,
    bool? silent,
  }) async {
    try {
      // Delegates to SystemManager (desktop native or simplified on mobile/web)
      return await SystemManager.instance.showNotification(
        title: title,
        body: body,
        icon: icon,
        duration: duration,
        silent: silent,
      );
    } catch (e) {
      if (kDebugMode) {
        print('NotificationsAdapter.show error: $e');
      }
      return null;
    }
  }

  @override
  Future<bool> cancel(String id) async {
    try {
      return await SystemManager.instance.closeNotification(id);
    } catch (e) {
      if (kDebugMode) {
        print('NotificationsAdapter.cancel error: $e');
      }
      return false;
    }
  }

  @override
  Future<void> cancelAll() async {
    // SystemManager does not expose cancelAll; naive no-op for now.
  }
}
