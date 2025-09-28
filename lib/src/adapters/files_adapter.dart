/// Files adapter interface and implementations
///
/// This defines the interface that all files adapters must implement,
/// allowing for pluggable backends like SharedPreferences, IndexedDB,
/// desktop config files, mobile secure storage, etc.

import 'dart:async';
import 'dart:typed_data';
import '../models/storage_models.dart';

/// Abstract base class for all files adapters
///
/// This allows the unified files system to work with different
/// storage backends depending on the platform and requirements.
///
/// Adapters can be:
/// - SharedPreferencesAdapter (mobile/desktop preferences)
/// - IndexedDBAdapter (web storage)
/// - SecureStorageAdapter (encrypted storage)
/// - FileSystemAdapter (direct file system access)
/// - CloudStorageAdapter (cloud storage like Firebase, AWS S3)
/// - HybridAdapter (combines multiple adapters)
abstract class FilesAdapter {
  /// Name of this adapter
  String get name;

  /// Version of this adapter
  String get version;

  /// Initialize the adapter
  Future<bool> initialize();

  // Key-Value Storage Operations

  /// Store a string value
  Future<bool> setString(String key, String value);

  /// Retrieve a string value
  Future<String?> getString(String key);

  /// Store an integer value
  Future<bool> setInt(String key, int value);

  /// Retrieve an integer value
  Future<int?> getInt(String key);

  /// Store a double value
  Future<bool> setDouble(String key, double value);

  /// Retrieve a double value
  Future<double?> getDouble(String key);

  /// Store a boolean value
  Future<bool> setBool(String key, bool value);

  /// Retrieve a boolean value
  Future<bool?> getBool(String key);

  /// Store a JSON object
  Future<bool> setJson(String key, Map<String, dynamic> value);

  /// Retrieve a JSON object
  Future<Map<String, dynamic>?> getJson(String key);

  /// Store binary data
  Future<bool> setBytes(String key, Uint8List value);

  /// Retrieve binary data
  Future<Uint8List?> getBytes(String key);

  /// Remove a key
  Future<bool> remove(String key);

  /// Clear all storage
  Future<bool> clear();

  /// Get all keys
  Future<List<String>> getKeys();

  /// Check if key exists
  Future<bool> containsKey(String key);

  // Secure Storage Operations

  /// Store sensitive data with encryption
  Future<bool> setSecure(String key, String value);

  /// Retrieve sensitive data
  Future<String?> getSecure(String key);

  /// Remove secure key
  Future<bool> removeSecure(String key);

  /// Clear all secure storage
  Future<bool> clearSecure();

  // File Operations

  /// Pick a file from the device
  Future<UnifiedFile?> pickFile([List<String>? allowedExtensions]);

  /// Pick multiple files
  Future<List<UnifiedFile>> pickFiles([List<String>? allowedExtensions]);

  /// Pick an image file
  Future<UnifiedFile?> pickImage({ImageSource source = ImageSource.gallery});

  /// Save a file to device storage
  Future<String?> saveFile(String fileName, Uint8List bytes,
      {String? directory});

  /// Read a file from device storage
  Future<Uint8List?> readFile(String filePath);

  /// Delete a file
  Future<bool> deleteFile(String filePath);

  /// Check if file exists
  Future<bool> fileExists(String filePath);

  /// Get file information
  Future<FileInfo?> getFileInfo(String filePath);

  /// List files in directory
  Future<List<FileInfo>> listFiles(String directoryPath);

  /// Create directory
  Future<bool> createDirectory(String path);

  /// Delete directory
  Future<bool> deleteDirectory(String path);

  // Upload/Download Operations

  /// Upload a file with progress tracking
  Stream<UploadProgress> upload(
    String url,
    UnifiedFile file, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
  });

  /// Download a file with progress tracking
  Stream<DownloadProgress> download(
    String url,
    String savePath, {
    Map<String, String>? headers,
  });

  // File Watching

  /// Watch a directory for changes
  Stream<FileChangeEvent> watchDirectory(String path);

  /// Watch a specific file for changes
  Stream<FileChangeEvent> watchFile(String filePath);

  // Storage Information

  /// Get storage statistics
  Future<StorageStats> getStorageStats();

  /// Get cache size
  Future<int> getCacheSize();

  /// Clear cache
  Future<bool> clearCache();

  // Offline & Sync

  /// Save data for offline access
  Future<bool> saveOffline(String key, Map<String, dynamic> data);

  /// Get offline data
  Future<Map<String, dynamic>?> getOffline(String key);

  /// Sync offline data when online
  Future<bool> syncOfflineData();

  /// Check if data needs syncing
  Future<bool> hasUnsyncedData();

  /// Dispose resources
  Future<void> dispose();
}

/// Mock files adapter for testing and development
class MockFilesAdapter extends FilesAdapter {
  final Map<String, dynamic> _storage = {};
  final Map<String, String> _secureStorage = {};
  final Map<String, Map<String, dynamic>> _offlineStorage = {};

  @override
  String get name => 'MockFilesAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    return true;
  }

  // Key-Value Storage Operations
  @override
  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<String?> getString(String key) async {
    return _storage[key] as String?;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<int?> getInt(String key) async {
    return _storage[key] as int?;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<double?> getDouble(String key) async {
    return _storage[key] as double?;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _storage[key] as bool?;
  }

  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    _storage[key] = Map<String, dynamic>.from(value);
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final value = _storage[key];
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  @override
  Future<bool> setBytes(String key, Uint8List value) async {
    _storage[key] = Uint8List.fromList(value);
    return true;
  }

  @override
  Future<Uint8List?> getBytes(String key) async {
    final value = _storage[key];
    if (value is Uint8List) {
      return Uint8List.fromList(value);
    }
    return null;
  }

  @override
  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  @override
  Future<List<String>> getKeys() async {
    return _storage.keys.toList();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  // Secure Storage Operations
  @override
  Future<bool> setSecure(String key, String value) async {
    _secureStorage[key] = value;
    return true;
  }

  @override
  Future<String?> getSecure(String key) async {
    return _secureStorage[key];
  }

  @override
  Future<bool> removeSecure(String key) async {
    _secureStorage.remove(key);
    return true;
  }

  @override
  Future<bool> clearSecure() async {
    _secureStorage.clear();
    return true;
  }

  // File Operations
  @override
  Future<UnifiedFile?> pickFile([List<String>? allowedExtensions]) async {
    // Mock file picker - return a sample file
    return UnifiedFile.fromPlatform(
      id: 'mock_file_${DateTime.now().millisecondsSinceEpoch}',
      name: 'sample.txt',
      path: '/mock/path/sample.txt',
      size: 1024,
      bytes: Uint8List.fromList('Mock file content'.codeUnits),
      mimeType: 'text/plain',
      lastModified: DateTime.now(),
    );
  }

  @override
  Future<List<UnifiedFile>> pickFiles([List<String>? allowedExtensions]) async {
    // Mock multiple file picker
    return [
      UnifiedFile.fromPlatform(
        id: 'mock_file_1',
        name: 'file1.txt',
        size: 512,
        bytes: Uint8List.fromList('File 1 content'.codeUnits),
        mimeType: 'text/plain',
      ),
      UnifiedFile.fromPlatform(
        id: 'mock_file_2',
        name: 'file2.jpg',
        size: 2048,
        bytes: Uint8List.fromList('Mock image data'.codeUnits),
        mimeType: 'image/jpeg',
      ),
    ];
  }

  @override
  Future<UnifiedFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    // Mock image picker
    return UnifiedFile.fromPlatform(
      id: 'mock_image_${DateTime.now().millisecondsSinceEpoch}',
      name: 'sample.jpg',
      path: '/mock/path/sample.jpg',
      size: 4096,
      bytes: Uint8List.fromList('Mock image data'.codeUnits),
      mimeType: 'image/jpeg',
      lastModified: DateTime.now(),
    );
  }

  @override
  Future<String?> saveFile(String fileName, Uint8List bytes,
      {String? directory}) async {
    final path =
        directory != null ? '$directory/$fileName' : '/mock/path/$fileName';
    _storage['file:$path'] = bytes;
    return path;
  }

  @override
  Future<Uint8List?> readFile(String filePath) async {
    final value = _storage['file:$filePath'];
    if (value is Uint8List) {
      return value;
    }
    return null;
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    _storage.remove('file:$filePath');
    return true;
  }

  @override
  Future<bool> fileExists(String filePath) async {
    return _storage.containsKey('file:$filePath');
  }

  @override
  Future<FileInfo?> getFileInfo(String filePath) async {
    if (await fileExists(filePath)) {
      return FileInfo(
        path: filePath,
        name: filePath.split('/').last,
        size: 1024,
        isDirectory: false,
        lastModified: DateTime.now(),
        mimeType: 'text/plain',
      );
    }
    return null;
  }

  @override
  Future<List<FileInfo>> listFiles(String directoryPath) async {
    // Mock directory listing
    return [
      FileInfo(
        path: '$directoryPath/file1.txt',
        name: 'file1.txt',
        size: 512,
        isDirectory: false,
        lastModified: DateTime.now(),
        mimeType: 'text/plain',
      ),
      FileInfo(
        path: '$directoryPath/subfolder',
        name: 'subfolder',
        size: 0,
        isDirectory: true,
        lastModified: DateTime.now(),
      ),
    ];
  }

  @override
  Future<bool> createDirectory(String path) async {
    _storage['dir:$path'] = true;
    return true;
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    _storage.remove('dir:$path');
    return true;
  }

  // Upload/Download Operations
  @override
  Stream<UploadProgress> upload(
    String url,
    UnifiedFile file, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
  }) async* {
    // Mock upload with progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield UploadProgress(
        id: 'mock_upload_${file.id}',
        fileName: file.name,
        totalBytes: file.size,
        uploadedBytes: (file.size * i / 100).round(),
        percentage: i.toDouble(),
        isComplete: i == 100,
      );
    }
  }

  @override
  Stream<DownloadProgress> download(
    String url,
    String savePath, {
    Map<String, String>? headers,
  }) async* {
    // Mock download with progress
    const totalBytes = 1024 * 1024; // 1MB
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield DownloadProgress(
        id: 'mock_download_${DateTime.now().millisecondsSinceEpoch}',
        url: url,
        savePath: savePath,
        totalBytes: totalBytes,
        downloadedBytes: (totalBytes * i / 100).round(),
        percentage: i.toDouble(),
        isComplete: i == 100,
      );
    }
  }

  // File Watching
  @override
  Stream<FileChangeEvent> watchDirectory(String path) async* {
    // Mock file watching - emit some sample events
    await Future.delayed(const Duration(seconds: 1));
    yield FileChangeEvent(
      path: '$path/new_file.txt',
      type: FileChangeType.created,
      timestamp: DateTime.now(),
    );

    await Future.delayed(const Duration(seconds: 2));
    yield FileChangeEvent(
      path: '$path/existing_file.txt',
      type: FileChangeType.modified,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<FileChangeEvent> watchFile(String filePath) async* {
    // Mock file watching for specific file
    await Future.delayed(const Duration(seconds: 1));
    yield FileChangeEvent(
      path: filePath,
      type: FileChangeType.modified,
      timestamp: DateTime.now(),
    );
  }

  // Storage Information
  @override
  Future<StorageStats> getStorageStats() async {
    return const StorageStats(
      totalSpace: 1024 * 1024 * 1024 * 100, // 100GB
      freeSpace: 1024 * 1024 * 1024 * 60, // 60GB
      usedSpace: 1024 * 1024 * 1024 * 40, // 40GB
    );
  }

  @override
  Future<int> getCacheSize() async {
    return 1024 * 1024 * 5; // 5MB
  }

  @override
  Future<bool> clearCache() async {
    // Mock cache clearing
    return true;
  }

  // Offline & Sync
  @override
  Future<bool> saveOffline(String key, Map<String, dynamic> data) async {
    _offlineStorage[key] = Map<String, dynamic>.from(data);
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getOffline(String key) async {
    final data = _offlineStorage[key];
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  @override
  Future<bool> syncOfflineData() async {
    // Mock sync operation
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> hasUnsyncedData() async {
    return _offlineStorage.isNotEmpty;
  }

  @override
  Future<void> dispose() async {
    _storage.clear();
    _secureStorage.clear();
    _offlineStorage.clear();
  }
}

/// SharedPreferences-based adapter for mobile/desktop preferences
class SharedPreferencesAdapter extends FilesAdapter {
  @override
  String get name => 'SharedPreferencesAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    // Initialize SharedPreferences
    return true;
  }

  // Implementation would use SharedPreferences package
  @override
  Future<bool> setString(String key, String value) async {
    // Use SharedPreferences to store
    return true;
  }

  @override
  Future<String?> getString(String key) async {
    // Use SharedPreferences to retrieve
    return null;
  }

  // ... other methods would be implemented using SharedPreferences

  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<int?> getInt(String key) async => null;
  @override
  Future<bool> setDouble(String key, double value) async => true;
  @override
  Future<double?> getDouble(String key) async => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool?> getBool(String key) async => null;
  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async => true;
  @override
  Future<Map<String, dynamic>?> getJson(String key) async => null;
  @override
  Future<bool> setBytes(String key, Uint8List value) async => true;
  @override
  Future<Uint8List?> getBytes(String key) async => null;
  @override
  Future<bool> remove(String key) async => true;
  @override
  Future<bool> clear() async => true;
  @override
  Future<List<String>> getKeys() async => [];
  @override
  Future<bool> containsKey(String key) async => false;
  @override
  Future<bool> setSecure(String key, String value) async => true;
  @override
  Future<String?> getSecure(String key) async => null;
  @override
  Future<bool> removeSecure(String key) async => true;
  @override
  Future<bool> clearSecure() async => true;
  @override
  Future<UnifiedFile?> pickFile([List<String>? allowedExtensions]) async =>
      null;
  @override
  Future<List<UnifiedFile>> pickFiles(
          [List<String>? allowedExtensions]) async =>
      [];
  @override
  Future<UnifiedFile?> pickImage(
          {ImageSource source = ImageSource.gallery}) async =>
      null;
  @override
  Future<String?> saveFile(String fileName, Uint8List bytes,
          {String? directory}) async =>
      null;
  @override
  Future<Uint8List?> readFile(String filePath) async => null;
  @override
  Future<bool> deleteFile(String filePath) async => true;
  @override
  Future<bool> fileExists(String filePath) async => false;
  @override
  Future<FileInfo?> getFileInfo(String filePath) async => null;
  @override
  Future<List<FileInfo>> listFiles(String directoryPath) async => [];
  @override
  Future<bool> createDirectory(String path) async => true;
  @override
  Future<bool> deleteDirectory(String path) async => true;
  @override
  Stream<UploadProgress> upload(String url, UnifiedFile file,
      {Map<String, String>? headers, Map<String, dynamic>? fields}) async* {}
  @override
  Stream<DownloadProgress> download(String url, String savePath,
      {Map<String, String>? headers}) async* {}
  @override
  Stream<FileChangeEvent> watchDirectory(String path) async* {}
  @override
  Stream<FileChangeEvent> watchFile(String filePath) async* {}
  @override
  Future<StorageStats> getStorageStats() async =>
      const StorageStats(totalSpace: 0, freeSpace: 0, usedSpace: 0);
  @override
  Future<int> getCacheSize() async => 0;
  @override
  Future<bool> clearCache() async => true;
  @override
  Future<bool> saveOffline(String key, Map<String, dynamic> data) async => true;
  @override
  Future<Map<String, dynamic>?> getOffline(String key) async => null;
  @override
  Future<bool> syncOfflineData() async => true;
  @override
  Future<bool> hasUnsyncedData() async => false;
  @override
  Future<void> dispose() async {}
}

/// IndexedDB-based adapter for web storage
class IndexedDBAdapter extends FilesAdapter {
  @override
  String get name => 'IndexedDBAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    // Initialize IndexedDB
    return true;
  }

  // Implementation would use IndexedDB APIs
  // Similar structure to SharedPreferencesAdapter but using web storage

  @override
  Future<bool> setString(String key, String value) async => true;
  @override
  Future<String?> getString(String key) async => null;
  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<int?> getInt(String key) async => null;
  @override
  Future<bool> setDouble(String key, double value) async => true;
  @override
  Future<double?> getDouble(String key) async => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool?> getBool(String key) async => null;
  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async => true;
  @override
  Future<Map<String, dynamic>?> getJson(String key) async => null;
  @override
  Future<bool> setBytes(String key, Uint8List value) async => true;
  @override
  Future<Uint8List?> getBytes(String key) async => null;
  @override
  Future<bool> remove(String key) async => true;
  @override
  Future<bool> clear() async => true;
  @override
  Future<List<String>> getKeys() async => [];
  @override
  Future<bool> containsKey(String key) async => false;
  @override
  Future<bool> setSecure(String key, String value) async => true;
  @override
  Future<String?> getSecure(String key) async => null;
  @override
  Future<bool> removeSecure(String key) async => true;
  @override
  Future<bool> clearSecure() async => true;
  @override
  Future<UnifiedFile?> pickFile([List<String>? allowedExtensions]) async =>
      null;
  @override
  Future<List<UnifiedFile>> pickFiles(
          [List<String>? allowedExtensions]) async =>
      [];
  @override
  Future<UnifiedFile?> pickImage(
          {ImageSource source = ImageSource.gallery}) async =>
      null;
  @override
  Future<String?> saveFile(String fileName, Uint8List bytes,
          {String? directory}) async =>
      null;
  @override
  Future<Uint8List?> readFile(String filePath) async => null;
  @override
  Future<bool> deleteFile(String filePath) async => true;
  @override
  Future<bool> fileExists(String filePath) async => false;
  @override
  Future<FileInfo?> getFileInfo(String filePath) async => null;
  @override
  Future<List<FileInfo>> listFiles(String directoryPath) async => [];
  @override
  Future<bool> createDirectory(String path) async => true;
  @override
  Future<bool> deleteDirectory(String path) async => true;
  @override
  Stream<UploadProgress> upload(String url, UnifiedFile file,
      {Map<String, String>? headers, Map<String, dynamic>? fields}) async* {}
  @override
  Stream<DownloadProgress> download(String url, String savePath,
      {Map<String, String>? headers}) async* {}
  @override
  Stream<FileChangeEvent> watchDirectory(String path) async* {}
  @override
  Stream<FileChangeEvent> watchFile(String filePath) async* {}
  @override
  Future<StorageStats> getStorageStats() async =>
      const StorageStats(totalSpace: 0, freeSpace: 0, usedSpace: 0);
  @override
  Future<int> getCacheSize() async => 0;
  @override
  Future<bool> clearCache() async => true;
  @override
  Future<bool> saveOffline(String key, Map<String, dynamic> data) async => true;
  @override
  Future<Map<String, dynamic>?> getOffline(String key) async => null;
  @override
  Future<bool> syncOfflineData() async => true;
  @override
  Future<bool> hasUnsyncedData() async => false;
  @override
  Future<void> dispose() async {}
}
