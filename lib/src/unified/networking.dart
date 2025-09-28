import 'dart:async';
import 'package:flutter/foundation.dart';
import '../common/platform_detector.dart';
import '../common/event_emitter.dart';

/// HTTP methods
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options,
}

/// Network connectivity status
enum ConnectivityStatus {
  none,
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  other,
}

/// Request priority for offline queue
enum RequestPriority {
  low,
  normal,
  high,
  critical,
}

/// HTTP response
class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic data;
  final String? error;
  final Duration? duration;

  const HttpResponse({
    required this.statusCode,
    required this.headers,
    this.data,
    this.error,
    this.duration,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  T? getData<T>() {
    if (data is T) return data as T;
    return null;
  }
}

/// HTTP request configuration
class HttpRequestConfig {
  final HttpMethod method;
  final String url;
  final Map<String, String>? headers;
  final dynamic body;
  final Map<String, dynamic>? queryParameters;
  final Duration? timeout;
  final bool followRedirects;
  final int maxRedirects;
  final bool validateCertificate;
  final RequestPriority priority;
  final bool retryOnFailure;
  final int maxRetries;
  final Duration? retryDelay;
  final bool queueIfOffline;

  const HttpRequestConfig({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    this.queryParameters,
    this.timeout,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.validateCertificate = true,
    this.priority = RequestPriority.normal,
    this.retryOnFailure = false,
    this.maxRetries = 3,
    this.retryDelay,
    this.queueIfOffline = false,
  });
}

/// WebSocket message
class WebSocketMessage {
  final dynamic data;
  final bool isBinary;
  final DateTime timestamp;

  WebSocketMessage({
    required this.data,
    this.isBinary = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get asString => data.toString();
  Uint8List? get asBinary => data is Uint8List ? data : null;
}

/// WebSocket configuration
class WebSocketConfig {
  final String url;
  final List<String>? protocols;
  final Map<String, String>? headers;
  final Duration? pingInterval;
  final Duration? timeout;
  final bool autoReconnect;
  final Duration? reconnectDelay;
  final int maxReconnectAttempts;

  const WebSocketConfig({
    required this.url,
    this.protocols,
    this.headers,
    this.pingInterval,
    this.timeout,
    this.autoReconnect = true,
    this.reconnectDelay,
    this.maxReconnectAttempts = 5,
  });
}

/// WebSocket connection state
enum WebSocketState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  error,
}

/// Download progress
class DownloadProgress {
  final int downloaded;
  final int? total;
  final double? percentage;
  final Duration? timeRemaining;

  const DownloadProgress({
    required this.downloaded,
    this.total,
    this.percentage,
    this.timeRemaining,
  });
}

/// Upload progress
class UploadProgress {
  final int uploaded;
  final int? total;
  final double? percentage;
  final Duration? timeRemaining;

  const UploadProgress({
    required this.uploaded,
    this.total,
    this.percentage,
    this.timeRemaining,
  });
}

/// File download/upload result
class FileTransferResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int? size;
  final Duration? duration;

  const FileTransferResult({
    required this.success,
    this.filePath,
    this.error,
    this.size,
    this.duration,
  });
}

/// gRPC call configuration
class GrpcConfig {
  final String host;
  final int port;
  final bool useSSL;
  final Map<String, String>? metadata;
  final Duration? timeout;
  final String? authority;

  const GrpcConfig({
    required this.host,
    required this.port,
    this.useSSL = true,
    this.metadata,
    this.timeout,
    this.authority,
  });
}

/// Network interceptor
abstract class NetworkInterceptor {
  Future<HttpRequestConfig> onRequest(HttpRequestConfig config);
  Future<HttpResponse> onResponse(HttpResponse response);
  Future<HttpResponse> onError(HttpResponse response);
}

/// Offline request queue item
class QueuedRequest {
  final String id;
  final HttpRequestConfig config;
  final DateTime queuedAt;
  final RequestPriority priority;
  final int attempts;

  const QueuedRequest({
    required this.id,
    required this.config,
    required this.queuedAt,
    this.priority = RequestPriority.normal,
    this.attempts = 0,
  });
}

/// Unified networking and connectivity API
class UnifiedNetworking extends EventEmitter {
  static UnifiedNetworking? _instance;
  static UnifiedNetworking get instance => _instance ??= UnifiedNetworking._();

  UnifiedNetworking._();

  bool _isInitialized = false;
  ConnectivityStatus _currentStatus = ConnectivityStatus.none;
  final List<NetworkInterceptor> _interceptors = [];
  final Map<String, StreamController> _webSocketStreams = {};
  final List<QueuedRequest> _offlineQueue = [];
  late StreamController<ConnectivityStatus> _connectivityController;

  /// Current connectivity status
  ConnectivityStatus get connectivityStatus => _currentStatus;

  /// Check if device is online
  bool get isOnline => _currentStatus != ConnectivityStatus.none;

  /// Stream of connectivity changes
  Stream<ConnectivityStatus> get connectivityStream =>
      _connectivityController.stream;

  /// Initialize networking system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _connectivityController =
          StreamController<ConnectivityStatus>.broadcast();

      if (kIsWeb) {
        await _initializeWeb();
      } else if (PlatformDetector.isDesktop) {
        await _initializeDesktop();
      } else if (PlatformDetector.isMobile) {
        await _initializeMobile();
      }

      // Start connectivity monitoring
      _startConnectivityMonitoring();

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNetworking: Failed to initialize: $e');
      }
      return false;
    }
  }

  /// Make HTTP request
  Future<HttpResponse> request(HttpRequestConfig config) async {
    try {
      // Apply interceptors
      HttpRequestConfig processedConfig = config;
      for (final interceptor in _interceptors) {
        processedConfig = await interceptor.onRequest(processedConfig);
      }

      // Check if should queue offline
      if (!isOnline && processedConfig.queueIfOffline) {
        await _queueRequest(processedConfig);
        return const HttpResponse(
          statusCode: 0,
          headers: {},
          error: 'Request queued for when online',
        );
      }

      HttpResponse response;
      if (kIsWeb) {
        response = await _requestWeb(processedConfig);
      } else if (PlatformDetector.isDesktop) {
        response = await _requestDesktop(processedConfig);
      } else if (PlatformDetector.isMobile) {
        response = await _requestMobile(processedConfig);
      } else {
        response = const HttpResponse(
          statusCode: 500,
          headers: {},
          error: 'Platform not supported',
        );
      }

      // Apply response interceptors
      for (final interceptor in _interceptors) {
        if (response.isSuccess) {
          response = await interceptor.onResponse(response);
        } else {
          response = await interceptor.onError(response);
        }
      }

      return response;
    } catch (e) {
      return HttpResponse(
        statusCode: 500,
        headers: {},
        error: e.toString(),
      );
    }
  }

  /// GET request
  Future<HttpResponse> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) {
    return request(HttpRequestConfig(
      method: HttpMethod.get,
      url: url,
      headers: headers,
      queryParameters: queryParameters,
      timeout: timeout,
    ));
  }

  /// POST request
  Future<HttpResponse> post(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(HttpRequestConfig(
      method: HttpMethod.post,
      url: url,
      body: body,
      headers: headers,
      timeout: timeout,
    ));
  }

  /// PUT request
  Future<HttpResponse> put(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(HttpRequestConfig(
      method: HttpMethod.put,
      url: url,
      body: body,
      headers: headers,
      timeout: timeout,
    ));
  }

  /// DELETE request
  Future<HttpResponse> delete(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    return request(HttpRequestConfig(
      method: HttpMethod.delete,
      url: url,
      headers: headers,
      timeout: timeout,
    ));
  }

  /// Download file with progress
  Future<FileTransferResult> downloadFile(
    String url,
    String savePath, {
    Map<String, String>? headers,
    Function(DownloadProgress)? onProgress,
  }) async {
    try {
      if (kIsWeb) {
        return await _downloadFileWeb(url, savePath, headers, onProgress);
      } else if (PlatformDetector.isDesktop) {
        return await _downloadFileDesktop(url, savePath, headers, onProgress);
      } else if (PlatformDetector.isMobile) {
        return await _downloadFileMobile(url, savePath, headers, onProgress);
      }

      return const FileTransferResult(
        success: false,
        error: 'Platform not supported',
      );
    } catch (e) {
      return FileTransferResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload file with progress
  Future<HttpResponse> uploadFile(
    String url,
    String filePath, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    String fieldName = 'file',
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      if (kIsWeb) {
        return await _uploadFileWeb(
            url, filePath, headers, fields, fieldName, onProgress);
      } else if (PlatformDetector.isDesktop) {
        return await _uploadFileDesktop(
            url, filePath, headers, fields, fieldName, onProgress);
      } else if (PlatformDetector.isMobile) {
        return await _uploadFileMobile(
            url, filePath, headers, fields, fieldName, onProgress);
      }

      return const HttpResponse(
        statusCode: 500,
        headers: {},
        error: 'Platform not supported',
      );
    } catch (e) {
      return HttpResponse(
        statusCode: 500,
        headers: {},
        error: e.toString(),
      );
    }
  }

  /// Connect to WebSocket
  Stream<WebSocketMessage>? connectWebSocket(WebSocketConfig config) {
    try {
      final streamId = config.url;

      if (_webSocketStreams.containsKey(streamId)) {
        return _webSocketStreams[streamId]!.stream.cast<WebSocketMessage>();
      }

      final controller = StreamController<WebSocketMessage>.broadcast();
      _webSocketStreams[streamId] = controller;

      // Start platform-specific WebSocket connection
      _connectWebSocketPlatform(config, controller);

      return controller.stream;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNetworking: Failed to connect WebSocket: $e');
      }
      return null;
    }
  }

  /// Send WebSocket message
  Future<bool> sendWebSocketMessage(String url, dynamic message) async {
    try {
      if (kIsWeb) {
        return await _sendWebSocketMessageWeb(url, message);
      } else if (PlatformDetector.isDesktop) {
        return await _sendWebSocketMessageDesktop(url, message);
      } else if (PlatformDetector.isMobile) {
        return await _sendWebSocketMessageMobile(url, message);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNetworking: Failed to send WebSocket message: $e');
      }
      return false;
    }
  }

  /// Close WebSocket connection
  Future<void> closeWebSocket(String url) async {
    if (_webSocketStreams.containsKey(url)) {
      await _webSocketStreams[url]!.close();
      _webSocketStreams.remove(url);
    }
  }

  /// Make gRPC call
  Future<HttpResponse> grpcCall(
    GrpcConfig config,
    String service,
    String method,
    dynamic request,
  ) async {
    try {
      if (kIsWeb) {
        return await _grpcCallWeb(config, service, method, request);
      } else if (PlatformDetector.isDesktop) {
        return await _grpcCallDesktop(config, service, method, request);
      } else if (PlatformDetector.isMobile) {
        return await _grpcCallMobile(config, service, method, request);
      }

      return const HttpResponse(
        statusCode: 500,
        headers: {},
        error: 'Platform not supported',
      );
    } catch (e) {
      return HttpResponse(
        statusCode: 500,
        headers: {},
        error: e.toString(),
      );
    }
  }

  /// Add network interceptor
  void addInterceptor(NetworkInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Remove network interceptor
  void removeInterceptor(NetworkInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  /// Clear all interceptors
  void clearInterceptors() {
    _interceptors.clear();
  }

  /// Get offline queue
  List<QueuedRequest> get offlineQueue => List.unmodifiable(_offlineQueue);

  /// Clear offline queue
  void clearOfflineQueue() {
    _offlineQueue.clear();
  }

  /// Process offline queue when back online
  Future<void> processOfflineQueue() async {
    if (!isOnline || _offlineQueue.isEmpty) return;

    final queue = List<QueuedRequest>.from(_offlineQueue);
    _offlineQueue.clear();

    // Sort by priority and queue time
    queue.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return a.queuedAt.compareTo(b.queuedAt);
    });

    for (final queuedRequest in queue) {
      try {
        await request(queuedRequest.config);
      } catch (e) {
        if (kDebugMode) {
          print('UnifiedNetworking: Failed to process queued request: $e');
        }
      }
    }
  }

  // Internal methods
  Future<void> _queueRequest(HttpRequestConfig config) async {
    final queuedRequest = QueuedRequest(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      config: config,
      queuedAt: DateTime.now(),
      priority: config.priority,
    );

    _offlineQueue.add(queuedRequest);

    // Limit queue size
    if (_offlineQueue.length > 1000) {
      _offlineQueue.removeAt(0);
    }
  }

  void _startConnectivityMonitoring() {
    // Platform-specific connectivity monitoring
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    ConnectivityStatus newStatus;

    if (kIsWeb) {
      newStatus = await _checkConnectivityWeb();
    } else if (PlatformDetector.isDesktop) {
      newStatus = await _checkConnectivityDesktop();
    } else if (PlatformDetector.isMobile) {
      newStatus = await _checkConnectivityMobile();
    } else {
      newStatus = ConnectivityStatus.none;
    }

    if (newStatus != _currentStatus) {
      final wasOffline = !isOnline;
      _currentStatus = newStatus;
      _connectivityController.add(newStatus);

      emit('connectivity-changed', {
        'status': newStatus.name,
        'isOnline': isOnline,
      });

      // Process offline queue if back online
      if (wasOffline && isOnline) {
        await processOfflineQueue();
      }
    }
  }

  // Platform-specific initialization
  Future<void> _initializeWeb() async {
    // Initialize web networking
  }

  Future<void> _initializeDesktop() async {
    // Initialize desktop networking
  }

  Future<void> _initializeMobile() async {
    // Initialize mobile networking
  }

  // Platform-specific implementations (stubs)
  Future<HttpResponse> _requestWeb(HttpRequestConfig config) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<HttpResponse> _requestDesktop(HttpRequestConfig config) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<HttpResponse> _requestMobile(HttpRequestConfig config) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<FileTransferResult> _downloadFileWeb(
      String url,
      String savePath,
      Map<String, String>? headers,
      Function(DownloadProgress)? onProgress) async {
    return const FileTransferResult(success: false, error: 'Not implemented');
  }

  Future<FileTransferResult> _downloadFileDesktop(
      String url,
      String savePath,
      Map<String, String>? headers,
      Function(DownloadProgress)? onProgress) async {
    return const FileTransferResult(success: false, error: 'Not implemented');
  }

  Future<FileTransferResult> _downloadFileMobile(
      String url,
      String savePath,
      Map<String, String>? headers,
      Function(DownloadProgress)? onProgress) async {
    return const FileTransferResult(success: false, error: 'Not implemented');
  }

  Future<HttpResponse> _uploadFileWeb(
      String url,
      String filePath,
      Map<String, String>? headers,
      Map<String, String>? fields,
      String fieldName,
      Function(UploadProgress)? onProgress) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<HttpResponse> _uploadFileDesktop(
      String url,
      String filePath,
      Map<String, String>? headers,
      Map<String, String>? fields,
      String fieldName,
      Function(UploadProgress)? onProgress) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<HttpResponse> _uploadFileMobile(
      String url,
      String filePath,
      Map<String, String>? headers,
      Map<String, String>? fields,
      String fieldName,
      Function(UploadProgress)? onProgress) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  void _connectWebSocketPlatform(
      WebSocketConfig config, StreamController<WebSocketMessage> controller) {
    // Platform-specific WebSocket implementation
  }

  Future<bool> _sendWebSocketMessageWeb(String url, dynamic message) async {
    return false;
  }

  Future<bool> _sendWebSocketMessageDesktop(String url, dynamic message) async {
    return false;
  }

  Future<bool> _sendWebSocketMessageMobile(String url, dynamic message) async {
    return false;
  }

  Future<HttpResponse> _grpcCallWeb(
      GrpcConfig config, String service, String method, dynamic request) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<HttpResponse> _grpcCallDesktop(
      GrpcConfig config, String service, String method, dynamic request) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<HttpResponse> _grpcCallMobile(
      GrpcConfig config, String service, String method, dynamic request) async {
    return const HttpResponse(
        statusCode: 500, headers: {}, error: 'Not implemented');
  }

  Future<ConnectivityStatus> _checkConnectivityWeb() async {
    return ConnectivityStatus.wifi; // Assume wifi for web
  }

  Future<ConnectivityStatus> _checkConnectivityDesktop() async {
    return ConnectivityStatus.ethernet; // Assume ethernet for desktop
  }

  Future<ConnectivityStatus> _checkConnectivityMobile() async {
    return ConnectivityStatus.mobile; // Assume mobile for mobile
  }

  /// Dispose resources
  Future<void> dispose() async {
    for (final controller in _webSocketStreams.values) {
      await controller.close();
    }
    _webSocketStreams.clear();
    _offlineQueue.clear();
    _interceptors.clear();
    await _connectivityController.close();
    _isInitialized = false;
  }
}
