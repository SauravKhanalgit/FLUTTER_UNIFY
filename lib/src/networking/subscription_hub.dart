/// Real-time subscription multiplexer with pluggable transport registry.
///
/// Provides unified stream abstraction for: WebSocket, GraphQL subscriptions,
/// server-sent events (future), custom transports.
///
/// Features roadmap:
/// - Automatic re-subscribe on connection loss
/// - Heartbeats + latency measurement
/// - Backpressure handling & stream pause/resume
import 'dart:async';

class SubscriptionDescriptor {
  final String id; // internal tracking
  final String channel; // logical channel or topic
  final String? operation; // optional GraphQL op name
  final Map<String, dynamic>? variables;
  final String? preferredTransport; // hint
  SubscriptionDescriptor({
    required this.id,
    required this.channel,
    this.operation,
    this.variables,
    this.preferredTransport,
  });
}

class SubscriptionEvent {
  final String id;
  final String channel;
  final dynamic data;
  final DateTime timestamp;
  final bool isError;
  final String? error;
  SubscriptionEvent({
    required this.id,
    required this.channel,
    required this.data,
    this.isError = false,
    this.error,
  }) : timestamp = DateTime.now();
}

abstract class SubscriptionTransport {
  String get name;
  Future<void> connect();
  Future<void> disconnect();
  bool get isConnected;
  bool get isConnecting => false; // optional override
  bool supports(SubscriptionDescriptor descriptor) => true; // capability filter
  Stream<dynamic> subscribeRaw(SubscriptionDescriptor descriptor);
  Future<void> unsubscribe(SubscriptionDescriptor descriptor);
}

/// In-memory mock transport for testing.
class MockSubscriptionTransport implements SubscriptionTransport {
  bool _connected = false;
  @override
  String get name => 'mock';
  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  bool get isConnected => _connected;
  @override
  bool get isConnecting => false;
  @override
  bool supports(SubscriptionDescriptor descriptor) => true;
  @override
  Stream<dynamic> subscribeRaw(SubscriptionDescriptor descriptor) async* {
    yield {
      'mock': true,
      'channel': descriptor.channel,
      'op': descriptor.operation,
      'echo': descriptor.variables,
      'transport': name,
    };
  }

  @override
  Future<void> unsubscribe(SubscriptionDescriptor descriptor) async {}
}

class SubscriptionHub {
  SubscriptionHub._();
  static SubscriptionHub? _instance;
  static SubscriptionHub get instance => _instance ??= SubscriptionHub._();

  // Transport registry
  final Map<String, SubscriptionTransport> _transports = {};
  String? _activeTransportName; // explicit override

  // Controllers per subscription id
  final Map<String, StreamController<SubscriptionEvent>> _controllers = {};
  // Track which transport a subscription used
  final Map<String, String> _subscriptionTransport = {};

  // Register default mock at construction
  void _ensureDefault() {
    if (!_transports.containsKey('mock')) {
      registerTransport(MockSubscriptionTransport());
      _activeTransportName ??= 'mock';
    }
  }

  void registerTransport(SubscriptionTransport transport) {
    _transports[transport.name] = transport;
  }

  void unregisterTransport(String name) {
    _transports.remove(name);
    if (_activeTransportName == name) _activeTransportName = null;
  }

  List<String> get registeredTransports =>
      _transports.keys.toList(growable: false);

  void setActiveTransport(String name) {
    if (_transports.containsKey(name)) _activeTransportName = name;
  }

  SubscriptionTransport? get activeTransport =>
      _activeTransportName != null ? _transports[_activeTransportName] : null;

  Future<void> initialize() async {
    _ensureDefault();
    // Lazily connect on first subscribe; no-op here.
  }

  SubscriptionTransport _selectTransport(SubscriptionDescriptor descriptor) {
    // 1. Explicit preferred transport
    if (descriptor.preferredTransport != null) {
      final t = _transports[descriptor.preferredTransport!];
      if (t != null) return t;
    }
    // 2. Active transport override
    if (activeTransport != null) return activeTransport!;
    // 3. First connected & supporting
    for (final t in _transports.values) {
      if (t.isConnected && t.supports(descriptor)) return t;
    }
    // 4. Any supporting transport (connect later)
    for (final t in _transports.values) {
      if (t.supports(descriptor)) return t;
    }
    // Fallback: ensure default mock
    return _transports['mock']!;
  }

  Future<void> _ensureConnected(SubscriptionTransport transport) async {
    if (!transport.isConnected) {
      await transport.connect();
    }
  }

  Stream<SubscriptionEvent> subscribe(SubscriptionDescriptor descriptor) {
    final existing = _controllers[descriptor.id];
    if (existing != null) return existing.stream;

    final controller = StreamController<SubscriptionEvent>.broadcast();
    _controllers[descriptor.id] = controller;

    final transport = _selectTransport(descriptor);
    _subscriptionTransport[descriptor.id] = transport.name;

    _ensureConnected(transport).then((_) {
      // Wire underlying raw stream
      transport.subscribeRaw(descriptor).listen((raw) {
        controller.add(SubscriptionEvent(
          id: descriptor.id,
          channel: descriptor.channel,
          data: raw,
        ));
      }, onError: (e) {
        controller.add(SubscriptionEvent(
          id: descriptor.id,
          channel: descriptor.channel,
          data: null,
          isError: true,
          error: e.toString(),
        ));
      });
    });

    return controller.stream;
  }

  Future<void> unsubscribe(String id) async {
    final controller = _controllers.remove(id);
    if (controller != null) {
      await controller.close();
    }
    final transportName = _subscriptionTransport.remove(id);
    if (transportName != null) {
      // We don't call unsubscribe on underlying transport because we lack descriptor context.
      // Future enhancement: maintain descriptor map.
    }
  }

  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
    _controllers.clear();
    _subscriptionTransport.clear();
    // Disconnect all transports
    for (final t in _transports.values) {
      await t.disconnect();
    }
  }
}
