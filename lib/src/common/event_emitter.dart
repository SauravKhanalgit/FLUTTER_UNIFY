/// Simple event emitter implementation for internal communication
class EventEmitter {
  final Map<String, List<Function>> _listeners = {};

  /// Add a listener for an event
  void on(String event, Function callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  /// Remove a listener for an event
  void off(String event, Function callback) {
    _listeners[event]?.remove(callback);
    if (_listeners[event]?.isEmpty == true) {
      _listeners.remove(event);
    }
  }

  /// Emit an event with optional data
  void emit(String event, [dynamic data]) {
    final listeners = _listeners[event];
    if (listeners != null) {
      for (final callback in listeners.toList()) {
        try {
          if (data != null) {
            callback(data);
          } else {
            callback();
          }
        } catch (e) {
          print('EventEmitter: Error in callback for event "$event": $e');
        }
      }
    }
  }

  /// Remove all listeners for an event or all events
  void removeAllListeners([String? event]) {
    if (event != null) {
      _listeners.remove(event);
    } else {
      _listeners.clear();
    }
  }

  /// Get the number of listeners for an event
  int listenerCount(String event) {
    return _listeners[event]?.length ?? 0;
  }

  /// Check if there are any listeners for an event
  bool hasListeners(String event) {
    return _listeners[event]?.isNotEmpty == true;
  }

  /// Get all event names that have listeners
  List<String> get eventNames => _listeners.keys.toList();
}
