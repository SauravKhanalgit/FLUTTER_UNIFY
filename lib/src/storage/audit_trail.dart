import 'dart:async';

/// Simple audit trail for CRUD ops with pluggable sink
class AuditTrail {
  AuditTrail._();
  static AuditTrail? _instance;
  static AuditTrail get instance => _instance ??= AuditTrail._();

  final _controller = StreamController<AuditEvent>.broadcast();
  Stream<AuditEvent> get stream => _controller.stream;
  void Function(AuditEvent)? _externalSink;

  void setExternalSink(void Function(AuditEvent) sink) {
    _externalSink = sink;
  }

  void log({
    required String entity,
    required String operation, // CREATE/READ/UPDATE/DELETE/SYNC
    String? id,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    Map<String, dynamic>? meta,
  }) {
    final evt = AuditEvent(
      entity: entity,
      operation: operation,
      id: id,
      timestamp: DateTime.now(),
      before: before,
      after: after,
      meta: meta,
    );
    _controller.add(evt);
    _externalSink?.call(evt);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class AuditEvent {
  final String entity;
  final String operation;
  final String? id;
  final DateTime timestamp;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final Map<String, dynamic>? meta;

  const AuditEvent({
    required this.entity,
    required this.operation,
    required this.timestamp,
    this.id,
    this.before,
    this.after,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
        'entity': entity,
        'op': operation,
        'id': id,
        'ts': timestamp.toIso8601String(),
        if (before != null) 'before': before,
        if (after != null) 'after': after,
        if (meta != null) 'meta': meta,
      };
}
