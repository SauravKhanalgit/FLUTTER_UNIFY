/// Performance Monitoring System
///
/// Tracks and reports performance metrics for all Unify operations.
/// Provides real-time insights into memory usage, network performance,
/// and operation timings.

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance metrics for a single operation
class PerformanceMetric {
  const PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.memoryUsage,
    this.networkBytes,
    this.success = true,
    this.metadata = const {},
  });

  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final int? memoryUsage; // bytes
  final int? networkBytes;
  final bool success;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'operation': operation,
        'duration': duration.inMilliseconds,
        'timestamp': timestamp.toIso8601String(),
        'memoryUsage': memoryUsage,
        'networkBytes': networkBytes,
        'success': success,
        'metadata': metadata,
      };
}

/// Performance statistics
class PerformanceStats {
  const PerformanceStats({
    required this.totalOperations,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.successRate,
    this.totalMemoryUsage,
    this.totalNetworkBytes,
    this.operationsByType = const {},
  });

  final int totalOperations;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final double successRate; // 0.0 to 1.0
  final int? totalMemoryUsage;
  final int? totalNetworkBytes;
  final Map<String, int> operationsByType;

  Map<String, dynamic> toJson() => {
        'totalOperations': totalOperations,
        'averageDuration': averageDuration.inMilliseconds,
        'minDuration': minDuration.inMilliseconds,
        'maxDuration': maxDuration.inMilliseconds,
        'successRate': successRate,
        'totalMemoryUsage': totalMemoryUsage,
        'totalNetworkBytes': totalNetworkBytes,
        'operationsByType': operationsByType,
      };
}

/// Performance Monitor
class PerformanceMonitor {
  PerformanceMonitor._();
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance => _instance ??= PerformanceMonitor._();

  bool _isEnabled = false;
  final List<PerformanceMetric> _metrics = [];
  final StreamController<PerformanceMetric> _metricController =
      StreamController<PerformanceMetric>.broadcast();
  final Map<String, Stopwatch> _activeOperations = {};

  /// Enable performance monitoring
  void enable() {
    _isEnabled = true;
    if (kDebugMode) {
      print('PerformanceMonitor: Enabled');
    }
  }

  /// Disable performance monitoring
  void disable() {
    _isEnabled = false;
    if (kDebugMode) {
      print('PerformanceMonitor: Disabled');
    }
  }

  /// Check if monitoring is enabled
  bool get isEnabled => _isEnabled;

  /// Start tracking an operation
  String startOperation(String operation, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return '';

    final id = '${operation}_${DateTime.now().millisecondsSinceEpoch}';
    _activeOperations[id] = Stopwatch()..start();
    return id;
  }

  /// End tracking an operation
  void endOperation(
    String operationId, {
    bool success = true,
    int? memoryUsage,
    int? networkBytes,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled || !_activeOperations.containsKey(operationId)) return;

    final stopwatch = _activeOperations.remove(operationId)!;
    stopwatch.stop();

    final metric = PerformanceMetric(
      operation: operationId.split('_').first,
      duration: stopwatch.elapsed,
      timestamp: DateTime.now(),
      memoryUsage: memoryUsage,
      networkBytes: networkBytes,
      success: success,
      metadata: metadata ?? {},
    );

    _metrics.add(metric);
    _metricController.add(metric);

    // Keep only last 1000 metrics
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  /// Track a complete operation
  Future<T> trackOperation<T>(
    String operation,
    Future<T> Function() operationFn, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isEnabled) {
      return await operationFn();
    }

    final id = startOperation(operation, metadata: metadata);
    try {
      final result = await operationFn();
      endOperation(id, success: true, metadata: metadata);
      return result;
    } catch (e) {
      endOperation(id, success: false, metadata: {
        ...?metadata,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Get all metrics
  List<PerformanceMetric> getMetrics() => List.unmodifiable(_metrics);

  /// Get metrics stream
  Stream<PerformanceMetric> get onMetric => _metricController.stream;

  /// Get statistics
  PerformanceStats getStats() {
    if (_metrics.isEmpty) {
      return const PerformanceStats(
        totalOperations: 0,
        averageDuration: Duration.zero,
        minDuration: Duration.zero,
        maxDuration: Duration.zero,
        successRate: 1.0,
      );
    }

    final durations = _metrics.map((m) => m.duration).toList();
    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    final avgMs = totalMs / durations.length;
    final minDuration = durations.reduce((a, b) => a < b ? a : b);
    final maxDuration = durations.reduce((a, b) => a > b ? a : b);
    final successful = _metrics.where((m) => m.success).length;
    final successRate = successful / _metrics.length;

    final operationsByType = <String, int>{};
    for (final metric in _metrics) {
      operationsByType[metric.operation] =
          (operationsByType[metric.operation] ?? 0) + 1;
    }

    final totalMemory = _metrics
        .where((m) => m.memoryUsage != null)
        .fold<int>(0, (sum, m) => sum + (m.memoryUsage ?? 0));

    final totalNetwork = _metrics
        .where((m) => m.networkBytes != null)
        .fold<int>(0, (sum, m) => sum + (m.networkBytes ?? 0));

    return PerformanceStats(
      totalOperations: _metrics.length,
      averageDuration: Duration(milliseconds: avgMs.round()),
      minDuration: minDuration,
      maxDuration: maxDuration,
      successRate: successRate,
      totalMemoryUsage: totalMemory > 0 ? totalMemory : null,
      totalNetworkBytes: totalNetwork > 0 ? totalNetwork : null,
      operationsByType: operationsByType,
    );
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
  }

  /// Dispose resources
  void dispose() {
    _metricController.close();
    _metrics.clear();
    _activeOperations.clear();
  }
}

