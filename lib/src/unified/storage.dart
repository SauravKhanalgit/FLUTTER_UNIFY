import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../common/platform_detector.dart';
import '../common/event_emitter.dart';

/// Storage security levels
enum StorageLevel {
  /// Standard storage (SharedPreferences, localStorage, etc.)
  standard,

  /// Secure storage (encrypted at rest)
  secure,

  /// Temporary storage (cache, temp files)
  temporary,
}

/// Storage configuration
class StorageConfig {
  final StorageLevel level;
  final String? namespace;
  final bool encrypted;
  final Duration? ttl;
  final int? maxSize;

  const StorageConfig({
    this.level = StorageLevel.standard,
    this.namespace,
    this.encrypted = false,
    this.ttl,
    this.maxSize,
  });
}

/// Storage entry with metadata
class StorageEntry<T> {
  final String key;
  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int size;
  final Map<String, dynamic>? metadata;

  const StorageEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    this.expiresAt,
    required this.size,
    this.metadata,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Unified storage API across all platforms
class UnifiedStorage extends EventEmitter {
  static UnifiedStorage? _instance;
  static UnifiedStorage get instance => _instance ??= UnifiedStorage._();

  bool _isInitialized = false;
  final Map<String, dynamic> _memoryCache = {};
  final StorageConfig _config;

  UnifiedStorage._() : _config = const StorageConfig();

  UnifiedStorage._withConfig(this._config);

  /// Create storage instance with configuration
  factory UnifiedStorage.withConfig(StorageConfig config) {
    return UnifiedStorage._withConfig(config);
  }

  /// Get current configuration
  StorageConfig get config => _config;

  /// Initialize storage system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (kIsWeb) {
        await _initializeWeb();
      } else if (PlatformDetector.isDesktop) {
        await _initializeDesktop();
      } else if (PlatformDetector.isMobile) {
        await _initializeMobile();
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedStorage: Failed to initialize: $e');
      }
      return false;
    }
  }

  /// Check if storage is available
  bool get isAvailable => _isInitialized;

  /// Get storage capacity info
  Future<StorageInfo> getStorageInfo() async {
    if (kIsWeb) {
      return await _getWebStorageInfo();
    } else if (PlatformDetector.isDesktop) {
      return await _getDesktopStorageInfo();
    } else if (PlatformDetector.isMobile) {
      return await _getMobileStorageInfo();
    }

    return const StorageInfo(available: 0, used: 0, total: 0);
  }

  // String operations
  Future<bool> setString(String key, String value, {Duration? ttl}) async {
    return await _setValue(key, value, ttl: ttl);
  }

  Future<String?> getString(String key) async {
    final value = await _getValue(key);
    return value is String ? value : null;
  }

  // Integer operations
  Future<bool> setInt(String key, int value, {Duration? ttl}) async {
    return await _setValue(key, value, ttl: ttl);
  }

  Future<int?> getInt(String key) async {
    final value = await _getValue(key);
    return value is int ? value : null;
  }

  // Double operations
  Future<bool> setDouble(String key, double value, {Duration? ttl}) async {
    return await _setValue(key, value, ttl: ttl);
  }

  Future<double?> getDouble(String key) async {
    final value = await _getValue(key);
    return value is double ? value : null;
  }

  // Boolean operations
  Future<bool> setBool(String key, bool value, {Duration? ttl}) async {
    return await _setValue(key, value, ttl: ttl);
  }

  Future<bool?> getBool(String key) async {
    final value = await _getValue(key);
    return value is bool ? value : null;
  }

  // JSON operations
  Future<bool> setJson(String key, Map<String, dynamic> value,
      {Duration? ttl}) async {
    return await _setValue(key, jsonEncode(value), ttl: ttl);
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = await _getValue(key);
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // List operations
  Future<bool> setStringList(String key, List<String> value,
      {Duration? ttl}) async {
    return await _setValue(key, jsonEncode(value), ttl: ttl);
  }

  Future<List<String>?> getStringList(String key) async {
    final value = await _getValue(key);
    if (value is String) {
      try {
        final decoded = jsonDecode(value) as List;
        return decoded.cast<String>();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Binary data operations
  Future<bool> setBytes(String key, Uint8List value, {Duration? ttl}) async {
    final encoded = base64Encode(value);
    return await _setValue(key, encoded, ttl: ttl);
  }

  Future<Uint8List?> getBytes(String key) async {
    final value = await _getValue(key);
    if (value is String) {
      try {
        return base64Decode(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // File operations
  Future<bool> setFile(String key, Uint8List data, {Duration? ttl}) async {
    if (kIsWeb) {
      return await _setWebFile(key, data, ttl: ttl);
    } else {
      return await _setNativeFile(key, data, ttl: ttl);
    }
  }

  Future<Uint8List?> getFile(String key) async {
    if (kIsWeb) {
      return await _getWebFile(key);
    } else {
      return await _getNativeFile(key);
    }
  }

  // Key management
  Future<List<String>> getKeys() async {
    if (kIsWeb) {
      return await _getWebKeys();
    } else if (PlatformDetector.isDesktop) {
      return await _getDesktopKeys();
    } else if (PlatformDetector.isMobile) {
      return await _getMobileKeys();
    }
    return [];
  }

  Future<bool> containsKey(String key) async {
    final keys = await getKeys();
    return keys.contains(key);
  }

  Future<bool> remove(String key) async {
    try {
      _memoryCache.remove(key);

      if (kIsWeb) {
        return await _removeWebValue(key);
      } else if (PlatformDetector.isDesktop) {
        return await _removeDesktopValue(key);
      } else if (PlatformDetector.isMobile) {
        return await _removeMobileValue(key);
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedStorage: Remove failed: $e');
      }
    }
    return false;
  }

  Future<bool> clear() async {
    try {
      _memoryCache.clear();

      if (kIsWeb) {
        return await _clearWebStorage();
      } else if (PlatformDetector.isDesktop) {
        return await _clearDesktopStorage();
      } else if (PlatformDetector.isMobile) {
        return await _clearMobileStorage();
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedStorage: Clear failed: $e');
      }
    }
    return false;
  }

  // Advanced operations
  Future<StorageEntry<T>?> getEntry<T>(String key) async {
    final value = await _getValue(key);
    if (value != null) {
      return StorageEntry<T>(
        key: key,
        value: value as T,
        createdAt: DateTime.now(), // Would be stored with actual creation time
        size: _calculateSize(value),
      );
    }
    return null;
  }

  Future<Map<String, dynamic>> getAll() async {
    final keys = await getKeys();
    final result = <String, dynamic>{};

    for (final key in keys) {
      final value = await _getValue(key);
      if (value != null) {
        result[key] = value;
      }
    }

    return result;
  }

  Future<bool> setAll(Map<String, dynamic> data, {Duration? ttl}) async {
    bool success = true;
    for (final entry in data.entries) {
      final result = await _setValue(entry.key, entry.value, ttl: ttl);
      if (!result) success = false;
    }
    return success;
  }

  // Secure storage operations
  Future<bool> setSecure(String key, String value, {Duration? ttl}) async {
    return await _setSecureValue(key, value, ttl: ttl);
  }

  Future<String?> getSecure(String key) async {
    return await _getSecureValue(key);
  }

  Future<bool> removeSecure(String key) async {
    return await _removeSecureValue(key);
  }

  // Internal implementations
  Future<dynamic> _getValue(String key) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // Platform-specific retrieval
    if (kIsWeb) {
      return await _getWebValue(key);
    } else if (PlatformDetector.isDesktop) {
      return await _getDesktopValue(key);
    } else if (PlatformDetector.isMobile) {
      return await _getMobileValue(key);
    }

    return null;
  }

  Future<bool> _setValue(String key, dynamic value, {Duration? ttl}) async {
    try {
      // Store in memory cache
      _memoryCache[key] = value;

      // Platform-specific storage
      bool success;
      if (kIsWeb) {
        success = await _setWebValue(key, value, ttl: ttl);
      } else if (PlatformDetector.isDesktop) {
        success = await _setDesktopValue(key, value, ttl: ttl);
      } else if (PlatformDetector.isMobile) {
        success = await _setMobileValue(key, value, ttl: ttl);
      } else {
        success = false;
      }

      if (success) {
        emit('storage-set', {'key': key, 'value': value});
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedStorage: Set value failed: $e');
      }
      return false;
    }
  }

  int _calculateSize(dynamic value) {
    if (value is String) {
      return value.length * 2; // UTF-16 encoding
    } else if (value is List) {
      return value.length * 8; // Estimate
    } else {
      return 8; // Default for primitives
    }
  }

  // Platform-specific initialization
  Future<void> _initializeWeb() async {
    // Initialize web storage (localStorage, IndexedDB, etc.)
  }

  Future<void> _initializeDesktop() async {
    // Initialize desktop storage (config files, registry, etc.)
  }

  Future<void> _initializeMobile() async {
    // Initialize mobile storage (SharedPreferences, Keychain, etc.)
  }

  // Web storage implementations
  Future<StorageInfo> _getWebStorageInfo() async {
    // Get web storage quota info
    return const StorageInfo(available: 5000000, used: 0, total: 5000000);
  }

  Future<dynamic> _getWebValue(String key) async {
    // Implement web storage retrieval
    return null;
  }

  Future<bool> _setWebValue(String key, dynamic value, {Duration? ttl}) async {
    // Implement web storage setting
    return true;
  }

  Future<bool> _removeWebValue(String key) async {
    // Implement web storage removal
    return true;
  }

  Future<bool> _clearWebStorage() async {
    // Implement web storage clearing
    return true;
  }

  Future<List<String>> _getWebKeys() async {
    // Implement web storage key retrieval
    return [];
  }

  Future<bool> _setWebFile(String key, Uint8List data, {Duration? ttl}) async {
    // Implement web file storage (IndexedDB)
    return true;
  }

  Future<Uint8List?> _getWebFile(String key) async {
    // Implement web file retrieval
    return null;
  }

  // Desktop storage implementations
  Future<StorageInfo> _getDesktopStorageInfo() async {
    // Get desktop storage info
    return const StorageInfo(available: 1000000000, used: 0, total: 1000000000);
  }

  Future<dynamic> _getDesktopValue(String key) async {
    // Implement desktop storage retrieval
    return null;
  }

  Future<bool> _setDesktopValue(String key, dynamic value,
      {Duration? ttl}) async {
    // Implement desktop storage setting
    return true;
  }

  Future<bool> _removeDesktopValue(String key) async {
    // Implement desktop storage removal
    return true;
  }

  Future<bool> _clearDesktopStorage() async {
    // Implement desktop storage clearing
    return true;
  }

  Future<List<String>> _getDesktopKeys() async {
    // Implement desktop storage key retrieval
    return [];
  }

  Future<bool> _setNativeFile(String key, Uint8List data,
      {Duration? ttl}) async {
    // Implement native file storage
    return true;
  }

  Future<Uint8List?> _getNativeFile(String key) async {
    // Implement native file retrieval
    return null;
  }

  // Mobile storage implementations
  Future<StorageInfo> _getMobileStorageInfo() async {
    // Get mobile storage info
    return const StorageInfo(available: 100000000, used: 0, total: 100000000);
  }

  Future<dynamic> _getMobileValue(String key) async {
    // Implement mobile storage retrieval
    return null;
  }

  Future<bool> _setMobileValue(String key, dynamic value,
      {Duration? ttl}) async {
    // Implement mobile storage setting
    return true;
  }

  Future<bool> _removeMobileValue(String key) async {
    // Implement mobile storage removal
    return true;
  }

  Future<bool> _clearMobileStorage() async {
    // Implement mobile storage clearing
    return true;
  }

  Future<List<String>> _getMobileKeys() async {
    // Implement mobile storage key retrieval
    return [];
  }

  // Secure storage implementations
  Future<bool> _setSecureValue(String key, String value,
      {Duration? ttl}) async {
    // Implement secure storage (encrypted)
    return true;
  }

  Future<String?> _getSecureValue(String key) async {
    // Implement secure retrieval (decrypted)
    return null;
  }

  Future<bool> _removeSecureValue(String key) async {
    // Implement secure removal
    return true;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _memoryCache.clear();
    _isInitialized = false;
  }
}

/// Storage information
class StorageInfo {
  final int available;
  final int used;
  final int total;

  const StorageInfo({
    required this.available,
    required this.used,
    required this.total,
  });

  double get usagePercentage => total > 0 ? (used / total) * 100 : 0;
  bool get hasSpace => available > 0;
}
