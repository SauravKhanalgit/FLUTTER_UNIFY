import 'dart:async';
import 'dart:typed_data';
import '../models/storage_models.dart';
import 'files_adapter.dart';

/// Web/no-IO stub for SqliteFilesAdapter to keep builds working on web
class SqliteFilesAdapter extends FilesAdapter {
  @override
  String get name => 'SqliteFilesAdapterStub';
  @override
  String get version => '0.0.0';

  @override
  Future<bool> initialize() async => true;

  // All methods are no-ops suitable for web; host app can provide a web adapter.
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
  Future<List<String>> getKeys() async => <String>[];
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
      <UnifiedFile>[];
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
  Future<List<FileInfo>> listFiles(String directoryPath) async => <FileInfo>[];
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
