/// 🌐 Unified Networking & Connectivity API
///
/// Wrap HTTP, WebSockets, gRPC, and platform connectivity detection.
/// Features automatic offline queueing and retry, with web polyfills
/// where native APIs are missing.
///
/// This provides a single interface for all networking operations
/// across all platforms with built-in offline support, retry logic,
/// and connectivity monitoring.
///
/// Example usage:
/// ```dart
/// // Simple HTTP requests
/// final response = await Unify.networking.get('https://api.example.com/users');
/// final users = response.data as List;
///
/// // With automatic retry and offline queueing
/// await Unify.networking.post(
///   'https://api.example.com/users',
///   data: {'name': 'John Doe'},
///   retryOnFailure: true,
///   queueOffline: true,
/// );
///
/// // WebSocket connections
/// final ws = await Unify.networking.connectWebSocket('wss://api.example.com/ws');
/// ws.listen((message) => print('Received: $message'));
///
/// // Connectivity monitoring
/// Unify.networking.onConnectivityChanged.listen((status) {
///   print('Connection: ${status.type}');
/// });
///
/// // Upload with progress
/// Unify.networking.upload(
///   'https://api.example.com/upload',
///   file: myFile,
/// ).listen((progress) {
///   print('Upload: ${progress.percentage}%');
/// });
/// ```

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../models/networking_models.dart';
import '../adapters/networking_adapter.dart';

/// Unified networking and connectivity API
///
/// This provides a single interface for all networking operations
/// including HTTP requests, WebSockets, connectivity monitoring,
/// and offline queue management.
class UnifiedNetworking {
  UnifiedNetworking._();

  static UnifiedNetworking? _instance;
  static UnifiedNetworking get instance => _instance ??= UnifiedNetworking._();

  NetworkingAdapter? _adapter;
  final StreamController<ConnectivityStatus> _connectivityController =
      StreamController.broadcast();
  final StreamController<NetworkRequest> _requestController =
      StreamController.broadcast();
  final StreamController<UploadProgress> _uploadController =
      StreamController.broadcast();
  final StreamController<DownloadProgress> _downloadController =
      StreamController.broadcast();

  final List<NetworkRequest> _offlineQueue = [];
  bool _isOnline = true;
  ConnectivityStatus _currentStatus = const ConnectivityStatus(
    type: ConnectivityType.unknown,
    isConnected: false,
  );

  /// Initialize the networking system
  Future<bool> initialize([NetworkingAdapter? adapter]) async {
    _adapter = adapter ?? DefaultNetworkingAdapter();
    final initialized = await _adapter!.initialize();

    if (initialized) {
      // Start monitoring connectivity
      _adapter!.onConnectivityChanged.listen((status) {
        _currentStatus = status;
        _isOnline = status.isConnected;
        _connectivityController.add(status);

        // Process offline queue when coming back online
        if (_isOnline) {
          _processOfflineQueue();
        }
      });
    }

    return initialized;
  }

  /// Register a custom networking adapter
  void registerAdapter(NetworkingAdapter adapter) {
    _adapter = adapter;
  }

  // Connectivity

  /// Current connectivity status
  ConnectivityStatus get connectivityStatus => _currentStatus;

  /// Whether device is currently online
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes
  Stream<ConnectivityStatus> get onConnectivityChanged =>
      _connectivityController.stream;

  /// Check current connectivity
  Future<ConnectivityStatus> checkConnectivity() async {
    if (_adapter == null) {
      return const ConnectivityStatus(
        type: ConnectivityType.unknown,
        isConnected: false,
      );
    }

    final status = await _adapter!.checkConnectivity();
    _currentStatus = status;
    _isOnline = status.isConnected;
    return status;
  }

  // HTTP Requests

  /// Make a GET request
  Future<NetworkResponse> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    bool retryOnFailure = false,
    int maxRetries = 3,
    bool queueOffline = false,
  }) async {
    return await _makeRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        timeout: timeout,
        retryOnFailure: retryOnFailure,
        maxRetries: maxRetries,
        queueOffline: queueOffline,
      ),
    );
  }

  /// Make a POST request
  Future<NetworkResponse> post(
    String url, {
    dynamic data,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    bool retryOnFailure = false,
    int maxRetries = 3,
    bool queueOffline = false,
  }) async {
    return await _makeRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: url,
        data: data,
        headers: headers,
        queryParameters: queryParameters,
        timeout: timeout,
        retryOnFailure: retryOnFailure,
        maxRetries: maxRetries,
        queueOffline: queueOffline,
      ),
    );
  }

  /// Make a PUT request
  Future<NetworkResponse> put(
    String url, {
    dynamic data,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    bool retryOnFailure = false,
    int maxRetries = 3,
    bool queueOffline = false,
  }) async {
    return await _makeRequest(
      NetworkRequest(
        method: HttpMethod.put,
        url: url,
        data: data,
        headers: headers,
        queryParameters: queryParameters,
        timeout: timeout,
        retryOnFailure: retryOnFailure,
        maxRetries: maxRetries,
        queueOffline: queueOffline,
      ),
    );
  }

  /// Make a DELETE request
  Future<NetworkResponse> delete(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    bool retryOnFailure = false,
    int maxRetries = 3,
    bool queueOffline = false,
  }) async {
    return await _makeRequest(
      NetworkRequest(
        method: HttpMethod.delete,
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        timeout: timeout,
        retryOnFailure: retryOnFailure,
        maxRetries: maxRetries,
        queueOffline: queueOffline,
      ),
    );
  }

  /// Make a PATCH request
  Future<NetworkResponse> patch(
    String url, {
    dynamic data,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    bool retryOnFailure = false,
    int maxRetries = 3,
    bool queueOffline = false,
  }) async {
    return await _makeRequest(
      NetworkRequest(
        method: HttpMethod.patch,
        url: url,
        data: data,
        headers: headers,
        queryParameters: queryParameters,
        timeout: timeout,
        retryOnFailure: retryOnFailure,
        maxRetries: maxRetries,
        queueOffline: queueOffline,
      ),
    );
  }

  /// Make a generic HTTP request
  Future<NetworkResponse> request(NetworkRequest request) async {
    return await _makeRequest(request);
  }

  // File Upload/Download

  /// Upload a file with progress tracking
  Stream<UploadProgress> upload(
    String url,
    Uint8List fileBytes,
    String fileName, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
    String fieldName = 'file',
  }) async* {
    if (_adapter == null) {
      yield UploadProgress(
        id: 'error',
        fileName: fileName,
        totalBytes: 0,
        uploadedBytes: 0,
        percentage: 0,
        isComplete: false,
        error: 'UnifiedNetworking not initialized',
      );
      return;
    }

    await for (final progress in _adapter!.upload(
      url,
      fileBytes,
      fileName,
      headers: headers,
      fields: fields,
      fieldName: fieldName,
    )) {
      _uploadController.add(progress);
      yield progress;
    }
  }

  /// Download a file with progress tracking
  Stream<DownloadProgress> download(
    String url, {
    Map<String, String>? headers,
    String? savePath,
  }) async* {
    if (_adapter == null) {
      yield DownloadProgress(
        id: 'error',
        url: url,
        totalBytes: 0,
        downloadedBytes: 0,
        percentage: 0,
        isComplete: false,
        error: 'UnifiedNetworking not initialized',
      );
      return;
    }

    await for (final progress in _adapter!.download(
      url,
      headers: headers,
      savePath: savePath,
    )) {
      _downloadController.add(progress);
      yield progress;
    }
  }

  // WebSocket

  /// Connect to a WebSocket
  Future<WebSocketConnection> connectWebSocket(
    String url, {
    Map<String, String>? headers,
    List<String>? protocols,
    Duration? pingInterval,
    bool autoReconnect = true,
  }) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedNetworking not initialized. Call initialize() first.');
    }

    return await _adapter!.connectWebSocket(
      url,
      headers: headers,
      protocols: protocols,
      pingInterval: pingInterval,
      autoReconnect: autoReconnect,
    );
  }

  // GraphQL (if supported by adapter)

  /// Execute a GraphQL query
  Future<GraphQLResponse> graphQL(
    String endpoint,
    String query, {
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
    String? operationName,
  }) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedNetworking not initialized. Call initialize() first.');
    }

    return await _adapter!.graphQL(
      endpoint,
      query,
      variables: variables,
      headers: headers,
      operationName: operationName,
    );
  }

  // gRPC (if supported by adapter)

  /// Make a gRPC call
  Future<GrpcResponse> grpc(
    String endpoint,
    String service,
    String method,
    Map<String, dynamic> request, {
    Map<String, String>? metadata,
    Duration? timeout,
  }) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedNetworking not initialized. Call initialize() first.');
    }

    return await _adapter!.grpc(
      endpoint,
      service,
      method,
      request,
      metadata: metadata,
      timeout: timeout,
    );
  }

  // Offline Queue Management

  /// Get pending offline requests
  List<NetworkRequest> get offlineQueue => List.unmodifiable(_offlineQueue);

  /// Clear offline queue
  void clearOfflineQueue() {
    _offlineQueue.clear();
  }

  /// Process offline queue manually
  Future<void> processOfflineQueue() async {
    await _processOfflineQueue();
  }

  // Request Interceptors

  /// Add request interceptor
  void addRequestInterceptor(RequestInterceptor interceptor) {
    _adapter?.addRequestInterceptor(interceptor);
  }

  /// Add response interceptor
  void addResponseInterceptor(ResponseInterceptor interceptor) {
    _adapter?.addResponseInterceptor(interceptor);
  }

  /// Remove request interceptor
  void removeRequestInterceptor(RequestInterceptor interceptor) {
    _adapter?.removeRequestInterceptor(interceptor);
  }

  /// Remove response interceptor
  void removeResponseInterceptor(ResponseInterceptor interceptor) {
    _adapter?.removeResponseInterceptor(interceptor);
  }

  // Caching

  /// Enable response caching
  void enableCaching({
    Duration defaultTtl = const Duration(minutes: 5),
    int maxCacheSize = 50,
  }) {
    _adapter?.enableCaching(defaultTtl: defaultTtl, maxCacheSize: maxCacheSize);
  }

  /// Disable response caching
  void disableCaching() {
    _adapter?.disableCaching();
  }

  /// Clear response cache
  void clearCache() {
    _adapter?.clearCache();
  }

  // Statistics

  /// Get network statistics
  Future<NetworkStatistics> getStatistics() async {
    if (_adapter == null) {
      return const NetworkStatistics(
        totalRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        totalBytesUploaded: 0,
        totalBytesDownloaded: 0,
        averageResponseTime: Duration.zero,
      );
    }

    return await _adapter!.getStatistics();
  }

  /// Reset network statistics
  void resetStatistics() {
    _adapter?.resetStatistics();
  }

  // Stream Getters

  /// Stream of all network requests
  Stream<NetworkRequest> get onRequest => _requestController.stream;

  /// Stream of upload progress events
  Stream<UploadProgress> get onUploadProgress => _uploadController.stream;

  /// Stream of download progress events
  Stream<DownloadProgress> get onDownloadProgress => _downloadController.stream;

  // Private Methods

  Future<NetworkResponse> _makeRequest(NetworkRequest request) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedNetworking not initialized. Call initialize() first.');
    }

    _requestController.add(request);

    // If offline and request should be queued
    if (!_isOnline && request.queueOffline) {
      _offlineQueue.add(request);
      return NetworkResponse(
        statusCode: 0,
        data: null,
        headers: {},
        request: request,
        isFromCache: false,
        error: 'Request queued for offline processing',
      );
    }

    // Make the request
    try {
      return await _adapter!.request(request);
    } catch (e) {
      // If request failed and should be queued offline
      if (request.queueOffline) {
        _offlineQueue.add(request);
      }
      rethrow;
    }
  }

  Future<void> _processOfflineQueue() async {
    if (_adapter == null || _offlineQueue.isEmpty) return;

    final requestsToProcess = List<NetworkRequest>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final request in requestsToProcess) {
      try {
        await _adapter!.request(request);
      } catch (e) {
        // Re-queue failed requests
        _offlineQueue.add(request);
      }
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivityController.close();
    await _requestController.close();
    await _uploadController.close();
    await _downloadController.close();
    await _adapter?.dispose();
    _offlineQueue.clear();
  }
}

/// Default networking adapter
class DefaultNetworkingAdapter extends NetworkingAdapter {
  @override
  String get name => 'DefaultNetworkingAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => Stream.value(
        const ConnectivityStatus(
          type: ConnectivityType.wifi,
          isConnected: true,
        ),
      );

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return const ConnectivityStatus(
      type: ConnectivityType.wifi,
      isConnected: true,
    );
  }

  @override
  Future<NetworkResponse> request(NetworkRequest request) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));

    return NetworkResponse(
      statusCode: 200,
      data: {'message': 'Mock response', 'method': request.method.name},
      headers: {'content-type': 'application/json'},
      request: request,
      isFromCache: false,
    );
  }

  @override
  Stream<UploadProgress> upload(
    String url,
    Uint8List fileBytes,
    String fileName, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
    String fieldName = 'file',
  }) async* {
    // Mock upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield UploadProgress(
        id: 'mock_upload',
        fileName: fileName,
        totalBytes: fileBytes.length,
        uploadedBytes: (fileBytes.length * i / 100).round(),
        percentage: i.toDouble(),
        isComplete: i == 100,
      );
    }
  }

  @override
  Stream<DownloadProgress> download(
    String url, {
    Map<String, String>? headers,
    String? savePath,
  }) async* {
    // Mock download progress
    const totalBytes = 1024 * 1024; // 1MB
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield DownloadProgress(
        id: 'mock_download',
        url: url,
        totalBytes: totalBytes,
        downloadedBytes: (totalBytes * i / 100).round(),
        percentage: i.toDouble(),
        isComplete: i == 100,
      );
    }
  }

  @override
  Future<WebSocketConnection> connectWebSocket(
    String url, {
    Map<String, String>? headers,
    List<String>? protocols,
    Duration? pingInterval,
    bool autoReconnect = true,
  }) async {
    // Mock WebSocket connection
    return MockWebSocketConnection(url);
  }

  @override
  Future<GraphQLResponse> graphQL(
    String endpoint,
    String query, {
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
    String? operationName,
  }) async {
    return GraphQLResponse(
      data: {'message': 'Mock GraphQL response'},
      errors: null,
      extensions: null,
    );
  }

  @override
  Future<GrpcResponse> grpc(
    String endpoint,
    String service,
    String method,
    Map<String, dynamic> request, {
    Map<String, String>? metadata,
    Duration? timeout,
  }) async {
    return GrpcResponse(
      data: {'message': 'Mock gRPC response'},
      statusCode: 0,
      statusMessage: 'OK',
      metadata: {},
    );
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
    return const NetworkStatistics(
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

/// Mock WebSocket connection for testing
class MockWebSocketConnection extends WebSocketConnection {
  MockWebSocketConnection(String url) : super(url);

  final StreamController<dynamic> _messageController =
      StreamController.broadcast();
  final StreamController<WebSocketEvent> _eventController =
      StreamController.broadcast();

  @override
  Stream<dynamic> get messages => _messageController.stream;

  @override
  Stream<WebSocketEvent> get events => _eventController.stream;

  @override
  bool get isConnected => true;

  @override
  void send(dynamic message) {
    // Mock send - echo back the message
    Timer(const Duration(milliseconds: 100), () {
      _messageController.add('Echo: $message');
    });
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
    await _messageController.close();
    await _eventController.close();
  }
}
