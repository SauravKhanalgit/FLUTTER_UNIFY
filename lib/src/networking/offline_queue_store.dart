import '../models/networking_models.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

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

/// Hive-backed queue store for persistent offline request queuing.
/// 
/// Requires Hive to be initialized externally before use:
/// ```dart
/// await Hive.initFlutter();
/// final store = HiveQueueStore();
/// await store.initialize();
/// ```
class HiveQueueStore implements OfflineQueueStore {
  static const String _boxName = 'flutter_unify_offline_queue';
  Box? _box;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Open or create the Hive box for storing queue
      _box = await Hive.openBox(_boxName);
      _initialized = true;
    } catch (e) {
      // If Hive is not initialized, fall back to memory behavior
      // This allows the store to work even if Hive.initFlutter() wasn't called
      _initialized = false;
    }
  }

  @override
  Future<List<NetworkRequest>> load() async {
    if (!_initialized || _box == null) return [];
    
    try {
      final storedData = _box!.get('queue');
      if (storedData == null || storedData is! List) return [];
      
      return storedData
          .map((map) => NetworkRequestSerialization.fromPersistedMap(
              Map<String, dynamic>.from(map as Map)))
          .toList();
    } catch (e) {
      // If deserialization fails, return empty list
      return [];
    }
  }

  @override
  Future<void> save(List<NetworkRequest> queue) async {
    if (!_initialized || _box == null) return;
    
    try {
      final serialized = queue
          .map((req) => req.toPersistedMap())
          .toList();
      await _box!.put('queue', serialized);
    } catch (e) {
      // If serialization fails, silently fail (queue will be lost)
      // In production, you might want to log this error
    }
  }

  @override
  Future<void> clear() async {
    if (!_initialized || _box == null) return;
    
    try {
      await _box!.delete('queue');
    } catch (e) {
      // If deletion fails, try to save empty list
      await _box!.put('queue', <Map<String, dynamic>>[]);
    }
  }

  /// Close the Hive box (call when disposing)
  Future<void> close() async {
    if (_box != null) {
      await _box!.close();
      _box = null;
      _initialized = false;
    }
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
