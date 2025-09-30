import 'dart:async';

/// AR Adapter hooks (ARCore / ARKit / WebXR) - skeleton abstraction

abstract class ArAdapter {
  String get name;
  Future<bool> initialize();
  bool get isInitialized;
  Future<void> startSession({Map<String, dynamic>? config});
  Future<void> endSession();
  Stream<Map<String, dynamic>> get events; // surfaces / anchors / gestures
  Future<void> dispose();
}

class MockArAdapter implements ArAdapter {
  bool _init = false;
  @override
  String get name => 'mock_ar';
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  @override
  Future<bool> initialize() async {
    _init = true;
    return true;
  }

  @override
  bool get isInitialized => _init;
  @override
  Future<void> startSession({Map<String, dynamic>? config}) async {
    if (!_init) throw StateError('AR adapter not initialized');
    _controller.add({'event': 'session.started', 'config': config});
  }

  @override
  Future<void> endSession() async {
    _controller.add({'event': 'session.ended'});
  }

  @override
  Stream<Map<String, dynamic>> get events => _controller.stream;
  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
