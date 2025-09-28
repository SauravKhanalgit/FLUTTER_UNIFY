import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth/unified_auth.dart';
import 'networking/unified_networking.dart';
import 'files/unified_files.dart';
import '../unified/system.dart';
import '../unified/notifications.dart';
import 'config/unify_config.dart';
import '../adapters/auth_adapter.dart';
import '../adapters/networking_adapter.dart';
import '../adapters/files_adapter.dart';

/// 🚀 Main Unify class - Single entry point for all unified APIs
///
/// This class provides a Bloc-like architecture with everything accessible
/// through a single namespace. Each module can be configured with different
/// adapters for maximum flexibility.
class Unify {
  // Private constructor
  Unify._();

  // Singleton instance
  static Unify? _instance;
  static Unify get instance => _instance ??= Unify._();

  // State management
  static UnifyConfig? _config;
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  // Module instances - only the ones we've actually implemented
  static UnifiedAuth? _auth;
  static UnifiedNetworking? _networking;
  static UnifiedFiles? _files;
  static UnifiedSystem? _system;
  static UnifiedNotifications? _notifications;

  // Streams
  static final StreamController<bool> _initializationController =
      StreamController<bool>.broadcast();

  /// Configuration
  static UnifyConfig get config => _config ??= UnifyConfig();
  static set config(UnifyConfig newConfig) => _config = newConfig;

  /// Initialization state
  static bool get isInitialized => _isInitialized;
  static bool get isInitializing => _isInitializing;
  static Stream<bool> get onInitializationChanged =>
      _initializationController.stream;

  /// Initialize the framework
  static Future<bool> initialize([
    UnifyConfig? config,
    AuthAdapter? authAdapter,
    NetworkingAdapter? networkingAdapter,
    FilesAdapter? filesAdapter,
  ]) async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      await _initializationController.stream
          .firstWhere((initialized) => initialized);
      return _isInitialized;
    }

    _isInitializing = true;
    _initializationController.add(false);

    try {
      if (kDebugMode) {
        print('Unify: Initializing framework...');
      }

      if (config != null)
        _config = config;
      else if (_config == null) _config = UnifyConfig();

      final results = <String, bool>{};

      // Initialize modules
      try {
        _auth = UnifiedAuth.instance;
        if (authAdapter != null) {
          _auth!.setAdapter(authAdapter);
        }
        results['auth'] = await _auth!.initialize(_config!.authConfig);
      } catch (e) {
        results['auth'] = false;
        if (kDebugMode) print('Unify: Auth init error: $e');
      }

      try {
        _networking = UnifiedNetworking.instance;
        results['networking'] =
            await _networking!.initialize(networkingAdapter);
      } catch (e) {
        results['networking'] = false;
        if (kDebugMode) print('Unify: Networking init error: $e');
      }

      try {
        _files = UnifiedFiles.instance;
        results['files'] = await _files!.initialize(filesAdapter);
      } catch (e) {
        results['files'] = false;
        if (kDebugMode) print('Unify: Files init error: $e');
      }

      try {
        _system = UnifiedSystem.instance;
        results['system'] = await _system!.initialize();
      } catch (e) {
        results['system'] = false;
        if (kDebugMode) print('Unify: System init error: $e');
      }

      try {
        _notifications = UnifiedNotifications.instance;
        results['notifications'] = await _notifications!.initialize();
      } catch (e) {
        results['notifications'] = false;
        if (kDebugMode) print('Unify: Notifications init error: $e');
      }

      _isInitialized = results.values.any((success) => success);
      if (kDebugMode) {
        print('Unify: ${_isInitialized ? '✅ Initialized' : '❌ Failed'}');
        print(
            'Unify: Modules: ${results.entries.where((e) => e.value).map((e) => e.key).join(', ')}');
      }

      return _isInitialized;
    } finally {
      _isInitializing = false;
      _initializationController.add(_isInitialized);
    }
  }

  /// Auth module
  static UnifiedAuth get auth {
    _ensureInitialized();
    return _auth!;
  }

  /// Networking module
  static UnifiedNetworking get networking {
    _ensureInitialized();
    return _networking!;
  }

  /// Files module
  static UnifiedFiles get files {
    _ensureInitialized();
    return _files!;
  }

  /// System module
  static UnifiedSystem get system {
    _ensureInitialized();
    return _system!;
  }

  /// Notifications module
  static UnifiedNotifications get notifications {
    _ensureInitialized();
    return _notifications!;
  }

  /// Framework version
  static String get version => '1.0.0';

  /// Available modules
  static List<String> get availableModules {
    final modules = <String>[];
    if (_auth != null) modules.add('auth');
    if (_networking != null) modules.add('networking');
    if (_files != null) modules.add('files');
    if (_system != null) modules.add('system');
    if (_notifications != null) modules.add('notifications');
    return modules;
  }

  /// Register adapters
  static void registerAuthAdapter(AuthAdapter adapter) =>
      _auth?.setAdapter(adapter);
  static void registerNetworkingAdapter(NetworkingAdapter adapter) =>
      _networking?.registerAdapter(adapter);
  static void registerFilesAdapter(FilesAdapter adapter) =>
      _files?.registerAdapter(adapter);

  /// Dispose all resources
  static Future<void> dispose() async {
    final tasks = <Future<void>>[];
    if (_auth != null) tasks.add(_auth!.dispose());
    if (_networking != null) tasks.add(_networking!.dispose());
    if (_files != null) tasks.add(_files!.dispose());
    if (_system != null) tasks.add(_system!.dispose());
    if (_notifications != null) tasks.add(_notifications!.dispose());

    await Future.wait(tasks);

    _auth = null;
    _networking = null;
    _files = null;
    _system = null;
    _notifications = null;
    _isInitialized = false;
    _isInitializing = false;

    await _initializationController.close();
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Unify not initialized. Call Unify.initialize() first.');
    }
  }
}
