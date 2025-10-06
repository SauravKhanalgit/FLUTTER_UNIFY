import 'dart:async';
import '../system/system_manager.dart';
import '../desktop/drag_drop.dart' as desktop_dnd;
import '../common/platform_detector.dart';

/// Unified clipboard & drag-and-drop adapter
abstract class InteractionAdapter {
  // Clipboard
  Future<bool> setText(String text);
  Future<String?> getText();
  Future<bool> hasText();

  // Drag-and-drop (desktop only)
  Future<void> initializeDragDrop();
  void registerDropTarget(desktop_dnd.DropTarget target);
  void unregisterDropTarget(desktop_dnd.DropTarget target);
  Future<void> setAcceptedDropTypes(List<String> types);
  Future<void> startDrag(desktop_dnd.DragData data);
}

class DefaultInteractionAdapter implements InteractionAdapter {
  desktop_dnd.DragDropManager? _dnd;
  bool _dndInitialized = false;

  @override
  Future<bool> setText(String text) =>
      SystemManager.instance.clipboardWriteText(text);

  @override
  Future<String?> getText() => SystemManager.instance.clipboardReadText();

  @override
  Future<bool> hasText() => SystemManager.instance.clipboardHasText();

  @override
  Future<void> initializeDragDrop() async {
    if (!PlatformDetector.isDesktop) return;
    if (_dndInitialized) return;
    _dnd = desktop_dnd.DragDropManager();
    await _dnd!.initialize();
    _dndInitialized = true;
  }

  @override
  void registerDropTarget(desktop_dnd.DropTarget target) {
    if (_dndInitialized && _dnd != null) {
      _dnd!.registerDropTarget(target);
    }
  }

  @override
  void unregisterDropTarget(desktop_dnd.DropTarget target) {
    if (_dndInitialized && _dnd != null) {
      _dnd!.unregisterDropTarget(target);
    }
  }

  @override
  Future<void> setAcceptedDropTypes(List<String> types) async {
    if (_dndInitialized && _dnd != null) {
      await _dnd!.setAcceptedDropTypes(types);
    }
  }

  @override
  Future<void> startDrag(desktop_dnd.DragData data) async {
    if (_dndInitialized && _dnd != null) {
      await _dnd!.startDrag(data: data);
    }
  }
}
