import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqf;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/storage_models.dart';
import '../storage/storage_paths.dart';
import '../storage/audit_trail.dart';
import 'files_adapter.dart';

/// Files adapter backed by SQLite for key/value and indexes and filesystem for blobs
class SqliteFilesAdapter extends FilesAdapter {
  final _audit = AuditTrail.instance;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  sqf.Database? _db;
  late final String _dbPath;
  late final String _attachmentsDir;

  @override
  String get name => 'SqliteFilesAdapter';

  @override
  String get version => '1.0.0';

  @override
  Future<bool> initialize() async {
    final dbDir = await StoragePaths.instance.databaseDir();
    _dbPath = p.join(dbDir, 'unify_storage.db');
    _attachmentsDir = await StoragePaths.instance.attachmentsDir();
    await Directory(_attachmentsDir).create(recursive: true);

    _db = await sqf.openDatabase(
      _dbPath,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE kv (
            k TEXT PRIMARY KEY,
            v TEXT,
            t TEXT, -- type: string,int,double,bool,json,bytes
            ts INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            k TEXT,
            payload TEXT,
            ts INTEGER
          );
        ''');
      },
    );
    return true;
  }

  Future<int> _putKv(String key, String value, String type) async {
    return await _db!.insert(
      'kv',
      {
        'k': key,
        'v': value,
        't': type,
        'ts': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: sqf.ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> _getKv(String key) async {
    final rows =
        await _db!.query('kv', where: 'k=?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // Key-Value ops
  @override
  Future<bool> setString(String key, String value) async {
    await _putKv(key, value, 'string');
    _audit.log(entity: 'kv', operation: 'CREATE', id: key, after: {'v': value});
    return true;
  }

  @override
  Future<String?> getString(String key) async {
    final row = await _getKv(key);
    return row?['v'] as String?;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    await _putKv(key, value.toString(), 'int');
    _audit.log(entity: 'kv', operation: 'CREATE', id: key, after: {'v': value});
    return true;
  }

  @override
  Future<int?> getInt(String key) async {
    final row = await _getKv(key);
    return row != null ? int.tryParse(row['v'] as String) : null;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    await _putKv(key, value.toString(), 'double');
    _audit.log(entity: 'kv', operation: 'CREATE', id: key, after: {'v': value});
    return true;
  }

  @override
  Future<double?> getDouble(String key) async {
    final row = await _getKv(key);
    return row != null ? double.tryParse(row['v'] as String) : null;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    await _putKv(key, value ? '1' : '0', 'bool');
    _audit.log(entity: 'kv', operation: 'CREATE', id: key, after: {'v': value});
    return true;
  }

  @override
  Future<bool?> getBool(String key) async {
    final row = await _getKv(key);
    final v = row?['v'] as String?;
    if (v == null) return null;
    return v == '1';
  }

  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    await _putKv(key, jsonEncode(value), 'json');
    _audit.log(entity: 'kv', operation: 'CREATE', id: key, after: value);
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final row = await _getKv(key);
    final v = row?['v'] as String?;
    return v != null ? jsonDecode(v) as Map<String, dynamic> : null;
  }

  @override
  Future<bool> setBytes(String key, Uint8List value) async {
    // Store as base64 in kv for small blobs
    await _putKv(key, base64Encode(value), 'bytes');
    _audit.log(
        entity: 'kv',
        operation: 'CREATE',
        id: key,
        after: {'len': value.length});
    return true;
  }

  @override
  Future<Uint8List?> getBytes(String key) async {
    final row = await _getKv(key);
    final v = row?['v'] as String?;
    return v != null ? Uint8List.fromList(base64Decode(v)) : null;
  }

  @override
  Future<bool> remove(String key) async {
    await _db!.delete('kv', where: 'k=?', whereArgs: [key]);
    _audit.log(entity: 'kv', operation: 'DELETE', id: key);
    return true;
  }

  @override
  Future<bool> clear() async {
    await _db!.delete('kv');
    _audit.log(entity: 'kv', operation: 'DELETE', id: '*');
    return true;
  }

  @override
  Future<List<String>> getKeys() async {
    final rows = await _db!.query('kv', columns: ['k']);
    return rows.map((e) => e['k'] as String).toList();
  }

  @override
  Future<bool> containsKey(String key) async {
    final row = await _getKv(key);
    return row != null;
  }

  // Secure storage (delegates to platform keystore)
  @override
  Future<bool> setSecure(String key, String value) async {
    await _secure.write(
        key: key,
        value: value,
        aOptions: const AndroidOptions(encryptedSharedPreferences: true));
    _audit.log(entity: 'secure', operation: 'CREATE', id: key);
    return true;
  }

  @override
  Future<String?> getSecure(String key) async {
    return _secure.read(key: key);
  }

  @override
  Future<bool> removeSecure(String key) async {
    await _secure.delete(key: key);
    _audit.log(entity: 'secure', operation: 'DELETE', id: key);
    return true;
  }

  @override
  Future<bool> clearSecure() async {
    await _secure.deleteAll();
    _audit.log(entity: 'secure', operation: 'DELETE', id: '*');
    return true;
  }

  // File operations
  @override
  Future<UnifiedFile?> pickFile([List<String>? allowedExtensions]) async {
    // For brevity, not implementing file_selector here
    return null;
  }

  @override
  Future<List<UnifiedFile>> pickFiles([List<String>? allowedExtensions]) async {
    return <UnifiedFile>[];
  }

  @override
  Future<UnifiedFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    return null;
  }

  @override
  Future<String?> saveFile(String fileName, Uint8List bytes,
      {String? directory}) async {
    final dir = directory ?? _attachmentsDir;
    final filePath = p.join(dir, fileName);
    final f = File(filePath);
    await f.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
    _audit.log(
        entity: 'file',
        operation: 'CREATE',
        id: fileName,
        after: {'path': filePath});
    return filePath;
  }

  @override
  Future<Uint8List?> readFile(String filePath) async {
    final f = File(filePath);
    if (!await f.exists()) return null;
    return await f.readAsBytes();
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    final f = File(filePath);
    if (await f.exists()) {
      await f.delete();
      _audit.log(entity: 'file', operation: 'DELETE', id: p.basename(filePath));
    }
    return true;
  }

  @override
  Future<bool> fileExists(String filePath) async => File(filePath).exists();

  @override
  Future<FileInfo?> getFileInfo(String filePath) async {
    final f = File(filePath);
    if (!await f.exists()) return null;
    final stat = await f.stat();
    return FileInfo(
      path: filePath,
      name: p.basename(filePath),
      size: stat.size,
      isDirectory: false,
      lastModified: stat.modified,
      lastAccessed: stat.accessed,
      created: stat.changed,
    );
  }

  @override
  Future<List<FileInfo>> listFiles(String directoryPath) async {
    final d = Directory(directoryPath);
    if (!await d.exists()) return <FileInfo>[];
    final entries = await d.list(recursive: false, followLinks: false).toList();
    final results = <FileInfo>[];
    for (final e in entries) {
      final stat = await e.stat();
      results.add(
        FileInfo(
          path: e.path,
          name: p.basename(e.path),
          size: stat.size,
          isDirectory: stat.type == FileSystemEntityType.directory,
          lastModified: stat.modified,
          lastAccessed: stat.accessed,
          created: stat.changed,
        ),
      );
    }
    return results;
  }

  @override
  Future<bool> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
    return true;
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    final d = Directory(path);
    if (await d.exists()) {
      await d.delete(recursive: true);
    }
    return true;
  }

  // Upload/Download (placeholders)
  @override
  Stream<UploadProgress> upload(String url, UnifiedFile file,
      {Map<String, String>? headers, Map<String, dynamic>? fields}) async* {}

  @override
  Stream<DownloadProgress> download(String url, String savePath,
      {Map<String, String>? headers}) async* {}

  // Watchers (not implemented)
  @override
  Stream<FileChangeEvent> watchDirectory(String path) async* {}

  @override
  Stream<FileChangeEvent> watchFile(String filePath) async* {}

  // Storage Info
  @override
  Future<StorageStats> getStorageStats() async {
    // Not trivial cross-platform; placeholder totals
    return const StorageStats(totalSpace: 0, freeSpace: 0, usedSpace: 0);
  }

  @override
  Future<int> getCacheSize() async => 0;

  @override
  Future<bool> clearCache() async => true;

  // Offline-first queue
  @override
  Future<bool> saveOffline(String key, Map<String, dynamic> data) async {
    await _db!.insert('offline_queue', {
      'k': key,
      'payload': jsonEncode(data),
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    _audit.log(entity: 'offline', operation: 'CREATE', id: key, after: data);
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getOffline(String key) async {
    final rows = await _db!.query('offline_queue',
        where: 'k=?', whereArgs: [key], orderBy: 'ts DESC', limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  @override
  Future<bool> syncOfflineData() async {
    // Placeholder: user should provide sync callback; mark as synced
    return true;
  }

  @override
  Future<bool> hasUnsyncedData() async {
    final count = sqf.Sqflite.firstIntValue(
            await _db!.rawQuery('SELECT COUNT(*) FROM offline_queue')) ??
        0;
    return count > 0;
  }

  @override
  Future<void> dispose() async {
    await _db?.close();
  }
}
