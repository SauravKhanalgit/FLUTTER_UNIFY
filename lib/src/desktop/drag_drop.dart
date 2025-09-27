import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Drag and drop functionality manager
class DragDropManager extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/drag_drop');

  bool _isInitialized = false;
  final List<DropTarget> _dropTargets = [];
  bool _isDragActive = false;
  DragData? _currentDragData;

  /// Check if drag drop manager is initialized
  bool get isInitialized => _isInitialized;

  /// Check if a drag operation is currently active
  bool get isDragActive => _isDragActive;

  /// Get current drag data
  DragData? get currentDragData => _currentDragData;

  /// Get registered drop targets
  List<DropTarget> get dropTargets => List.from(_dropTargets);

  /// Initialize drag drop manager
  Future<void> initialize() async {
    if (kIsWeb && !PlatformDetector.supportsDragDrop) {
      throw UnsupportedError('Drag and drop is not supported on this platform');
    }

    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');

      _isInitialized = true;
      emit('drag-drop-initialized');

      if (kDebugMode) {
        print('DragDropManager: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DragDropManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDragEnter':
        final data = DragData.fromMap(call.arguments);
        _currentDragData = data;
        _isDragActive = true;
        emit('drag-enter', data);
        break;

      case 'onDragOver':
        final data = DragData.fromMap(call.arguments);
        _currentDragData = data;
        emit('drag-over', data);
        break;

      case 'onDragLeave':
        emit('drag-leave', _currentDragData);
        _currentDragData = null;
        _isDragActive = false;
        break;

      case 'onDrop':
        final data = DragData.fromMap(call.arguments);
        emit('drop', data);
        _handleDrop(data);
        _currentDragData = null;
        _isDragActive = false;
        break;

      case 'onDragStart':
        final data = DragData.fromMap(call.arguments);
        emit('drag-start', data);
        break;

      case 'onDragEnd':
        emit('drag-end', _currentDragData);
        _currentDragData = null;
        _isDragActive = false;
        break;

      default:
        if (kDebugMode) {
          print('DragDropManager: Unknown method call: ${call.method}');
        }
    }
  }

  /// Register a drop target
  void registerDropTarget(DropTarget target) {
    if (!_dropTargets.contains(target)) {
      _dropTargets.add(target);
      emit('drop-target-registered', target.id);

      if (kDebugMode) {
        print('DragDropManager: Registered drop target: ${target.id}');
      }
    }
  }

  /// Unregister a drop target
  void unregisterDropTarget(DropTarget target) {
    if (_dropTargets.remove(target)) {
      emit('drop-target-unregistered', target.id);

      if (kDebugMode) {
        print('DragDropManager: Unregistered drop target: ${target.id}');
      }
    }
  }

  /// Handle drop event
  void _handleDrop(DragData data) {
    // Find matching drop targets based on position and accepted types
    for (final target in _dropTargets) {
      if (target.acceptsDataType(data.type) && target.onDrop != null) {
        try {
          target.onDrop!(data);
        } catch (e) {
          if (kDebugMode) {
            print(
                'DragDropManager: Error in drop handler for ${target.id}: $e');
          }
        }
      }
    }
  }

  /// Start a drag operation
  Future<void> startDrag({
    required DragData data,
    String? dragImage,
    int? offsetX,
    int? offsetY,
  }) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('startDrag', {
        'data': data.toMap(),
        'dragImage': dragImage,
        'offsetX': offsetX ?? 0,
        'offsetY': offsetY ?? 0,
      });

      _currentDragData = data;
      _isDragActive = true;
      emit('drag-started', data);

      if (kDebugMode) {
        print('DragDropManager: Started drag operation with ${data.type}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DragDropManager: Failed to start drag: $e');
      }
    }
  }

  /// Set accepted drop types for the entire window
  Future<void> setAcceptedDropTypes(List<String> types) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setAcceptedDropTypes', {'types': types});
      emit('accepted-types-changed', types);

      if (kDebugMode) {
        print('DragDropManager: Set accepted drop types: ${types.join(', ')}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DragDropManager: Failed to set accepted drop types: $e');
      }
    }
  }

  /// Enable or disable drag and drop
  Future<void> setEnabled(bool enabled) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
      emit('enabled-changed', enabled);

      if (kDebugMode) {
        print(
            'DragDropManager: Drag and drop ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DragDropManager: Failed to set enabled state: $e');
      }
    }
  }

  /// Get supported data types
  Future<List<String>> getSupportedDataTypes() async {
    if (!_isInitialized) return [];

    try {
      final result = await _channel.invokeMethod('getSupportedDataTypes')
          as List<dynamic>?;
      return result?.cast<String>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('DragDropManager: Failed to get supported data types: $e');
      }
      return [];
    }
  }

  /// Dispose drag drop manager
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      _dropTargets.clear();
      _currentDragData = null;
      _isDragActive = false;
      removeAllListeners();

      if (kDebugMode) {
        print('DragDropManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DragDropManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// Drag and drop data
class DragData {
  final String type;
  final dynamic data;
  final List<String> files;
  final String text;
  final String url;
  final Map<String, dynamic> metadata;

  DragData({
    required this.type,
    this.data,
    this.files = const [],
    this.text = '',
    this.url = '',
    this.metadata = const {},
  });

  /// Create from files
  factory DragData.files(List<String> filePaths) {
    return DragData(
      type: 'files',
      files: filePaths,
      data: filePaths,
    );
  }

  /// Create from text
  factory DragData.text(String textData) {
    return DragData(
      type: 'text',
      text: textData,
      data: textData,
    );
  }

  /// Create from URL
  factory DragData.url(String urlData) {
    return DragData(
      type: 'url',
      url: urlData,
      data: urlData,
    );
  }

  /// Create from custom data
  factory DragData.custom(String type, dynamic data) {
    return DragData(
      type: type,
      data: data,
    );
  }

  /// Create from map
  factory DragData.fromMap(Map<String, dynamic> map) {
    return DragData(
      type: map['type'] ?? 'unknown',
      data: map['data'],
      files: (map['files'] as List<dynamic>?)?.cast<String>() ?? [],
      text: map['text'] ?? '',
      url: map['url'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'data': data,
      'files': files,
      'text': text,
      'url': url,
      'metadata': metadata,
    };
  }

  /// Check if data is of specific type
  bool isType(String checkType) => type == checkType;

  /// Check if data contains files
  bool get hasFiles => files.isNotEmpty;

  /// Check if data contains text
  bool get hasText => text.isNotEmpty;

  /// Check if data contains URL
  bool get hasUrl => url.isNotEmpty;
}

/// Drop target configuration
class DropTarget {
  final String id;
  final List<String> acceptedTypes;
  final Function(DragData)? onDrop;
  final Function(DragData)? onDragEnter;
  final Function(DragData)? onDragOver;
  final Function()? onDragLeave;

  DropTarget({
    required this.id,
    this.acceptedTypes = const ['*'],
    this.onDrop,
    this.onDragEnter,
    this.onDragOver,
    this.onDragLeave,
  });

  /// Check if this target accepts the given data type
  bool acceptsDataType(String type) {
    return acceptedTypes.contains('*') || acceptedTypes.contains(type);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DropTarget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Drag effect types
enum DragEffect {
  none,
  copy,
  move,
  link,
}
