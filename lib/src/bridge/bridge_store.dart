/// Reactive shared store across Flutter <-> native / web boundaries.
///
/// Provides a minimal key-value + subscription model now; future expansion:
/// - Conflict resolution strategies
/// - Snapshot version vectors
/// - Selective replication / scoping
import 'dart:async';

class BridgeStoreUpdate {
  final String key;
  final dynamic value;
  final DateTime timestamp;
  BridgeStoreUpdate(this.key, this.value) : timestamp = DateTime.now();
}

class BridgeStore {
  BridgeStore._();
  static final BridgeStore instance = BridgeStore._();

  final Map<String, dynamic> _data = {};
  final StreamController<BridgeStoreUpdate> _controller =
      StreamController.broadcast();

  Stream<BridgeStoreUpdate> get updates => _controller.stream;

  dynamic get(String key) => _data[key];

  T? getTyped<T>(String key) {
    final v = _data[key];
    if (v is T) return v;
    return null;
  }

  void set(String key, dynamic value) {
    _data[key] = value;
    _controller.add(BridgeStoreUpdate(key, value));
  }

  bool contains(String key) => _data.containsKey(key);

  Map<String, dynamic> snapshot() => Map.unmodifiable(_data);

  Future<void> dispose() async => _controller.close();
}
