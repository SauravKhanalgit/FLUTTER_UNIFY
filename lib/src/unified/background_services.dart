import 'dart:async';
import 'package:flutter/foundation.dart';
import '../common/platform_detector.dart';
import '../common/event_emitter.dart';

/// Background task types
enum BackgroundTaskType {
  immediate,
  periodic,
  oneTime,
  expedited,
  longRunning,
}

/// Task execution constraints
enum TaskConstraint {
  requiresCharging,
  requiresDeviceIdle,
  requiresStorageNotLow,
  requiresBatteryNotLow,
  requiresNetworkConnected,
  requiresNetworkUnmetered,
}

/// Task execution result
enum TaskResult {
  success,
  failure,
  retry,
  reschedule,
}

/// Background task status
enum TaskStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
  rescheduled,
}

/// Background task configuration
class BackgroundTaskConfig {
  final String id;
  final String name;
  final BackgroundTaskType type;
  final Duration? initialDelay;
  final Duration? interval;
  final Duration? flexInterval;
  final Set<TaskConstraint> constraints;
  final Map<String, dynamic>? inputData;
  final Duration? maxExecutionTime;
  final int? maxRetries;
  final Duration? backoffDelay;
  final bool requiresNetworkConnectivity;
  final bool persistAcrossReboot;
  final bool replaceExisting;

  const BackgroundTaskConfig({
    required this.id,
    required this.name,
    required this.type,
    this.initialDelay,
    this.interval,
    this.flexInterval,
    this.constraints = const {},
    this.inputData,
    this.maxExecutionTime,
    this.maxRetries = 3,
    this.backoffDelay,
    this.requiresNetworkConnectivity = false,
    this.persistAcrossReboot = false,
    this.replaceExisting = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialDelay': initialDelay?.inMilliseconds,
      'interval': interval?.inMilliseconds,
      'flexInterval': flexInterval?.inMilliseconds,
      'constraints': constraints.map((c) => c.name).toList(),
      'inputData': inputData,
      'maxExecutionTime': maxExecutionTime?.inMilliseconds,
      'maxRetries': maxRetries,
      'backoffDelay': backoffDelay?.inMilliseconds,
      'requiresNetworkConnectivity': requiresNetworkConnectivity,
      'persistAcrossReboot': persistAcrossReboot,
      'replaceExisting': replaceExisting,
    };
  }

  factory BackgroundTaskConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundTaskConfig(
      id: json['id'],
      name: json['name'],
      type: BackgroundTaskType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BackgroundTaskType.oneTime,
      ),
      initialDelay: json['initialDelay'] != null
          ? Duration(milliseconds: json['initialDelay'])
          : null,
      interval: json['interval'] != null
          ? Duration(milliseconds: json['interval'])
          : null,
      flexInterval: json['flexInterval'] != null
          ? Duration(milliseconds: json['flexInterval'])
          : null,
      constraints: (json['constraints'] as List?)
              ?.map((c) => TaskConstraint.values.firstWhere(
                    (constraint) => constraint.name == c,
                    orElse: () => TaskConstraint.requiresNetworkConnected,
                  ))
              .toSet() ??
          {},
      inputData: json['inputData'],
      maxExecutionTime: json['maxExecutionTime'] != null
          ? Duration(milliseconds: json['maxExecutionTime'])
          : null,
      maxRetries: json['maxRetries'] ?? 3,
      backoffDelay: json['backoffDelay'] != null
          ? Duration(milliseconds: json['backoffDelay'])
          : null,
      requiresNetworkConnectivity: json['requiresNetworkConnectivity'] ?? false,
      persistAcrossReboot: json['persistAcrossReboot'] ?? false,
      replaceExisting: json['replaceExisting'] ?? false,
    );
  }
}

/// Background task execution context
class TaskExecutionContext {
  final String taskId;
  final String taskName;
  final Map<String, dynamic>? inputData;
  final int attemptCount;
  final DateTime startTime;
  final bool isRetry;

  const TaskExecutionContext({
    required this.taskId,
    required this.taskName,
    this.inputData,
    this.attemptCount = 1,
    required this.startTime,
    this.isRetry = false,
  });
}

/// Background task execution result
class TaskExecutionResult {
  final TaskResult result;
  final Map<String, dynamic>? outputData;
  final String? error;
  final Duration? executionTime;
  final DateTime? nextRunTime;

  const TaskExecutionResult({
    required this.result,
    this.outputData,
    this.error,
    this.executionTime,
    this.nextRunTime,
  });

  factory TaskExecutionResult.success({
    Map<String, dynamic>? outputData,
    Duration? executionTime,
  }) {
    return TaskExecutionResult(
      result: TaskResult.success,
      outputData: outputData,
      executionTime: executionTime,
    );
  }

  factory TaskExecutionResult.failure(
    String error, {
    Duration? executionTime,
  }) {
    return TaskExecutionResult(
      result: TaskResult.failure,
      error: error,
      executionTime: executionTime,
    );
  }

  factory TaskExecutionResult.retry({
    Duration? executionTime,
    DateTime? nextRunTime,
  }) {
    return TaskExecutionResult(
      result: TaskResult.retry,
      executionTime: executionTime,
      nextRunTime: nextRunTime,
    );
  }

  factory TaskExecutionResult.reschedule({
    DateTime? nextRunTime,
    Duration? executionTime,
  }) {
    return TaskExecutionResult(
      result: TaskResult.reschedule,
      executionTime: executionTime,
      nextRunTime: nextRunTime,
    );
  }
}

/// Background task info
class BackgroundTaskInfo {
  final BackgroundTaskConfig config;
  final TaskStatus status;
  final DateTime? lastRunTime;
  final DateTime? nextRunTime;
  final int runCount;
  final int failureCount;
  final String? lastError;

  const BackgroundTaskInfo({
    required this.config,
    required this.status,
    this.lastRunTime,
    this.nextRunTime,
    this.runCount = 0,
    this.failureCount = 0,
    this.lastError,
  });
}

/// Background task handler
typedef BackgroundTaskHandler = Future<TaskExecutionResult> Function(
    TaskExecutionContext context);

/// Foreground service configuration
class ForegroundServiceConfig {
  final String id;
  final String title;
  final String description;
  final String? iconPath;
  final bool showProgress;
  final bool ongoing;
  final List<ForegroundServiceAction> actions;

  const ForegroundServiceConfig({
    required this.id,
    required this.title,
    required this.description,
    this.iconPath,
    this.showProgress = false,
    this.ongoing = true,
    this.actions = const [],
  });
}

/// Foreground service action
class ForegroundServiceAction {
  final String id;
  final String title;
  final String? iconPath;

  const ForegroundServiceAction({
    required this.id,
    required this.title,
    this.iconPath,
  });
}

/// Unified background services API
class UnifiedBackgroundServices extends EventEmitter {
  static UnifiedBackgroundServices? _instance;
  static UnifiedBackgroundServices get instance =>
      _instance ??= UnifiedBackgroundServices._();

  UnifiedBackgroundServices._();

  bool _isInitialized = false;
  final Map<String, BackgroundTaskHandler> _taskHandlers = {};
  final Map<String, BackgroundTaskInfo> _activeTasks = {};
  final Map<String, Timer> _webTimers = {};

  /// Initialize background services
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
        print('UnifiedBackgroundServices: Failed to initialize: $e');
      }
      return false;
    }
  }

  /// Register a background task handler
  void registerTaskHandler(String taskId, BackgroundTaskHandler handler) {
    _taskHandlers[taskId] = handler;
  }

  /// Unregister a background task handler
  void unregisterTaskHandler(String taskId) {
    _taskHandlers.remove(taskId);
  }

  /// Schedule a background task
  Future<bool> scheduleTask(BackgroundTaskConfig config) async {
    if (!_isInitialized) {
      throw StateError('UnifiedBackgroundServices not initialized');
    }

    try {
      bool success = false;

      if (kIsWeb) {
        success = await _scheduleTaskWeb(config);
      } else if (PlatformDetector.isDesktop) {
        success = await _scheduleTaskDesktop(config);
      } else if (PlatformDetector.isMobile) {
        success = await _scheduleTaskMobile(config);
      }

      if (success) {
        _activeTasks[config.id] = BackgroundTaskInfo(
          config: config,
          status: TaskStatus.pending,
          nextRunTime: DateTime.now().add(config.initialDelay ?? Duration.zero),
        );

        emit('task-scheduled', {
          'taskId': config.id,
          'taskName': config.name,
        });
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedBackgroundServices: Failed to schedule task: $e');
      }
      return false;
    }
  }

  /// Cancel a background task
  Future<bool> cancelTask(String taskId) async {
    if (!_isInitialized) {
      throw StateError('UnifiedBackgroundServices not initialized');
    }

    try {
      bool success = false;

      if (kIsWeb) {
        success = await _cancelTaskWeb(taskId);
      } else if (PlatformDetector.isDesktop) {
        success = await _cancelTaskDesktop(taskId);
      } else if (PlatformDetector.isMobile) {
        success = await _cancelTaskMobile(taskId);
      }

      if (success) {
        _activeTasks.remove(taskId);

        emit('task-cancelled', {
          'taskId': taskId,
        });
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedBackgroundServices: Failed to cancel task: $e');
      }
      return false;
    }
  }

  /// Get all active tasks
  List<BackgroundTaskInfo> getActiveTasks() {
    return List.unmodifiable(_activeTasks.values);
  }

  /// Get task info by ID
  BackgroundTaskInfo? getTaskInfo(String taskId) {
    return _activeTasks[taskId];
  }

  /// Cancel all tasks
  Future<bool> cancelAllTasks() async {
    bool allSuccess = true;

    for (final taskId in _activeTasks.keys.toList()) {
      final success = await cancelTask(taskId);
      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  /// Start foreground service (mobile/desktop only)
  Future<bool> startForegroundService(ForegroundServiceConfig config) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print(
            'UnifiedBackgroundServices: Foreground services not supported on web');
      }
      return false;
    }

    try {
      if (PlatformDetector.isDesktop) {
        return await _startForegroundServiceDesktop(config);
      } else if (PlatformDetector.isMobile) {
        return await _startForegroundServiceMobile(config);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'UnifiedBackgroundServices: Failed to start foreground service: $e');
      }
      return false;
    }
  }

  /// Stop foreground service
  Future<bool> stopForegroundService(String serviceId) async {
    if (kIsWeb) return false;

    try {
      if (PlatformDetector.isDesktop) {
        return await _stopForegroundServiceDesktop(serviceId);
      } else if (PlatformDetector.isMobile) {
        return await _stopForegroundServiceMobile(serviceId);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'UnifiedBackgroundServices: Failed to stop foreground service: $e');
      }
      return false;
    }
  }

  /// Update foreground service notification
  Future<bool> updateForegroundService(
    String serviceId, {
    String? title,
    String? description,
    int? progress,
  }) async {
    if (kIsWeb) return false;

    try {
      if (PlatformDetector.isDesktop) {
        return await _updateForegroundServiceDesktop(
            serviceId, title, description, progress);
      } else if (PlatformDetector.isMobile) {
        return await _updateForegroundServiceMobile(
            serviceId, title, description, progress);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'UnifiedBackgroundServices: Failed to update foreground service: $e');
      }
      return false;
    }
  }

  /// Check if background execution is available
  bool isBackgroundExecutionAvailable() {
    if (kIsWeb) {
      // Web has limited background execution with Service Workers
      return true;
    } else if (PlatformDetector.isDesktop) {
      // Desktop generally allows background execution
      return true;
    } else if (PlatformDetector.isMobile) {
      // Mobile has various restrictions
      return true; // Assumes proper permissions
    }

    return false;
  }

  /// Request background execution permissions (mobile)
  Future<bool> requestBackgroundExecutionPermission() async {
    if (kIsWeb || PlatformDetector.isDesktop) {
      return true; // Not needed for web/desktop
    }

    try {
      if (PlatformDetector.isMobile) {
        return await _requestBackgroundExecutionPermissionMobile();
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print(
            'UnifiedBackgroundServices: Failed to request background permission: $e');
      }
      return false;
    }
  }

  /// Execute task immediately (for testing)
  Future<TaskExecutionResult> executeTaskImmediately(String taskId) async {
    final handler = _taskHandlers[taskId];
    if (handler == null) {
      return TaskExecutionResult.failure(
          'No handler registered for task: $taskId');
    }

    final taskInfo = _activeTasks[taskId];
    if (taskInfo == null) {
      return TaskExecutionResult.failure('Task not found: $taskId');
    }

    final context = TaskExecutionContext(
      taskId: taskId,
      taskName: taskInfo.config.name,
      inputData: taskInfo.config.inputData,
      attemptCount: 1,
      startTime: DateTime.now(),
      isRetry: false,
    );

    try {
      _updateTaskStatus(taskId, TaskStatus.running);
      final result = await handler(context);

      if (result.result == TaskResult.success) {
        _updateTaskStatus(taskId, TaskStatus.completed);
      } else {
        _updateTaskStatus(taskId, TaskStatus.failed);
      }

      return result;
    } catch (e) {
      _updateTaskStatus(taskId, TaskStatus.failed);
      return TaskExecutionResult.failure(e.toString());
    }
  }

  // Internal methods
  void _updateTaskStatus(String taskId, TaskStatus status) {
    final taskInfo = _activeTasks[taskId];
    if (taskInfo != null) {
      _activeTasks[taskId] = BackgroundTaskInfo(
        config: taskInfo.config,
        status: status,
        lastRunTime: status == TaskStatus.running
            ? DateTime.now()
            : taskInfo.lastRunTime,
        nextRunTime: taskInfo.nextRunTime,
        runCount: status == TaskStatus.completed
            ? taskInfo.runCount + 1
            : taskInfo.runCount,
        failureCount: status == TaskStatus.failed
            ? taskInfo.failureCount + 1
            : taskInfo.failureCount,
      );

      emit('task-status-changed', {
        'taskId': taskId,
        'status': status.name,
      });
    }
  }

  // Platform-specific initialization
  Future<void> _initializeWeb() async {
    // Initialize web background tasks (Service Workers, Web Workers)
  }

  Future<void> _initializeDesktop() async {
    // Initialize desktop background tasks
  }

  Future<void> _initializeMobile() async {
    // Initialize mobile background tasks (WorkManager, etc.)
  }

  // Platform-specific implementations (stubs)
  Future<bool> _scheduleTaskWeb(BackgroundTaskConfig config) async {
    // Web implementation using Service Workers or timers
    if (config.type == BackgroundTaskType.periodic && config.interval != null) {
      final timer = Timer.periodic(config.interval!, (timer) {
        _executeWebTask(config.id);
      });
      _webTimers[config.id] = timer;
      return true;
    }
    return false;
  }

  Future<bool> _scheduleTaskDesktop(BackgroundTaskConfig config) async {
    // Desktop implementation
    return false;
  }

  Future<bool> _scheduleTaskMobile(BackgroundTaskConfig config) async {
    // Mobile implementation (WorkManager, etc.)
    return false;
  }

  Future<bool> _cancelTaskWeb(String taskId) async {
    final timer = _webTimers.remove(taskId);
    timer?.cancel();
    return timer != null;
  }

  Future<bool> _cancelTaskDesktop(String taskId) async {
    return false;
  }

  Future<bool> _cancelTaskMobile(String taskId) async {
    return false;
  }

  Future<void> _executeWebTask(String taskId) async {
    final handler = _taskHandlers[taskId];
    final taskInfo = _activeTasks[taskId];

    if (handler != null && taskInfo != null) {
      final context = TaskExecutionContext(
        taskId: taskId,
        taskName: taskInfo.config.name,
        inputData: taskInfo.config.inputData,
        attemptCount: taskInfo.runCount + 1,
        startTime: DateTime.now(),
      );

      try {
        _updateTaskStatus(taskId, TaskStatus.running);
        await handler(context);
        _updateTaskStatus(taskId, TaskStatus.completed);
      } catch (e) {
        _updateTaskStatus(taskId, TaskStatus.failed);
      }
    }
  }

  Future<bool> _startForegroundServiceDesktop(
      ForegroundServiceConfig config) async {
    return false;
  }

  Future<bool> _startForegroundServiceMobile(
      ForegroundServiceConfig config) async {
    return false;
  }

  Future<bool> _stopForegroundServiceDesktop(String serviceId) async {
    return false;
  }

  Future<bool> _stopForegroundServiceMobile(String serviceId) async {
    return false;
  }

  Future<bool> _updateForegroundServiceDesktop(String serviceId, String? title,
      String? description, int? progress) async {
    return false;
  }

  Future<bool> _updateForegroundServiceMobile(String serviceId, String? title,
      String? description, int? progress) async {
    return false;
  }

  Future<bool> _requestBackgroundExecutionPermissionMobile() async {
    return false;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await cancelAllTasks();
    _taskHandlers.clear();
    _activeTasks.clear();

    for (final timer in _webTimers.values) {
      timer.cancel();
    }
    _webTimers.clear();

    _isInitialized = false;
  }
}
