import 'dart:async';
import 'dart:convert';

import '../adapters/networking_adapter.dart';
import '../models/networking_models.dart';
import '../feature_flags/feature_flags.dart';
import 'offline_queue_store.dart';

/// Policy describing how to cache responses.
class CachePolicy {
  final Duration ttl;
  final bool enabled;
  const CachePolicy(
      {this.ttl = const Duration(minutes: 5), this.enabled = true});
  static const disabled = CachePolicy(enabled: false, ttl: Duration.zero);
}

/// Policy describing how to retry failed requests.
class RetryPolicy {
  final int maxRetries;
  final Duration baseDelay;
  final bool exponentialBackoff;
  const RetryPolicy(
      {this.maxRetries = 3,
      this.baseDelay = const Duration(milliseconds: 400),
      this.exponentialBackoff = true});
  static const none = RetryPolicy(
      maxRetries: 0, baseDelay: Duration.zero, exponentialBackoff: false);
}

/// Queue persistence mode.
enum QueuePersistence { memory /* future: hive, sqlite */ }

/// Represents a queued network operation for offline-first behavior.
class QueuedRequest {
  final NetworkRequest request;
  final DateTime enqueuedAt;
  int attempts = 0;
  Completer<NetworkResponse> completer;
  QueuedRequest(this.request)
      : enqueuedAt = DateTime.now(),
        completer = Completer<NetworkResponse>();
}

/// Offline + retry aware wrapper over a lower-level NetworkingAdapter.
///
/// Current status:
/// - In-memory queue only
/// - Basic retry with optional exponential backoff
/// - Simple cache map (keyed by method+url+hash(body))
/// - Flag gated via `offline_networking`
class OfflineClient {
  final NetworkingAdapter _adapter;
  final Map<String, _CacheEntry> _cache = {};
  final List<QueuedRequest> _queue = [];
  bool _processing = false;
  bool _online = true;
  final OfflineQueueStore _store; // new

  CachePolicy defaultCachePolicy = const CachePolicy();
  RetryPolicy defaultRetryPolicy = const RetryPolicy();

  OfflineClient(this._adapter, {OfflineQueueStore? store})
      : _store = store ?? MemoryQueueStore();

  Future<void> initializePersistence() async {
    await _store.initialize();
    final loaded = await _store.load();
    if (loaded.isNotEmpty) {
      for (final r in loaded) {
        _queue.add(QueuedRequest(r));
      }
    }
  }

  // Connectivity binding (placeholder: tie into UnifiedNetworking later)
  void setOnline(bool online) {
    _online = online;
    if (_online) _processQueue();
  }

  Future<NetworkResponse> execute(NetworkRequest request,
      {CachePolicy? cachePolicy,
      RetryPolicy? retryPolicy,
      bool queueIfOffline = true}) async {
    if (!UnifyFeatures.instance.isEnabled('offline_networking')) {
      return _adapter.request(request);
    }

    final appliedCache = cachePolicy ?? defaultCachePolicy;
    final appliedRetry = retryPolicy ?? defaultRetryPolicy;

    final cacheKey = _cacheKey(request);
    if (appliedCache.enabled) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        return cached.response;
      }
    }

    if (!_online && queueIfOffline && request.method != HttpMethod.get) {
      final qr = QueuedRequest(request);
      _queue.add(qr);
      _persistQueue();
      return qr.completer.future; // resolves once processed
    }

    return _attemptRequest(request, appliedCache, appliedRetry, cacheKey);
  }

  Future<NetworkResponse> _attemptRequest(NetworkRequest request,
      CachePolicy cachePolicy, RetryPolicy retryPolicy, String cacheKey) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await _adapter.request(request);
        if (cachePolicy.enabled && request.method == HttpMethod.get) {
          _cache[cacheKey] = _CacheEntry(response, cachePolicy.ttl);
        }
        return response;
      } catch (e) {
        if (attempt >= retryPolicy.maxRetries) rethrow;
        attempt++;
        final delay = retryPolicy.exponentialBackoff
            ? retryPolicy.baseDelay * attempt
            : retryPolicy.baseDelay;
        await Future.delayed(delay);
      }
    }
  }

  void _processQueue() {
    if (_processing) return;
    _processing = true;
    Future.microtask(() async {
      while (_queue.isNotEmpty && _online) {
        final qr = _queue.removeAt(0);
        try {
          final resp = await _attemptRequest(qr.request, CachePolicy.disabled,
              defaultRetryPolicy, _cacheKey(qr.request));
          qr.completer.complete(resp);
        } catch (e) {
          qr.completer.completeError(e);
        }
      }
      await _persistQueue();
      _processing = false;
    });
  }

  Future<void> _persistQueue() async {
    // Filter only original requests (ignore those already resolved);
    final remaining = _queue.map((q) => q.request).toList();
    await _store.save(remaining);
  }

  String _cacheKey(NetworkRequest request) {
    final bodyHash = request.data == null ? '' : request.data.hashCode;
    return '${request.method.name}:${request.url}:${bodyHash}:${jsonEncode(request.queryParameters ?? {})}';
  }
}

class _CacheEntry {
  final NetworkResponse response;
  final DateTime expiresAt;
  _CacheEntry(this.response, Duration ttl)
      : expiresAt = DateTime.now().add(ttl);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
