import 'package:flutter/material.dart';
import '../desktop/drag_drop.dart' as dd;

/// A widget that can receive dropped files and other data
class DropTarget extends StatefulWidget {
  /// The child widget to render
  final Widget child;

  /// Callback when files are dropped
  final Function(List<String> files)? onDropFiles;

  /// Callback when text is dropped
  final Function(String text)? onDropText;

  /// Callback when URL is dropped
  final Function(String url)? onDropUrl;

  /// Callback when any data is dropped
  final Function(dd.DragData data)? onDrop;

  /// Callback when drag enters the widget
  final Function(dd.DragData data)? onDragEnter;

  /// Callback when drag moves over the widget
  final Function(dd.DragData data)? onDragOver;

  /// Callback when drag leaves the widget
  final VoidCallback? onDragLeave;

  /// List of accepted data types (default: all types)
  final List<String> acceptedTypes;

  /// Whether to highlight the widget during drag over
  final bool highlightOnDragOver;

  /// Color to use for highlighting during drag over
  final Color? highlightColor;

  /// Border to show during drag over
  final Border? highlightBorder;

  /// Whether the drop target is enabled
  final bool enabled;

  const DropTarget({
    Key? key,
    required this.child,
    this.onDropFiles,
    this.onDropText,
    this.onDropUrl,
    this.onDrop,
    this.onDragEnter,
    this.onDragOver,
    this.onDragLeave,
    this.acceptedTypes = const ['*'],
    this.highlightOnDragOver = true,
    this.highlightColor,
    this.highlightBorder,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<DropTarget> createState() => _DropTargetState();
}

class _DropTargetState extends State<DropTarget> {
  bool _isDragOver = false;
  String? _dropTargetId;

  @override
  void initState() {
    super.initState();
    _initializeDropTarget();
  }

  void _initializeDropTarget() {
    if (!widget.enabled) return;

    _dropTargetId = 'drop_target_${DateTime.now().millisecondsSinceEpoch}';

    // Register with DragDropManager if available
    try {
      // Note: This is a widget wrapper, the actual platform integration
      // would be handled by the underlying desktop drag drop manager
      // For now, this is just a placeholder for the widget layer
    } catch (e) {
      // DragDropManager might not be available (e.g., on web or mobile)
      // Fall back to web-specific drag and drop if on web
    }
  }

  void _handleDrop(dd.DragData data) {
    setState(() {
      _isDragOver = false;
    });

    // Call specific callbacks based on data type
    if (data.hasFiles && widget.onDropFiles != null) {
      widget.onDropFiles!(data.files);
    }

    if (data.hasText && widget.onDropText != null) {
      widget.onDropText!(data.text);
    }

    if (data.hasUrl && widget.onDropUrl != null) {
      widget.onDropUrl!(data.url);
    }

    // Call general drop callback
    if (widget.onDrop != null) {
      widget.onDrop!(data);
    }
  }

  void _handleDragEnter(dd.DragData data) {
    if (!mounted) return;

    setState(() {
      _isDragOver = true;
    });

    if (widget.onDragEnter != null) {
      widget.onDragEnter!(data);
    }
  }

  void _handleDragOver(dd.DragData data) {
    if (widget.onDragOver != null) {
      widget.onDragOver!(data);
    }
  }

  void _handleDragLeave() {
    if (!mounted) return;

    setState(() {
      _isDragOver = false;
    });

    if (widget.onDragLeave != null) {
      widget.onDragLeave!();
    }
  }

  @override
  void dispose() {
    // Unregister drop target
    if (_dropTargetId != null) {
      try {
        // In a real implementation:
        // DragDropManager.instance.unregisterDropTarget(_dropTargetId!);
      } catch (e) {
        // Ignore errors during disposal
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    // Add highlight decoration if drag is over and highlighting is enabled
    if (_isDragOver && widget.highlightOnDragOver && widget.enabled) {
      child = Container(
        decoration: BoxDecoration(
          color: widget.highlightColor ??
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
          border: widget.highlightBorder ??
              Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      );
    }

    // For web platform, use HTML drag and drop events
    return _WebDropTarget(
      enabled: widget.enabled,
      acceptedTypes: widget.acceptedTypes,
      onDrop: _handleDrop,
      onDragEnter: _handleDragEnter,
      onDragOver: _handleDragOver,
      onDragLeave: _handleDragLeave,
      child: child,
    );
  }
}

/// Web-specific drop target implementation
class _WebDropTarget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final List<String> acceptedTypes;
  final Function(dd.DragData data)? onDrop;
  final Function(dd.DragData data)? onDragEnter;
  final Function(dd.DragData data)? onDragOver;
  final VoidCallback? onDragLeave;

  const _WebDropTarget({
    Key? key,
    required this.child,
    required this.enabled,
    required this.acceptedTypes,
    this.onDrop,
    this.onDragEnter,
    this.onDragOver,
    this.onDragLeave,
  }) : super(key: key);

  @override
  State<_WebDropTarget> createState() => _WebDropTargetState();
}

class _WebDropTargetState extends State<_WebDropTarget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  // Web-specific drag and drop implementation would go here
  // This is a simplified version - real implementation would use
  // dart:html events for dragover, drop, etc.
}

/// A draggable widget that can start drag operations
class DragSource extends StatefulWidget {
  /// The child widget to render
  final Widget child;

  /// Data to drag
  final dd.DragData data;

  /// Custom drag feedback widget
  final Widget? feedback;

  /// Drag anchor point offset
  final Offset? dragAnchorStrategy;

  /// Whether dragging is enabled
  final bool enabled;

  /// Callback when drag starts
  final VoidCallback? onDragStarted;

  /// Callback when drag ends
  final VoidCallback? onDragEnd;

  /// Callback when drag is completed (successful drop)
  final VoidCallback? onDragCompleted;

  const DragSource({
    Key? key,
    required this.child,
    required this.data,
    this.feedback,
    this.dragAnchorStrategy,
    this.enabled = true,
    this.onDragStarted,
    this.onDragEnd,
    this.onDragCompleted,
  }) : super(key: key);

  @override
  State<DragSource> createState() => _DragSourceState();
}

class _DragSourceState extends State<DragSource> {
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Draggable<dd.DragData>(
      data: widget.data,
      feedback: widget.feedback ??
          Material(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                _getDragText(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: widget.child,
      ),
      onDragStarted: () {
        if (widget.onDragStarted != null) {
          widget.onDragStarted!();
        }

        // Start native drag operation if available
        try {
          // DragDropManager.instance.startDrag(data: widget.data);
        } catch (e) {
          // Native drag not available, use Flutter's draggable
        }
      },
      onDragEnd: (details) {
        if (widget.onDragEnd != null) {
          widget.onDragEnd!();
        }
      },
      onDragCompleted: () {
        if (widget.onDragCompleted != null) {
          widget.onDragCompleted!();
        }
      },
      child: widget.child,
    );
  }

  String _getDragText() {
    switch (widget.data.type) {
      case 'files':
        return '${widget.data.files.length} file(s)';
      case 'text':
        return widget.data.text.length > 20
            ? '${widget.data.text.substring(0, 20)}...'
            : widget.data.text;
      case 'url':
        return widget.data.url;
      default:
        return 'Dragging ${widget.data.type}';
    }
  }
}
