import 'dart:async';
import 'dart:io' show Directory;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cross-platform app paths for databases, attachments, cache, temp, etc.
class StoragePaths {
  StoragePaths._();
  static StoragePaths? _instance;
  static StoragePaths get instance => _instance ??= StoragePaths._();

  bool _initialized = false;
  Directory? _appSupport;
  Directory? _appDocs;
  Directory? _cache;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      // No real file system, logical paths only
      _initialized = true;
      return;
    }
    _appSupport = await getApplicationSupportDirectory();
    _appDocs = await getApplicationDocumentsDirectory();
    _cache = await getTemporaryDirectory();
    _initialized = true;
  }

  /// Application support dir (safe for databases/config)
  Future<String> appSupportDir() async {
    await initialize();
    if (kIsWeb) return '/web/support';
    return _appSupport!.path;
  }

  /// Application documents dir (user-visible on some platforms)
  Future<String> appDocumentsDir() async {
    await initialize();
    if (kIsWeb) return '/web/docs';
    return _appDocs!.path;
  }

  /// Cache directory
  Future<String> cacheDir() async {
    await initialize();
    if (kIsWeb) return '/web/cache';
    return _cache!.path;
  }

  /// Directory for databases
  Future<String> databaseDir() async {
    final base = kIsWeb ? '/web/db' : await appSupportDir();
    final dir = p.join(base, 'databases');
    if (!kIsWeb) {
      final d = Directory(dir);
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
    }
    return dir;
  }

  /// Directory for large file attachments
  Future<String> attachmentsDir() async {
    final base = kIsWeb ? '/web/files' : await appSupportDir();
    final dir = p.join(base, 'attachments');
    if (!kIsWeb) {
      final d = Directory(dir);
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
    }
    return dir;
  }

  /// Build a database file path
  Future<String> databaseFile(String name) async {
    final dir = await databaseDir();
    final fileName = name.endsWith('.db') ? name : '$name.db';
    return p.join(dir, fileName);
  }
}
