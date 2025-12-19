/// Developer Dashboard for Flutter Unify
///
/// Provides a visual debugging and monitoring interface for all Unify operations.
/// Can be opened via `Unify.dev.dashboard.show()` to see:
/// - Network request timeline
/// - Auth state changes
/// - Stream events
/// - Performance metrics
/// - Error tracking
/// - Adapter usage statistics

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dev_dashboard_server.dart';

/// Developer tools and dashboard
class DevDashboard {
  DevDashboard._();
  static DevDashboard? _instance;
  static DevDashboard get instance => _instance ??= DevDashboard._();

  bool _isEnabled = false;
  final List<DashboardEvent> _events = [];
  final StreamController<DashboardEvent> _eventController =
      StreamController<DashboardEvent>.broadcast();

  /// Enable the dashboard
  void enable() {
    _isEnabled = true;
    if (kDebugMode) {
      print('DevDashboard: Enabled');
    }
  }

  /// Disable the dashboard
  void disable() {
    _isEnabled = false;
    if (kDebugMode) {
      print('DevDashboard: Disabled');
    }
  }

  /// Check if dashboard is enabled
  bool get isEnabled => _isEnabled;

  /// Show the dashboard (opens web interface)
  Future<void> show({int port = 8080}) async {
    if (!_isEnabled) {
      if (kDebugMode) {
        print('DevDashboard: Enable dashboard first with DevDashboard.instance.enable()');
      }
      return;
    }

    try {
      final server = DevDashboardServer.instance;
      if (!server.isRunning) {
        await server.start(port: port);
      }

      if (kDebugMode) {
        print('DevDashboard: Dashboard available at ${server.url}');
        print('DevDashboard: Events captured: ${_events.length}');
        print('DevDashboard: Open ${server.url} in your browser');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DevDashboard: Failed to start server: $e');
        print('DevDashboard: Dashboard URL would be: http://localhost:$port');
      }
    }
  }

  /// Record an event
  void recordEvent(DashboardEvent event) {
    if (!_isEnabled) return;

    _events.add(event);
    _eventController.add(event);

    // Keep only last 1000 events
    if (_events.length > 1000) {
      _events.removeAt(0);
    }
  }

  /// Get all events
  List<DashboardEvent> getEvents() => List.unmodifiable(_events);

  /// Get events stream
  Stream<DashboardEvent> get onEvent => _eventController.stream;

  /// Clear all events
  void clearEvents() {
    _events.clear();
  }

  /// Get statistics
  DashboardStats getStats() {
    final networkEvents = _events.where((e) => e.type == EventType.network).length;
    final authEvents = _events.where((e) => e.type == EventType.auth).length;
    final errorEvents = _events.where((e) => e.type == EventType.error).length;

    return DashboardStats(
      totalEvents: _events.length,
      networkEvents: networkEvents,
      authEvents: authEvents,
      errorEvents: errorEvents,
      firstEventTime: _events.isNotEmpty ? _events.first.timestamp : null,
      lastEventTime: _events.isNotEmpty ? _events.last.timestamp : null,
    );
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _events.clear();
  }
}

/// Dashboard event types
enum EventType {
  network,
  auth,
  storage,
  system,
  ai,
  error,
  performance,
  other,
}

/// Dashboard event
class DashboardEvent {
  const DashboardEvent({
    required this.type,
    required this.timestamp,
    required this.title,
    this.description,
    this.data,
    this.duration,
    this.success = true,
  });

  final EventType type;
  final DateTime timestamp;
  final String title;
  final String? description;
  final Map<String, dynamic>? data;
  final Duration? duration;
  final bool success;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'description': description,
        'data': data,
        'duration': duration?.inMilliseconds,
        'success': success,
      };
}

/// Dashboard statistics
class DashboardStats {
  const DashboardStats({
    required this.totalEvents,
    required this.networkEvents,
    required this.authEvents,
    required this.errorEvents,
    this.firstEventTime,
    this.lastEventTime,
  });

  final int totalEvents;
  final int networkEvents;
  final int authEvents;
  final int errorEvents;
  final DateTime? firstEventTime;
  final DateTime? lastEventTime;

  Map<String, dynamic> toJson() => {
        'totalEvents': totalEvents,
        'networkEvents': networkEvents,
        'authEvents': authEvents,
        'errorEvents': errorEvents,
        'firstEventTime': firstEventTime?.toIso8601String(),
        'lastEventTime': lastEventTime?.toIso8601String(),
      };
}

