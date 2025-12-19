import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/core/performance_monitor.dart';

void main() {
  group('PerformanceMonitor', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor.instance;
      monitor.enable();
      monitor.clearMetrics();
    });

    tearDown(() {
      monitor.clearMetrics();
      monitor.disable();
    });

    test('should track operation', () async {
      final id = monitor.startOperation('test_operation');
      await Future.delayed(const Duration(milliseconds: 100));
      monitor.endOperation(id);

      final metrics = monitor.getMetrics();
      expect(metrics.length, 1);
      expect(metrics.first.operation, 'test_operation');
      expect(metrics.first.duration.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('should track operation with trackOperation', () async {
      final result = await monitor.trackOperation(
        'test_op',
        () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'success';
        },
      );

      expect(result, 'success');
      final metrics = monitor.getMetrics();
      expect(metrics.length, 1);
      expect(metrics.first.operation, 'test_op');
      expect(metrics.first.success, isTrue);
    });

    test('should track failed operation', () async {
      try {
        await monitor.trackOperation(
          'failed_op',
          () async {
            throw Exception('Test error');
          },
        );
      } catch (e) {
        // Expected
      }

      final metrics = monitor.getMetrics();
      expect(metrics.length, 1);
      expect(metrics.first.operation, 'failed_op');
      expect(metrics.first.success, isFalse);
    });

    test('should calculate statistics', () async {
      // Track multiple operations
      for (int i = 0; i < 5; i++) {
        final id = monitor.startOperation('op_$i');
        await Future.delayed(const Duration(milliseconds: 10));
        monitor.endOperation(id);
      }

      final stats = monitor.getStats();
      expect(stats.totalOperations, 5);
      expect(stats.averageDuration.inMilliseconds, greaterThanOrEqualTo(10));
      expect(stats.minDuration.inMilliseconds, greaterThanOrEqualTo(10));
      expect(stats.maxDuration.inMilliseconds, greaterThanOrEqualTo(10));
      expect(stats.successRate, 1.0);
    });

    test('should track memory usage', () {
      final id = monitor.startOperation('memory_op');
      monitor.endOperation(id, memoryUsage: 1024 * 1024); // 1MB

      final metrics = monitor.getMetrics();
      expect(metrics.first.memoryUsage, 1024 * 1024);
    });

    test('should track network bytes', () {
      final id = monitor.startOperation('network_op');
      monitor.endOperation(id, networkBytes: 512 * 1024); // 512KB

      final metrics = monitor.getMetrics();
      expect(metrics.first.networkBytes, 512 * 1024);
    });

    test('should limit metrics to 1000', () {
      for (int i = 0; i < 1500; i++) {
        final id = monitor.startOperation('op_$i');
        monitor.endOperation(id);
      }

      final metrics = monitor.getMetrics();
      expect(metrics.length, lessThanOrEqualTo(1000));
    });

    test('should provide metrics stream', () async {
      final metrics = <PerformanceMetric>[];
      final subscription = monitor.onMetric.listen((metric) {
        metrics.add(metric);
      });

      final id = monitor.startOperation('stream_op');
      monitor.endOperation(id);

      await Future.delayed(const Duration(milliseconds: 10));
      await subscription.cancel();

      expect(metrics.length, 1);
      expect(metrics.first.operation, 'stream_op');
    });
  });
}

