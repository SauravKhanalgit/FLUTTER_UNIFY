/// Networking-related models for unified networking system
///
/// This file contains all the data models used by the unified networking system
/// including requests, responses, connectivity status, and progress tracking.

import 'dart:typed_data';

/// HTTP methods
enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
}

/// Connectivity types
enum ConnectivityType {
  /// No connection
  none,

  /// WiFi connection
  wifi,

  /// Mobile/cellular connection
  mobile,

  /// Ethernet connection (desktop)
  ethernet,

  /// Bluetooth connection
  bluetooth,

  /// VPN connection
  vpn,

  /// Unknown connection type
  unknown,
}

/// Connectivity status information
class ConnectivityStatus {
  /// Type of connection
  final ConnectivityType type;

  /// Whether device is connected to internet
  final bool isConnected;

  /// Connection strength (0-100, null if not available)
  final int? strength;

  /// Connection speed in Mbps (null if not available)
  final double? speed;

  /// Whether connection is metered (mobile data, limited WiFi)
  final bool isMetered;

  /// Additional connection details
  final Map<String, dynamic>? details;

  /// Timestamp when status was determined
  final DateTime timestamp;

  ConnectivityStatus({
    required this.type,
    required this.isConnected,
    this.strength,
    this.speed,
    this.isMetered = false,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Whether connection is mobile/cellular
  bool get isMobile => type == ConnectivityType.mobile;

  /// Whether connection is WiFi
  bool get isWiFi => type == ConnectivityType.wifi;

  /// Whether connection is wired (ethernet)
  bool get isWired => type == ConnectivityType.ethernet;

  /// Connection type as string
  String get typeString {
    switch (type) {
      case ConnectivityType.none:
        return 'No Connection';
      case ConnectivityType.wifi:
        return 'WiFi';
      case ConnectivityType.mobile:
        return 'Mobile';
      case ConnectivityType.ethernet:
        return 'Ethernet';
      case ConnectivityType.bluetooth:
        return 'Bluetooth';
      case ConnectivityType.vpn:
        return 'VPN';
      case ConnectivityType.unknown:
        return 'Unknown';
    }
  }

  @override
  String toString() =>
      'ConnectivityStatus(type: $typeString, connected: $isConnected)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityStatus &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          isConnected == other.isConnected;

  @override
  int get hashCode => type.hashCode ^ isConnected.hashCode;
}

/// Network request configuration
class NetworkRequest {
  /// HTTP method
  final HttpMethod method;

  /// Request URL
  final String url;

  /// Request data (body)
  final dynamic data;

  /// Request headers
  final Map<String, String>? headers;

  /// Query parameters
  final Map<String, dynamic>? queryParameters;

  /// Request timeout
  final Duration? timeout;

  /// Whether to retry on failure
  final bool retryOnFailure;

  /// Maximum number of retries
  final int maxRetries;

  /// Whether to queue request if offline
  final bool queueOffline;

  /// Request priority (higher number = higher priority)
  final int priority;

  /// Whether response should be cached
  final bool cacheResponse;

  /// Cache TTL (time-to-live)
  final Duration? cacheTtl;

  /// Unique request ID
  final String id;

  /// Request timestamp
  final DateTime timestamp;

  NetworkRequest({
    required this.method,
    required this.url,
    this.data,
    this.headers,
    this.queryParameters,
    this.timeout,
    this.retryOnFailure = false,
    this.maxRetries = 3,
    this.queueOffline = false,
    this.priority = 0,
    this.cacheResponse = false,
    this.cacheTtl,
    String? id,
    DateTime? timestamp,
  })  : id = id ?? 'req_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  /// Create a copy with modified parameters
  NetworkRequest copyWith({
    HttpMethod? method,
    String? url,
    dynamic data,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    bool? retryOnFailure,
    int? maxRetries,
    bool? queueOffline,
    int? priority,
    bool? cacheResponse,
    Duration? cacheTtl,
  }) {
    return NetworkRequest(
      method: method ?? this.method,
      url: url ?? this.url,
      data: data ?? this.data,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      timeout: timeout ?? this.timeout,
      retryOnFailure: retryOnFailure ?? this.retryOnFailure,
      maxRetries: maxRetries ?? this.maxRetries,
      queueOffline: queueOffline ?? this.queueOffline,
      priority: priority ?? this.priority,
      cacheResponse: cacheResponse ?? this.cacheResponse,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      id: id,
      timestamp: timestamp,
    );
  }

  @override
  String toString() => 'NetworkRequest(${method.name.toUpperCase()} $url)';
}

/// Network response
class NetworkResponse {
  /// HTTP status code
  final int statusCode;

  /// Response data
  final dynamic data;

  /// Response headers
  final Map<String, String> headers;

  /// Original request
  final NetworkRequest request;

  /// Whether response came from cache
  final bool isFromCache;

  /// Response timestamp
  final DateTime timestamp;

  /// Response size in bytes
  final int? size;

  /// Response time (how long request took)
  final Duration? responseTime;

  /// Error message (if request failed)
  final String? error;

  NetworkResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
    required this.request,
    this.isFromCache = false,
    DateTime? timestamp,
    this.size,
    this.responseTime,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Whether request was successful (2xx status code)
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Whether request had client error (4xx status code)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Whether request had server error (5xx status code)
  bool get isServerError => statusCode >= 500;

  /// Whether request failed
  bool get isError => error != null || !isSuccess;

  /// Content type from headers
  String? get contentType => headers['content-type'];

  /// Whether response is JSON
  bool get isJson => contentType?.contains('application/json') ?? false;

  /// Whether response is XML
  bool get isXml => contentType?.contains('xml') ?? false;

  /// Whether response is HTML
  bool get isHtml => contentType?.contains('text/html') ?? false;

  /// Get response data as JSON
  Map<String, dynamic>? get asJson {
    if (data is Map<String, dynamic>) {
      return data as Map<String, dynamic>;
    }
    return null;
  }

  /// Get response data as string
  String? get asString {
    if (data is String) {
      return data as String;
    }
    return data?.toString();
  }

  /// Get response data as bytes
  Uint8List? get asBytes {
    if (data is Uint8List) {
      return data as Uint8List;
    }
    return null;
  }

  @override
  String toString() => 'NetworkResponse($statusCode, ${data?.runtimeType})';
}

/// Upload progress information
class UploadProgress {
  /// Unique upload identifier
  final String id;

  /// Name of file being uploaded
  final String fileName;

  /// Total bytes to upload
  final int totalBytes;

  /// Bytes uploaded so far
  final int uploadedBytes;

  /// Upload percentage (0-100)
  final double percentage;

  /// Whether upload is complete
  final bool isComplete;

  /// Upload error (if any)
  final String? error;

  /// Upload speed in bytes/second (if available)
  final double? speed;

  /// Estimated time remaining in seconds (if available)
  final int? remainingTime;

  /// Upload start time
  final DateTime startTime;

  /// Current timestamp
  final DateTime timestamp;

  UploadProgress({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.percentage,
    required this.isComplete,
    this.error,
    this.speed,
    this.remainingTime,
    DateTime? startTime,
    DateTime? timestamp,
  })  : startTime = startTime ?? DateTime.now(),
        timestamp = timestamp ?? DateTime.now();

  /// Whether upload failed
  bool get hasError => error != null;

  /// Whether upload is in progress
  bool get isInProgress => !isComplete && !hasError;

  /// Time elapsed since upload started
  Duration get elapsedTime => timestamp.difference(startTime);

  /// Get human-readable speed
  String get speedString {
    if (speed == null) return 'Unknown';
    if (speed! < 1024) return '${speed!.toStringAsFixed(0)} B/s';
    if (speed! < 1024 * 1024)
      return '${(speed! / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed! / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  /// Get human-readable remaining time
  String get remainingTimeString {
    if (remainingTime == null) return 'Unknown';
    if (remainingTime! < 60) return '${remainingTime}s';
    if (remainingTime! < 3600) return '${(remainingTime! / 60).round()}m';
    return '${(remainingTime! / 3600).round()}h';
  }

  @override
  String toString() =>
      'UploadProgress($fileName: ${percentage.toStringAsFixed(1)}%)';
}

/// Download progress information
class DownloadProgress {
  /// Unique download identifier
  final String id;

  /// URL being downloaded
  final String url;

  /// Local save path (if applicable)
  final String? savePath;

  /// Total bytes to download
  final int totalBytes;

  /// Bytes downloaded so far
  final int downloadedBytes;

  /// Download percentage (0-100)
  final double percentage;

  /// Whether download is complete
  final bool isComplete;

  /// Downloaded data (if loading into memory)
  final Uint8List? data;

  /// Download error (if any)
  final String? error;

  /// Download speed in bytes/second (if available)
  final double? speed;

  /// Estimated time remaining in seconds (if available)
  final int? remainingTime;

  /// Download start time
  final DateTime startTime;

  /// Current timestamp
  final DateTime timestamp;

  DownloadProgress({
    required this.id,
    required this.url,
    this.savePath,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.percentage,
    required this.isComplete,
    this.data,
    this.error,
    this.speed,
    this.remainingTime,
    DateTime? startTime,
    DateTime? timestamp,
  })  : startTime = startTime ?? DateTime.now(),
        timestamp = timestamp ?? DateTime.now();

  /// Whether download failed
  bool get hasError => error != null;

  /// Whether download is in progress
  bool get isInProgress => !isComplete && !hasError;

  /// Time elapsed since download started
  Duration get elapsedTime => timestamp.difference(startTime);

  /// Get human-readable speed
  String get speedString {
    if (speed == null) return 'Unknown';
    if (speed! < 1024) return '${speed!.toStringAsFixed(0)} B/s';
    if (speed! < 1024 * 1024)
      return '${(speed! / 1024).toStringAsFixed(1)} KB/s';
    return '${(speed! / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  /// Get human-readable remaining time
  String get remainingTimeString {
    if (remainingTime == null) return 'Unknown';
    if (remainingTime! < 60) return '${remainingTime}s';
    if (remainingTime! < 3600) return '${(remainingTime! / 60).round()}m';
    return '${(remainingTime! / 3600).round()}h';
  }

  @override
  String toString() => 'DownloadProgress(${percentage.toStringAsFixed(1)}%)';
}

/// WebSocket connection state
enum WebSocketState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  error,
}

/// WebSocket event types
enum WebSocketEventType {
  connecting,
  connected,
  message,
  error,
  disconnected,
  reconnecting,
}

/// WebSocket event
class WebSocketEvent {
  /// Event type
  final WebSocketEventType type;

  /// Event data (if any)
  final dynamic data;

  /// Error message (for error events)
  final String? error;

  /// Event timestamp
  final DateTime timestamp;

  WebSocketEvent({
    required this.type,
    this.data,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'WebSocketEvent($type)';
}

/// WebSocket connection abstract class
abstract class WebSocketConnection {
  /// WebSocket URL
  final String url;

  /// Connection headers
  final Map<String, String>? headers;

  /// Supported protocols
  final List<String>? protocols;

  WebSocketConnection(
    this.url, {
    this.headers,
    this.protocols,
  });

  /// Stream of incoming messages
  Stream<dynamic> get messages;

  /// Stream of connection events
  Stream<WebSocketEvent> get events;

  /// Current connection state
  bool get isConnected;

  /// Send a message
  void send(dynamic message);

  /// Send text message
  void sendText(String message);

  /// Send binary message
  void sendBytes(Uint8List bytes);

  /// Close the connection
  Future<void> close([int? code, String? reason]);
}

/// GraphQL response
class GraphQLResponse {
  /// Response data
  final Map<String, dynamic>? data;

  /// GraphQL errors
  final List<Map<String, dynamic>>? errors;

  /// Response extensions
  final Map<String, dynamic>? extensions;

  const GraphQLResponse({
    this.data,
    this.errors,
    this.extensions,
  });

  /// Whether response has errors
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Whether response is successful
  bool get isSuccess => !hasErrors && data != null;

  @override
  String toString() => 'GraphQLResponse(hasErrors: $hasErrors)';
}

/// gRPC response
class GrpcResponse {
  /// Response data
  final Map<String, dynamic> data;

  /// Status code
  final int statusCode;

  /// Status message
  final String statusMessage;

  /// Response metadata
  final Map<String, String> metadata;

  const GrpcResponse({
    required this.data,
    required this.statusCode,
    required this.statusMessage,
    required this.metadata,
  });

  /// Whether response is successful
  bool get isSuccess => statusCode == 0;

  @override
  String toString() => 'GrpcResponse($statusCode: $statusMessage)';
}

/// Network statistics
class NetworkStatistics {
  /// Total number of requests made
  final int totalRequests;

  /// Number of successful requests
  final int successfulRequests;

  /// Number of failed requests
  final int failedRequests;

  /// Total bytes uploaded
  final int totalBytesUploaded;

  /// Total bytes downloaded
  final int totalBytesDownloaded;

  /// Average response time
  final Duration averageResponseTime;

  /// Statistics collection start time
  final DateTime startTime;

  /// Last update time
  final DateTime lastUpdate;

  NetworkStatistics({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.totalBytesUploaded,
    required this.totalBytesDownloaded,
    required this.averageResponseTime,
    DateTime? startTime,
    DateTime? lastUpdate,
  })  : startTime = startTime ?? DateTime.now(),
        lastUpdate = lastUpdate ?? DateTime.now();

  /// Success rate as percentage
  double get successRate =>
      totalRequests > 0 ? (successfulRequests / totalRequests) * 100 : 0;

  /// Failure rate as percentage
  double get failureRate =>
      totalRequests > 0 ? (failedRequests / totalRequests) * 100 : 0;

  /// Total data transferred in bytes
  int get totalBytesTransferred => totalBytesUploaded + totalBytesDownloaded;

  /// Get human-readable data sizes
  String get uploadedDataString => _formatBytes(totalBytesUploaded);
  String get downloadedDataString => _formatBytes(totalBytesDownloaded);
  String get totalDataString => _formatBytes(totalBytesTransferred);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() =>
      'NetworkStatistics($totalRequests requests, ${successRate.toStringAsFixed(1)}% success)';
}

/// Request interceptor function type
typedef RequestInterceptor = Future<NetworkRequest> Function(
    NetworkRequest request);

/// Response interceptor function type
typedef ResponseInterceptor = Future<NetworkResponse> Function(
    NetworkResponse response);
