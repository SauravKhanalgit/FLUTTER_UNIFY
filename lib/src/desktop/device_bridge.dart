/// Device Bridge & Peripheral IPC (BLE / Serial / USB) - skeleton
///
/// Goals:
///  - Provide unified discovery & connection API for IoT / peripheral devices
///  - Abstract transport (BLE / Serial / WebUSB / TCP) behind a common session
///  - Event-driven messaging with structured frames
///  - Pluggable codec (raw, json, cbor, protobuf later)
///
import 'dart:async';
import 'dart:convert';

abstract class PeripheralTransport {
  String get name;
  Future<bool> initialize();
  Future<List<PeripheralInfo>> scan({Duration timeout});
  Future<PeripheralSession> connect(PeripheralInfo info);
  Future<void> dispose();
  bool get isInitialized;
}

class PeripheralInfo {
  final String id; // MAC / path / identifier
  final String label; // friendly name
  final String transportHint; // ble | serial | usb | tcp
  final Map<String, dynamic>? metadata;
  PeripheralInfo({
    required this.id,
    required this.label,
    required this.transportHint,
    this.metadata,
  });
}

class PeripheralSession {
  final String id;
  final PeripheralInfo info;
  final StreamController<PeripheralFrame> _frames =
      StreamController.broadcast();
  bool _open = true;
  PeripheralSession(this.id, this.info);
  Stream<PeripheralFrame> get frames => _frames.stream;
  bool get isOpen => _open;
  void send(PeripheralFrame frame) {
    if (_open) _frames.add(frame);
  }

  Future<void> close() async {
    _open = false;
    await _frames.close();
  }
}

class PeripheralFrame {
  final DateTime ts = DateTime.now();
  final dynamic payload;
  final String codec; // json | raw
  PeripheralFrame(this.payload, {this.codec = 'json'});
  Map<String, dynamic> toJson() => {
        'ts': ts.toIso8601String(),
        'codec': codec,
        'payload': payload,
      };
}

/// Mock BLE/Serial hybrid transport
class MockPeripheralTransport implements PeripheralTransport {
  bool _init = false;
  @override
  String get name => 'mock_peripheral';
  @override
  bool get isInitialized => _init;
  @override
  Future<bool> initialize() async {
    _init = true;
    return true;
  }

  @override
  Future<void> dispose() async {
    _init = false;
  }

  @override
  Future<List<PeripheralInfo>> scan(
      {Duration timeout = const Duration(seconds: 2)}) async {
    if (!_init) throw StateError('Transport not initialized');
    await Future.delayed(timeout);
    return [
      PeripheralInfo(
          id: 'esp32-001', label: 'ESP32 DevKit', transportHint: 'ble'),
      PeripheralInfo(
          id: 'serial-ttyUSB0', label: 'USB Serial', transportHint: 'serial'),
    ];
  }

  @override
  Future<PeripheralSession> connect(PeripheralInfo info) async {
    if (!_init) throw StateError('Transport not initialized');
    return PeripheralSession(
        'sess_${DateTime.now().millisecondsSinceEpoch}', info);
  }
}

/// DeviceBridge facade
class DeviceBridge {
  DeviceBridge._();
  static DeviceBridge? _instance;
  static DeviceBridge get instance => _instance ??= DeviceBridge._();

  final Map<String, PeripheralTransport> _transports = {};
  PeripheralTransport? _active;

  void registerTransport(PeripheralTransport transport,
      {bool setActive = false}) {
    _transports[transport.name] = transport;
    if (setActive || _active == null) _active = transport;
  }

  List<String> get registered => _transports.keys.toList(growable: false);
  PeripheralTransport? get active => _active;
  set active(PeripheralTransport? t) => _active = t;

  Future<void> initialize() async {
    if (_transports.isEmpty) {
      registerTransport(MockPeripheralTransport(), setActive: true);
    }
    for (final t in _transports.values) {
      if (!t.isInitialized) {
        await t.initialize();
      }
    }
  }

  Future<List<PeripheralInfo>> scan(
      {Duration timeout = const Duration(seconds: 2)}) async {
    if (_active == null) throw StateError('No active peripheral transport');
    return _active!.scan(timeout: timeout);
  }

  Future<PeripheralSession> connect(String id) async {
    if (_active == null) throw StateError('No active peripheral transport');
    final devices = await scan();
    final target = devices.firstWhere((d) => d.id == id,
        orElse: () => throw ArgumentError('Device not found: $id'));
    return _active!.connect(target);
  }
}

/// Helper to encode a frame payload to json
String encodeFrame(PeripheralFrame frame) => jsonEncode(frame.toJson());
