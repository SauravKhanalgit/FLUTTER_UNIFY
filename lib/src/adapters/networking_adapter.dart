/// Networking adapter interface and implementations
///
/// This defines the interface that all networking adapters must implement,
/// allowing for pluggable backends like HTTP clients, WebSocket libraries,
/// and connectivity detection systems.

import 'dart:async';
import 'dart:typed_data';
import '../models/networking_models.dart';

/// Abstract base class for all networking adapters
///
/// This allows the unified networking system to work with different
/// networking backends depending on the platform and requirements.
///
/// Adapters can be:
/// - HttpAdapter (using dart:io HttpClient or package:http)
/// - DioAdapter (using Dio package)
/// - WebAdapter (using web APIs)
/// - MockAdapter (for testing)
/// - OfflineAdapter (for offline-first apps)
abstract class NetworkingAdapter {
  /// Name of this adapter
  String get name;

  /// Version of this adapter
  String get version;

  /// Initialize the adapter
  Future<bool> initialize();

  // Connectivity

  /// Stream of connectivity changes
  Stream<ConnectivityStatus> get onConnectivityChanged;

  /// Check current connectivity
  Future<ConnectivityStatus> checkConnectivity();

  // HTTP Requests

  /// Make a network request
  Future<NetworkResponse> request(NetworkRequest request);

  // File Upload/Download

  /// Upload a file with progress tracking
  Stream<UploadProgress> upload(
    String url,
    Uint8List fileBytes,
    String fileName, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
    String fieldName = 'file',
  });

  /// Download a file with progress tracking
  Stream<DownloadProgress> download(
    String url, {
    Map<String, String>? headers,
    String? savePath,
  });

  // WebSocket

  /// Connect to a WebSocket
  Future<WebSocketConnection> connectWebSocket(
    String url, {
    Map<String, String>? headers,
    List<String>? protocols,
    Duration? pingInterval,
    bool autoReconnect = true,
  });

  // GraphQL (optional - not all adapters support this)

  /// Execute a GraphQL query
  Future<GraphQLResponse> graphQL(
    String endpoint,
    String query, {
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
    String? operationName,
  });

  // gRPC (optional - not all adapters support this)

  /// Make a gRPC call
  Future<GrpcResponse> grpc(
    String endpoint,
    String service,
    String method,
    Map<String, dynamic> request, {
    Map<String, String>? metadata,
    Duration? timeout,
  });

  // Request/Response Interceptors

  /// Add request interceptor
  void addRequestInterceptor(RequestInterceptor interceptor);

  /// Add response interceptor
  void addResponseInterceptor(ResponseInterceptor interceptor);

  /// Remove request interceptor
  void removeRequestInterceptor(RequestInterceptor interceptor);

  /// Remove response interceptor
  void removeResponseInterceptor(ResponseInterceptor interceptor);

  // Caching

  /// Enable response caching
  void enableCaching({
    Duration defaultTtl = const Duration(minutes: 5),
    int maxCacheSize = 50,
  });

  /// Disable response caching
  void disableCaching();

  /// Clear response cache
  void clearCache();

  // Statistics

  /// Get network statistics
  Future<NetworkStatistics> getStatistics();

  /// Reset network statistics
  void resetStatistics();

  /// Dispose resources
  Future<void> dispose();
}

/// Mock networking adapter for testing and development
class MockNetworkingAdapter extends NetworkingAdapter {
  final List<RequestInterceptor> _requestInterceptors = [];
  final List<ResponseInterceptor> _responseInterceptors = [];
  final Map<String, NetworkResponse> _cache = {};
  bool _cachingEnabled = false;
  Duration _defaultCacheTtl = const Duration(minutes: 5);

  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  int _totalBytesUploaded = 0;
  int _totalBytesDownloaded = 0;
  final List<Duration> _responseTimes = [];
  final DateTime _startTime = DateTime.now();

  @override
  String get name => 'MockNetworkingAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    return true;
  }

  // Connectivity
  @override
  Stream<ConnectivityStatus> get onConnectivityChanged {
    // Mock connectivity stream - emit periodic changes
    return Stream.periodic(const Duration(seconds: 10), (count) {
      final types = [
        ConnectivityType.wifi,
        ConnectivityType.mobile,
        ConnectivityType.ethernet
      ];
      return ConnectivityStatus(
        type: types[count % types.length],
        isConnected: true,
        strength: 80 + (count % 20),
        speed: 50.0 + (count % 50),
      );
    });
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return ConnectivityStatus(
      type: ConnectivityType.wifi,
      isConnected: true,
      strength: 95,
      speed: 100.0,
    );
  }

  // HTTP Requests
  @override
  Future<NetworkResponse> request(NetworkRequest request) async {
    _totalRequests++;
    final startTime = DateTime.now();

    try {
      // Apply request interceptors
      var processedRequest = request;
      for (final interceptor in _requestInterceptors) {
        processedRequest = await interceptor(processedRequest);
      }

      // Check cache first
      final cacheKey = _getCacheKey(processedRequest);
      if (_cachingEnabled && _cache.containsKey(cacheKey)) {
        final cachedResponse = _cache[cacheKey]!;
        _successfulRequests++;
        return cachedResponse;
      }

      // Simulate network delay
      await Future.delayed(
          Duration(milliseconds: 100 + (request.url.length % 200)));

      // Mock response based on request
      final responseData = _generateMockResponse(processedRequest);

      var response = NetworkResponse(
        statusCode: 200,
        data: responseData,
        headers: {
          'content-type': 'application/json',
          'x-mock-adapter': 'true',
        },
        request: processedRequest,
        responseTime: DateTime.now().difference(startTime),
      );

      // Apply response interceptors
      for (final interceptor in _responseInterceptors) {
        response = await interceptor(response);
      }

      // Cache response if enabled
      if (_cachingEnabled && processedRequest.cacheResponse) {
        _cache[cacheKey] = response;
        // Clean up old cache entries
        Timer(_defaultCacheTtl, () => _cache.remove(cacheKey));
      }

      _successfulRequests++;
      _responseTimes.add(response.responseTime ?? Duration.zero);

      return response;
    } catch (e) {
      _failedRequests++;
      rethrow;
    }
  }

  // File Upload/Download
  @override
  Stream<UploadProgress> upload(
    String url,
    Uint8List fileBytes,
    String fileName, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
    String fieldName = 'file',
  }) async* {
    final uploadId = 'mock_upload_${DateTime.now().millisecondsSinceEpoch}';
    final totalBytes = fileBytes.length;

    // Mock upload progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));

      final uploadedBytes = (totalBytes * i / 100).round();
      final speed =
          i > 0 ? (uploadedBytes / (i * 0.05)) : 0.0; // bytes per second
      final remainingTime =
          speed > 0 ? ((totalBytes - uploadedBytes) / speed).round() : null;

      yield UploadProgress(
        id: uploadId,
        fileName: fileName,
        totalBytes: totalBytes,
        uploadedBytes: uploadedBytes,
        percentage: i.toDouble(),
        isComplete: i == 100,
        speed: speed,
        remainingTime: remainingTime,
      );

      if (i == 100) {
        _totalBytesUploaded += totalBytes;
      }
    }
  }

  @override
  Stream<DownloadProgress> download(
    String url, {
    Map<String, String>? headers,
    String? savePath,
  }) async* {
    final downloadId = 'mock_download_${DateTime.now().millisecondsSinceEpoch}';
    const totalBytes = 1024 * 1024; // 1MB mock file

    // Mock download progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));

      final downloadedBytes = (totalBytes * i / 100).round();
      final speed =
          i > 0 ? (downloadedBytes / (i * 0.05)) : 0.0; // bytes per second
      final remainingTime =
          speed > 0 ? ((totalBytes - downloadedBytes) / speed).round() : null;

      yield DownloadProgress(
        id: downloadId,
        url: url,
        savePath: savePath,
        totalBytes: totalBytes,
        downloadedBytes: downloadedBytes,
        percentage: i.toDouble(),
        isComplete: i == 100,
        data: i == 100
            ? Uint8List.fromList(
                List.generate(totalBytes, (index) => index % 256))
            : null,
        speed: speed,
        remainingTime: remainingTime,
      );

      if (i == 100) {
        _totalBytesDownloaded += totalBytes;
      }
    }
  }

  // WebSocket
  @override
  Future<WebSocketConnection> connectWebSocket(
    String url, {
    Map<String, String>? headers,
    List<String>? protocols,
    Duration? pingInterval,
    bool autoReconnect = true,
  }) async {
    // Simulate connection delay
    await Future.delayed(const Duration(milliseconds: 200));
    return MockWebSocketConnection(url, headers: headers, protocols: protocols);
  }

  // GraphQL
  @override
  Future<GraphQLResponse> graphQL(
    String endpoint,
    String query, {
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
    String? operationName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return GraphQLResponse(
      data: {
        'mock': true,
        'operation': operationName,
        'query': query.substring(0, query.length > 50 ? 50 : query.length),
        'variables': variables,
      },
      errors: null,
      extensions: {
        'tracing': {
          'version': 1,
          'startTime': DateTime.now().toIso8601String(),
          'duration': 150000000, // 150ms in nanoseconds
        },
      },
    );
  }

  // gRPC
  @override
  Future<GrpcResponse> grpc(
    String endpoint,
    String service,
    String method,
    Map<String, dynamic> request, {
    Map<String, String>? metadata,
    Duration? timeout,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return GrpcResponse(
      data: {
        'mock': true,
        'service': service,
        'method': method,
        'request': request,
      },
      statusCode: 0, // OK
      statusMessage: 'OK',
      metadata: metadata ?? {},
    );
  }

  // Request/Response Interceptors
  @override
  void addRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  @override
  void addResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  @override
  void removeRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.remove(interceptor);
  }

  @override
  void removeResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.remove(interceptor);
  }

  // Caching
  @override
  void enableCaching({
    Duration defaultTtl = const Duration(minutes: 5),
    int maxCacheSize = 50,
  }) {
    _cachingEnabled = true;
    _defaultCacheTtl = defaultTtl;
  }

  @override
  void disableCaching() {
    _cachingEnabled = false;
    _cache.clear();
  }

  @override
  void clearCache() {
    _cache.clear();
  }

  // Statistics
  @override
  Future<NetworkStatistics> getStatistics() async {
    final averageResponseTime = _responseTimes.isNotEmpty
        ? Duration(
            microseconds: _responseTimes
                    .map((d) => d.inMicroseconds)
                    .reduce((a, b) => a + b) ~/
                _responseTimes.length,
          )
        : Duration.zero;

    return NetworkStatistics(
      totalRequests: _totalRequests,
      successfulRequests: _successfulRequests,
      failedRequests: _failedRequests,
      totalBytesUploaded: _totalBytesUploaded,
      totalBytesDownloaded: _totalBytesDownloaded,
      averageResponseTime: averageResponseTime,
      startTime: _startTime,
    );
  }

  @override
  void resetStatistics() {
    _totalRequests = 0;
    _successfulRequests = 0;
    _failedRequests = 0;
    _totalBytesUploaded = 0;
    _totalBytesDownloaded = 0;
    _responseTimes.clear();
  }

  @override
  Future<void> dispose() async {
    _requestInterceptors.clear();
    _responseInterceptors.clear();
    _cache.clear();
  }

  // Private helper methods
  String _getCacheKey(NetworkRequest request) {
    return '${request.method.name}:${request.url}:${request.queryParameters?.toString() ?? ''}';
  }

  Map<String, dynamic> _generateMockResponse(NetworkRequest request) {
    switch (request.method) {
      case HttpMethod.get:
        return {
          'message': 'Mock GET response',
          'url': request.url,
          'timestamp': DateTime.now().toIso8601String(),
          'data': List.generate(5, (i) => {'id': i, 'name': 'Item $i'}),
        };
      case HttpMethod.post:
        return {
          'message': 'Mock POST response',
          'created': true,
          'id': DateTime.now().millisecondsSinceEpoch,
          'data': request.data,
        };
      case HttpMethod.put:
        return {
          'message': 'Mock PUT response',
          'updated': true,
          'data': request.data,
        };
      case HttpMethod.delete:
        return {
          'message': 'Mock DELETE response',
          'deleted': true,
        };
      case HttpMethod.patch:
        return {
          'message': 'Mock PATCH response',
          'patched': true,
          'data': request.data,
        };
      default:
        return {
          'message': 'Mock ${request.method.name.toUpperCase()} response',
          'method': request.method.name,
        };
    }
  }
}

/// Mock WebSocket connection for testing
class MockWebSocketConnection extends WebSocketConnection {
  final StreamController<dynamic> _messageController =
      StreamController.broadcast();
  final StreamController<WebSocketEvent> _eventController =
      StreamController.broadcast();
  bool _isConnected = true;
  Timer? _pingTimer;
  Timer? _messageTimer;

  MockWebSocketConnection(
    String url, {
    Map<String, String>? headers,
    List<String>? protocols,
  }) : super(url, headers: headers, protocols: protocols) {
    _initialize();
  }

  void _initialize() {
    // Emit connection event
    Timer(const Duration(milliseconds: 100), () {
      _eventController.add(WebSocketEvent(type: WebSocketEventType.connected));
    });

    // Send periodic mock messages
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isConnected) {
        _messageController.add({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
          'message': 'Mock WebSocket message',
        });
      }
    });

    // Send periodic ping (if required)
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        send({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
      }
    });
  }

  @override
  Stream<dynamic> get messages => _messageController.stream;

  @override
  Stream<WebSocketEvent> get events => _eventController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  void send(dynamic message) {
    if (!_isConnected) {
      throw StateError('WebSocket is not connected');
    }

    // Echo back the message after a short delay
    Timer(const Duration(milliseconds: 50), () {
      if (_isConnected) {
        _messageController.add({
          'type': 'echo',
          'original': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.message,
      data: message,
    ));
  }

  @override
  void sendText(String message) {
    send(message);
  }

  @override
  void sendBytes(Uint8List bytes) {
    send(bytes);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    if (!_isConnected) return;

    _isConnected = false;
    _pingTimer?.cancel();
    _messageTimer?.cancel();

    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.disconnected,
      data: {'code': code, 'reason': reason},
    ));

    await _messageController.close();
    await _eventController.close();
  }
}

/// HTTP-based adapter using dart:io or package:http
class HttpAdapter extends NetworkingAdapter {
  @override
  String get name => 'HttpAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    // Initialize HTTP client
    return true;
  }

  // Implementation would use actual HTTP client
  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => Stream.empty();

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return ConnectivityStatus(
        type: ConnectivityType.unknown, isConnected: false);
  }

  @override
  Future<NetworkResponse> request(NetworkRequest request) async {
    throw UnimplementedError('HttpAdapter not fully implemented');
  }

  @override
  Stream<UploadProgress> upload(
      String url, Uint8List fileBytes, String fileName,
      {Map<String, String>? headers,
      Map<String, dynamic>? fields,
      String fieldName = 'file'}) async* {}

  @override
  Stream<DownloadProgress> download(String url,
      {Map<String, String>? headers, String? savePath}) async* {}

  @override
  Future<WebSocketConnection> connectWebSocket(String url,
      {Map<String, String>? headers,
      List<String>? protocols,
      Duration? pingInterval,
      bool autoReconnect = true}) async {
    throw UnimplementedError('WebSocket not implemented in HttpAdapter');
  }

  @override
  Future<GraphQLResponse> graphQL(String endpoint, String query,
      {Map<String, dynamic>? variables,
      Map<String, String>? headers,
      String? operationName}) async {
    throw UnimplementedError('GraphQL not implemented in HttpAdapter');
  }

  @override
  Future<GrpcResponse> grpc(String endpoint, String service, String method,
      Map<String, dynamic> request,
      {Map<String, String>? metadata, Duration? timeout}) async {
    throw UnimplementedError('gRPC not implemented in HttpAdapter');
  }

  @override
  void addRequestInterceptor(RequestInterceptor interceptor) {}

  @override
  void addResponseInterceptor(ResponseInterceptor interceptor) {}

  @override
  void removeRequestInterceptor(RequestInterceptor interceptor) {}

  @override
  void removeResponseInterceptor(ResponseInterceptor interceptor) {}

  @override
  void enableCaching(
      {Duration defaultTtl = const Duration(minutes: 5),
      int maxCacheSize = 50}) {}

  @override
  void disableCaching() {}

  @override
  void clearCache() {}

  @override
  Future<NetworkStatistics> getStatistics() async {
    return NetworkStatistics(
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      totalBytesUploaded: 0,
      totalBytesDownloaded: 0,
      averageResponseTime: Duration.zero,
    );
  }

  @override
  void resetStatistics() {}

  @override
  Future<void> dispose() async {}
}

/// Dio-based adapter for advanced HTTP features
class DioAdapter extends NetworkingAdapter {
  @override
  String get name => 'DioAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    // Initialize Dio
    return true;
  }

  // Implementation would use Dio package
  // Similar structure to HttpAdapter but with Dio features

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => Stream.empty();

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return ConnectivityStatus(
        type: ConnectivityType.unknown, isConnected: false);
  }

  @override
  Future<NetworkResponse> request(NetworkRequest request) async {
    throw UnimplementedError('DioAdapter not fully implemented');
  }

  @override
  Stream<UploadProgress> upload(
      String url, Uint8List fileBytes, String fileName,
      {Map<String, String>? headers,
      Map<String, dynamic>? fields,
      String fieldName = 'file'}) async* {}

  @override
  Stream<DownloadProgress> download(String url,
      {Map<String, String>? headers, String? savePath}) async* {}

  @override
  Future<WebSocketConnection> connectWebSocket(String url,
      {Map<String, String>? headers,
      List<String>? protocols,
      Duration? pingInterval,
      bool autoReconnect = true}) async {
    throw UnimplementedError('WebSocket not implemented in DioAdapter');
  }

  @override
  Future<GraphQLResponse> graphQL(String endpoint, String query,
      {Map<String, dynamic>? variables,
      Map<String, String>? headers,
      String? operationName}) async {
    throw UnimplementedError('GraphQL not implemented in DioAdapter');
  }

  @override
  Future<GrpcResponse> grpc(String endpoint, String service, String method,
      Map<String, dynamic> request,
      {Map<String, String>? metadata, Duration? timeout}) async {
    throw UnimplementedError('gRPC not implemented in DioAdapter');
  }

  @override
  void addRequestInterceptor(RequestInterceptor interceptor) {}

  @override
  void addResponseInterceptor(ResponseInterceptor interceptor) {}

  @override
  void removeRequestInterceptor(RequestInterceptor interceptor) {}

  @override
  void removeResponseInterceptor(ResponseInterceptor interceptor) {}

  @override
  void enableCaching(
      {Duration defaultTtl = const Duration(minutes: 5),
      int maxCacheSize = 50}) {}

  @override
  void disableCaching() {}

  @override
  void clearCache() {}

  @override
  Future<NetworkStatistics> getStatistics() async {
    return NetworkStatistics(
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      totalBytesUploaded: 0,
      totalBytesDownloaded: 0,
      averageResponseTime: Duration.zero,
    );
  }

  @override
  void resetStatistics() {}

  @override
  Future<void> dispose() async {}
}
