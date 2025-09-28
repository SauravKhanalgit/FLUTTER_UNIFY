/// 📁 Unified Files & Storage API
///
/// Abstract differences between SharedPreferences, IndexedDB, desktop config files,
/// and mobile secure storage. Includes secure storage (encrypted at rest) for all platforms.
///
/// Features:
/// - Cross-platform file operations
/// - Secure storage with encryption
/// - Offline-first with sync capabilities
/// - File watching and change detection
/// - Upload/download with progress tracking
/// - Drag & drop support
/// - File type detection and validation

import 'dart:async';
import 'dart:typed_data';
import '../models/storage_models.dart';
import '../adapters/files_adapter.dart';

/// Unified files and storage API
///
/// This provides a single interface for all file and storage operations
/// across all platforms. The actual implementation is handled by
/// adapters that can be swapped based on your needs.
///
/// Example usage:
/// ```dart
/// // Simple key-value storage
/// await Unify.files.setString('user_preference', 'dark_mode');
/// final theme = await Unify.files.getString('user_preference');
///
/// // JSON storage with automatic serialization
/// await Unify.files.setJson('user_profile', {
///   'name': 'John Doe',
///   'email': 'john@example.com',
/// });
/// final profile = await Unify.files.getJson('user_profile');
///
/// // Secure storage for sensitive data
/// await Unify.files.setSecure('api_key', 'secret_key_here');
/// final apiKey = await Unify.files.getSecure('api_key');
///
/// // File operations
/// final file = await Unify.files.pickFile(['jpg', 'png']);
/// await Unify.files.saveFile('my_image.jpg', file.bytes);
///
/// // Upload with progress
/// Unify.files.upload(
///   'https://api.example.com/upload',
///   file: file,
/// ).listen((progress) {
///   print('Upload: ${progress.percentage}%');
/// });
///
/// // Watch for file changes
/// Unify.files.watchDirectory('/path/to/watch').listen((event) {
///   print('File ${event.path} was ${event.type}');
/// });
/// ```
class UnifiedFiles {
  UnifiedFiles._();

  static UnifiedFiles? _instance;
  static UnifiedFiles get instance => _instance ??= UnifiedFiles._();

  FilesAdapter? _adapter;
  final StreamController<FileChangeEvent> _fileChangeController =
      StreamController.broadcast();
  final StreamController<UploadProgress> _uploadController =
      StreamController.broadcast();
  final StreamController<DownloadProgress> _downloadController =
      StreamController.broadcast();

  /// Initialize the files system
  Future<bool> initialize([FilesAdapter? adapter]) async {
    _adapter = adapter ?? DefaultFilesAdapter();
    return await _adapter!.initialize();
  }

  /// Register a custom files adapter
  void registerAdapter(FilesAdapter adapter) {
    _adapter = adapter;
  }

  // Key-Value Storage

  /// Store a string value
  Future<bool> setString(String key, String value) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedFiles not initialized. Call initialize() first.');
    }
    return await _adapter!.setString(key, value);
  }

  /// Retrieve a string value
  Future<String?> getString(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getString(key);
  }

  /// Store an integer value
  Future<bool> setInt(String key, int value) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedFiles not initialized. Call initialize() first.');
    }
    return await _adapter!.setInt(key, value);
  }

  /// Retrieve an integer value
  Future<int?> getInt(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getInt(key);
  }

  /// Store a double value
  Future<bool> setDouble(String key, double value) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedFiles not initialized. Call initialize() first.');
    }
    return await _adapter!.setDouble(key, value);
  }

  /// Retrieve a double value
  Future<double?> getDouble(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getDouble(key);
  }

  /// Store a boolean value
  Future<bool> setBool(String key, bool value) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedFiles not initialized. Call initialize() first.');
    }
    return await _adapter!.setBool(key, value);
  }

  /// Retrieve a boolean value
  Future<bool?> getBool(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getBool(key);
  }

  /// Store a JSON object
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedFiles not initialized. Call initialize() first.');
    }
    return await _adapter!.setJson(key, value);
  }

  /// Retrieve a JSON object
  Future<Map<String, dynamic>?> getJson(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getJson(key);
  }

  /// Store binary data
  Future<bool> setBytes(String key, Uint8List value) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedFiles not initialized. Call initialize() first.');
    }
    return await _adapter!.setBytes(key, value);
  }

  /// Retrieve binary data
  Future<Uint8List?> getBytes(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getBytes(key);
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    if (_adapter == null) return false;
    return await _adapter!.remove(key);
  }

  /// Clear all storage
  Future<bool> clear() async {
    if (_adapter == null) return false;
    return await _adapter!.clear();
  }

  /// Get all keys
  Future<List<String>> getKeys() async {
    if (_adapter == null) return [];
    return await _adapter!.getKeys();
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    if (_adapter == null) return false;
    return await _adapter!.containsKey(key);
  }

  // Secure Storage

  /// Store sensitive data with encryption
  Future<bool> setSecure(String key, String value) async {
    if (_adapter == null) {
      throw StateError(
          'UnifiedFiles not initialized. Call initialize() first.');
    }
    return await _adapter!.setSecure(key, value);
  }

  /// Retrieve sensitive data
  Future<String?> getSecure(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getSecure(key);
  }

  /// Remove secure key
  Future<bool> removeSecure(String key) async {
    if (_adapter == null) return false;
    return await _adapter!.removeSecure(key);
  }

  /// Clear all secure storage
  Future<bool> clearSecure() async {
    if (_adapter == null) return false;
    return await _adapter!.clearSecure();
  }

  // File Operations

  /// Pick a file from the device
  Future<UnifiedFile?> pickFile([List<String>? allowedExtensions]) async {
    if (_adapter == null) return null;
    return await _adapter!.pickFile(allowedExtensions);
  }

  /// Pick multiple files
  Future<List<UnifiedFile>> pickFiles([List<String>? allowedExtensions]) async {
    if (_adapter == null) return [];
    return await _adapter!.pickFiles(allowedExtensions);
  }

  /// Pick an image file
  Future<UnifiedFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    if (_adapter == null) return null;
    return await _adapter!.pickImage(source: source);
  }

  /// Take a photo with camera
  Future<UnifiedFile?> takePhoto() async {
    if (_adapter == null) return null;
    return await _adapter!.pickImage(source: ImageSource.camera);
  }

  /// Save a file to device storage
  Future<String?> saveFile(String fileName, Uint8List bytes,
      {String? directory}) async {
    if (_adapter == null) return null;
    return await _adapter!.saveFile(fileName, bytes, directory: directory);
  }

  /// Read a file from device storage
  Future<Uint8List?> readFile(String filePath) async {
    if (_adapter == null) return null;
    return await _adapter!.readFile(filePath);
  }

  /// Delete a file
  Future<bool> deleteFile(String filePath) async {
    if (_adapter == null) return false;
    return await _adapter!.deleteFile(filePath);
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    if (_adapter == null) return false;
    return await _adapter!.fileExists(filePath);
  }

  /// Get file information
  Future<FileInfo?> getFileInfo(String filePath) async {
    if (_adapter == null) return null;
    return await _adapter!.getFileInfo(filePath);
  }

  /// List files in directory
  Future<List<FileInfo>> listFiles(String directoryPath) async {
    if (_adapter == null) return [];
    return await _adapter!.listFiles(directoryPath);
  }

  /// Create directory
  Future<bool> createDirectory(String path) async {
    if (_adapter == null) return false;
    return await _adapter!.createDirectory(path);
  }

  /// Delete directory
  Future<bool> deleteDirectory(String path) async {
    if (_adapter == null) return false;
    return await _adapter!.deleteDirectory(path);
  }

  // Upload/Download Operations

  /// Upload a file with progress tracking
  Stream<UploadProgress> upload(
    String url,
    UnifiedFile file, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
  }) async* {
    if (_adapter == null) {
      yield UploadProgress(
        id: 'error',
        fileName: file.name,
        totalBytes: 0,
        uploadedBytes: 0,
        percentage: 0,
        isComplete: false,
        error: 'UnifiedFiles not initialized',
      );
      return;
    }

    await for (final progress
        in _adapter!.upload(url, file, headers: headers, fields: fields)) {
      _uploadController.add(progress);
      yield progress;
    }
  }

  /// Download a file with progress tracking
  Stream<DownloadProgress> download(
    String url,
    String savePath, {
    Map<String, String>? headers,
  }) async* {
    if (_adapter == null) {
      yield DownloadProgress(
        id: 'error',
        url: url,
        savePath: savePath,
        totalBytes: 0,
        downloadedBytes: 0,
        percentage: 0,
        isComplete: false,
        error: 'UnifiedFiles not initialized',
      );
      return;
    }

    await for (final progress
        in _adapter!.download(url, savePath, headers: headers)) {
      _downloadController.add(progress);
      yield progress;
    }
  }

  // File Watching

  /// Watch a directory for changes
  Stream<FileChangeEvent> watchDirectory(String path) async* {
    if (_adapter == null) return;

    await for (final event in _adapter!.watchDirectory(path)) {
      _fileChangeController.add(event);
      yield event;
    }
  }

  /// Watch a specific file for changes
  Stream<FileChangeEvent> watchFile(String filePath) async* {
    if (_adapter == null) return;

    await for (final event in _adapter!.watchFile(filePath)) {
      _fileChangeController.add(event);
      yield event;
    }
  }

  // Storage Information

  /// Get storage statistics
  Future<StorageStats> getStorageStats() async {
    if (_adapter == null) {
      return const StorageStats(
        totalSpace: 0,
        freeSpace: 0,
        usedSpace: 0,
      );
    }
    return await _adapter!.getStorageStats();
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    if (_adapter == null) return 0;
    return await _adapter!.getCacheSize();
  }

  /// Clear cache
  Future<bool> clearCache() async {
    if (_adapter == null) return false;
    return await _adapter!.clearCache();
  }

  // Offline & Sync

  /// Save data for offline access
  Future<bool> saveOffline(String key, Map<String, dynamic> data) async {
    if (_adapter == null) return false;
    return await _adapter!.saveOffline(key, data);
  }

  /// Get offline data
  Future<Map<String, dynamic>?> getOffline(String key) async {
    if (_adapter == null) return null;
    return await _adapter!.getOffline(key);
  }

  /// Sync offline data when online
  Future<bool> syncOfflineData() async {
    if (_adapter == null) return false;
    return await _adapter!.syncOfflineData();
  }

  /// Check if data needs syncing
  Future<bool> hasUnsyncedData() async {
    if (_adapter == null) return false;
    return await _adapter!.hasUnsyncedData();
  }

  // Stream Getters

  /// Stream of file change events
  Stream<FileChangeEvent> get onFileChanged => _fileChangeController.stream;

  /// Stream of upload progress events
  Stream<UploadProgress> get onUploadProgress => _uploadController.stream;

  /// Stream of download progress events
  Stream<DownloadProgress> get onDownloadProgress => _downloadController.stream;

  /// Dispose resources
  Future<void> dispose() async {
    await _fileChangeController.close();
    await _uploadController.close();
    await _downloadController.close();
    await _adapter?.dispose();
  }
}

/// Default files adapter
class DefaultFilesAdapter extends FilesAdapter {
  @override
  String get name => 'DefaultFilesAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    return true;
  }

  // Basic implementations - would be platform-specific in real implementation
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
  Stream<UploadProgress> upload(
    String url,
    UnifiedFile file, {
    Map<String, String>? headers,
    Map<String, dynamic>? fields,
  }) async* {
    // Mock upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield UploadProgress(
        id: 'mock_upload',
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
    // Mock download progress
    const totalBytes = 1024 * 1024; // 1MB
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield DownloadProgress(
        id: 'mock_download',
        url: url,
        savePath: savePath,
        totalBytes: totalBytes,
        downloadedBytes: (totalBytes * i / 100).round(),
        percentage: i.toDouble(),
        isComplete: i == 100,
      );
    }
  }

  @override
  Stream<FileChangeEvent> watchDirectory(String path) async* {
    // Mock file watching - would use platform-specific file watchers
  }

  @override
  Stream<FileChangeEvent> watchFile(String filePath) async* {
    // Mock file watching
  }

  @override
  Future<StorageStats> getStorageStats() async {
    return const StorageStats(
      totalSpace: 1024 * 1024 * 1024 * 100, // 100GB
      freeSpace: 1024 * 1024 * 1024 * 50, // 50GB
      usedSpace: 1024 * 1024 * 1024 * 50, // 50GB
    );
  }

  @override
  Future<int> getCacheSize() async => 1024 * 1024 * 10; // 10MB

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
