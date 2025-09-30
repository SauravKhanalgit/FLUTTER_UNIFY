/// Hybrid bridge channel abstraction.
///
/// Provides a unified API over platform channels / JS interop / desktop IPC.
/// Roadmap:
/// - Auto code generation from interface definitions
/// - Bi-directional streaming
/// - Structured error + lifecycle events
import 'dart:async';

class BridgeMessage {
  final String channel;
  final String type; // event, request, response, error
  final dynamic payload;
  final String? correlationId;
  final DateTime timestamp;
  BridgeMessage({
    required this.channel,
    required this.type,
    this.payload,
    this.correlationId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

abstract class BridgeTransport {
  Stream<BridgeMessage> get messages;
  Future<void> send(BridgeMessage message);
  Future<void> dispose();
  String get name;
}

/// In-memory mock transport for testing / web fallback.
class MemoryBridgeTransport implements BridgeTransport {
  final _controller = StreamController<BridgeMessage>.broadcast();
  @override
  Stream<BridgeMessage> get messages => _controller.stream;
  @override
  Future<void> send(BridgeMessage message) async {
    // echo async to simulate crossing boundary
    Future.microtask(() => _controller.add(message));
  }

  @override
  Future<void> dispose() async => _controller.close();
  @override
  String get name => 'memory';
}

class BridgeChannel {
  final String name;
  final BridgeTransport _transport;
  final _listeners = <void Function(BridgeMessage)>[];

  BridgeChannel(this.name, this._transport) {
    _transport.messages.where((m) => m.channel == name).listen(_dispatch);
  }

  void _dispatch(BridgeMessage m) {
    for (final l in List.from(_listeners)) {
      l(m);
    }
  }

  void listen(void Function(BridgeMessage) handler) {
    _listeners.add(handler);
  }

  void removeListener(void Function(BridgeMessage) handler) {
    _listeners.remove(handler);
  }

  Future<void> sendEvent(String type, dynamic payload) async {
    await _transport
        .send(BridgeMessage(channel: name, type: type, payload: payload));
  }
}
