import '../models/networking_models.dart';
import 'dart:async';

/// Abstraction for persisting queued network requests.
abstract class OfflineQueueStore {
  Future<void> initialize();
  Future<List<NetworkRequest>> load();
  Future<void> save(List<NetworkRequest> queue);
  Future<void> clear();
}

/// In-memory fallback implementation (no persistence across restarts).
class MemoryQueueStore implements OfflineQueueStore {
  final _buffer = <NetworkRequest>[];
  @override
  Future<void> initialize() async {}
  @override
  Future<List<NetworkRequest>> load() async => List.unmodifiable(_buffer);
  @override
  Future<void> save(List<NetworkRequest> queue) async {
    _buffer
      ..clear()
      ..addAll(queue);
  }

  @override
  Future<void> clear() async => _buffer.clear();
}

/// (Stub) Hive-backed queue store (to be completed in future phase).
/// Currently behaves like memory but documents intended usage.
class HiveQueueStore implements OfflineQueueStore {
  bool _initialized = false;
  @override
  Future<void> initialize() async {
    // TODO: integrate hive_flutter initialization (Hive.initFlutter()) externally
    _initialized = true; // mark ready
  }

  @override
  Future<List<NetworkRequest>> load() async {
    if (!_initialized) return [];
    // TODO: read from Hive box and deserialize
    return [];
  }

  @override
  Future<void> save(List<NetworkRequest> queue) async {
    if (!_initialized) return;
    // TODO: serialize and write to Hive box
  }

  @override
  Future<void> clear() async {
    if (!_initialized) return;
    // TODO: clear Hive box
  }
}

/// Simple JSON (plain map) serialization helpers.
extension NetworkRequestSerialization on NetworkRequest {
  Map<String, dynamic> toPersistedMap() => {
        'm': method.name,
        'u': url,
        if (data is String || data is num || data is bool) 'd': data,
        if (data is Map<String, dynamic>) 'dj': data,
        if (headers != null) 'h': headers,
        if (queryParameters != null) 'q': queryParameters,
        'ro': retryOnFailure,
        'mr': maxRetries,
        'qo': queueOffline,
        'pr': priority,
        'cr': cacheResponse,
        if (cacheTtl != null) 'ct': cacheTtl!.inMilliseconds,
      };

  static NetworkRequest fromPersistedMap(Map<String, dynamic> m) {
    final methodName = m['m'] as String? ?? 'get';
    final method = HttpMethod.values.firstWhere(
      (e) => e.name == methodName,
      orElse: () => HttpMethod.get,
    );
    final dynamic rawData = m.containsKey('dj') ? m['dj'] : m['d'];
    return NetworkRequest(
      method: method,
      url: m['u'] as String? ?? '',
      data: rawData,
      headers: (m['h'] as Map?)?.cast<String, String>(),
      queryParameters: (m['q'] as Map?)?.cast<String, dynamic>(),
      retryOnFailure: m['ro'] == true,
      maxRetries: (m['mr'] as int?) ?? 3,
      queueOffline: m['qo'] == true,
      priority: (m['pr'] as int?) ?? 0,
      cacheResponse: m['cr'] == true,
      cacheTtl:
          m['ct'] != null ? Duration(milliseconds: (m['ct'] as int)) : null,
    );
  }
}
