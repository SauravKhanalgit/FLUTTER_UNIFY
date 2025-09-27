import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../common/event_emitter.dart';
import '../common/platform_detector.dart';

/// Global shortcuts manager
class ShortcutsManager extends EventEmitter {
  static const MethodChannel _channel =
      MethodChannel('flutter_unify/shortcuts');

  bool _isInitialized = false;
  final Map<String, GlobalShortcut> _registeredShortcuts = {};

  /// Check if shortcuts manager is initialized
  bool get isInitialized => _isInitialized;

  /// Get registered shortcuts
  Map<String, GlobalShortcut> get registeredShortcuts =>
      Map.from(_registeredShortcuts);

  /// Initialize shortcuts manager
  Future<void> initialize() async {
    if (kIsWeb || !PlatformDetector.supportsGlobalShortcuts) {
      throw UnsupportedError(
          'Global shortcuts are not supported on this platform');
    }

    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');

      _isInitialized = true;
      emit('shortcuts-initialized');

      if (kDebugMode) {
        print('ShortcutsManager: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ShortcutsManager: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onShortcutPressed':
        final shortcutKey = call.arguments['shortcut'] as String;
        final timestamp = call.arguments['timestamp'] as int?;

        final shortcut = _registeredShortcuts[shortcutKey];
        if (shortcut != null) {
          emit('shortcut-pressed', {
            'shortcut': shortcutKey,
            'timestamp': timestamp,
          });

          if (shortcut.onPressed != null) {
            try {
              shortcut.onPressed!();
            } catch (e) {
              if (kDebugMode) {
                print(
                    'ShortcutsManager: Error in shortcut handler for $shortcutKey: $e');
              }
            }
          }
        }
        break;

      default:
        if (kDebugMode) {
          print('ShortcutsManager: Unknown method call: ${call.method}');
        }
    }
  }

  /// Register a global shortcut
  Future<bool> register(
    String shortcut,
    VoidCallback onPressed, {
    String? description,
    bool replaceExisting = false,
  }) async {
    if (!_isInitialized) {
      throw StateError('ShortcutsManager must be initialized first');
    }

    // Check if shortcut already exists
    if (_registeredShortcuts.containsKey(shortcut) && !replaceExisting) {
      if (kDebugMode) {
        print('ShortcutsManager: Shortcut $shortcut already registered');
      }
      return false;
    }

    // Validate shortcut format
    if (!_isValidShortcut(shortcut)) {
      if (kDebugMode) {
        print('ShortcutsManager: Invalid shortcut format: $shortcut');
      }
      return false;
    }

    try {
      final result = await _channel.invokeMethod('registerShortcut', {
        'shortcut': shortcut,
        'description': description ?? '',
      }) as bool?;

      if (result == true) {
        _registeredShortcuts[shortcut] = GlobalShortcut(
          keys: shortcut,
          onPressed: onPressed,
          description: description,
        );

        emit('shortcut-registered', shortcut);

        if (kDebugMode) {
          print('ShortcutsManager: Registered shortcut: $shortcut');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('ShortcutsManager: Failed to register shortcut: $shortcut');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ShortcutsManager: Error registering shortcut $shortcut: $e');
      }
      return false;
    }
  }

  /// Unregister a global shortcut
  Future<bool> unregister(String shortcut) async {
    if (!_isInitialized) return false;

    if (!_registeredShortcuts.containsKey(shortcut)) {
      if (kDebugMode) {
        print('ShortcutsManager: Shortcut $shortcut not found');
      }
      return false;
    }

    try {
      final result = await _channel.invokeMethod('unregisterShortcut', {
        'shortcut': shortcut,
      }) as bool?;

      if (result == true) {
        _registeredShortcuts.remove(shortcut);
        emit('shortcut-unregistered', shortcut);

        if (kDebugMode) {
          print('ShortcutsManager: Unregistered shortcut: $shortcut');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('ShortcutsManager: Failed to unregister shortcut: $shortcut');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ShortcutsManager: Error unregistering shortcut $shortcut: $e');
      }
      return false;
    }
  }

  /// Unregister all shortcuts
  Future<void> unregisterAll() async {
    if (!_isInitialized) return;

    final shortcuts = List<String>.from(_registeredShortcuts.keys);
    for (final shortcut in shortcuts) {
      await unregister(shortcut);
    }

    if (kDebugMode) {
      print('ShortcutsManager: Unregistered all shortcuts');
    }
  }

  /// Check if a shortcut is registered
  bool isRegistered(String shortcut) {
    return _registeredShortcuts.containsKey(shortcut);
  }

  /// Get list of available modifier keys for this platform
  List<String> getAvailableModifiers() {
    if (PlatformDetector.isMacOS) {
      return ['Cmd', 'Alt', 'Ctrl', 'Shift'];
    } else {
      return ['Ctrl', 'Alt', 'Shift', 'Win'];
    }
  }

  /// Get list of available function keys
  List<String> getFunctionKeys() {
    return List.generate(12, (index) => 'F${index + 1}');
  }

  /// Validate shortcut format
  bool _isValidShortcut(String shortcut) {
    if (shortcut.isEmpty) return false;

    // Split by + and trim spaces
    final parts = shortcut.split('+').map((s) => s.trim()).toList();

    if (parts.length < 2) return false; // Must have at least modifier + key

    final modifiers = parts.take(parts.length - 1).toList();
    final key = parts.last;

    // Check modifiers
    final validModifiers = getAvailableModifiers();
    for (final modifier in modifiers) {
      if (!validModifiers.contains(modifier)) return false;
    }

    // Check key (simplified validation)
    if (key.isEmpty) return false;

    return true;
  }

  /// Create shortcut string for current platform
  String createShortcut({
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool meta = false, // Cmd on macOS, Win on Windows
    required String key,
  }) {
    final modifiers = <String>[];

    if (PlatformDetector.isMacOS) {
      if (meta) modifiers.add('Cmd');
      if (ctrl) modifiers.add('Ctrl');
      if (alt) modifiers.add('Alt');
      if (shift) modifiers.add('Shift');
    } else {
      if (ctrl) modifiers.add('Ctrl');
      if (alt) modifiers.add('Alt');
      if (shift) modifiers.add('Shift');
      if (meta) modifiers.add('Win');
    }

    modifiers.add(key);
    return modifiers.join('+');
  }

  /// Get system shortcut conflicts
  Future<List<String>> getSystemConflicts(String shortcut) async {
    if (!_isInitialized) return [];

    try {
      final result = await _channel.invokeMethod('getSystemConflicts', {
        'shortcut': shortcut,
      }) as List<dynamic>?;

      return result?.cast<String>() ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('ShortcutsManager: Error checking system conflicts: $e');
      }
      return [];
    }
  }

  /// Check if shortcut is available (no system conflicts)
  Future<bool> isShortcutAvailable(String shortcut) async {
    final conflicts = await getSystemConflicts(shortcut);
    return conflicts.isEmpty;
  }

  /// Get shortcut suggestions based on action
  List<String> getShortcutSuggestions(String action) {
    final suggestions = <String>[];

    switch (action.toLowerCase()) {
      case 'copy':
        suggestions.add(createShortcut(ctrl: true, key: 'C'));
        break;
      case 'paste':
        suggestions.add(createShortcut(ctrl: true, key: 'V'));
        break;
      case 'cut':
        suggestions.add(createShortcut(ctrl: true, key: 'X'));
        break;
      case 'undo':
        suggestions.add(createShortcut(ctrl: true, key: 'Z'));
        break;
      case 'redo':
        suggestions.add(createShortcut(ctrl: true, shift: true, key: 'Z'));
        break;
      case 'save':
        suggestions.add(createShortcut(ctrl: true, key: 'S'));
        break;
      case 'open':
        suggestions.add(createShortcut(ctrl: true, key: 'O'));
        break;
      case 'new':
        suggestions.add(createShortcut(ctrl: true, key: 'N'));
        break;
      case 'find':
        suggestions.add(createShortcut(ctrl: true, key: 'F'));
        break;
      case 'quit':
        if (PlatformDetector.isMacOS) {
          suggestions.add(createShortcut(meta: true, key: 'Q'));
        } else {
          suggestions.add(createShortcut(alt: true, key: 'F4'));
        }
        break;
    }

    return suggestions;
  }

  /// Dispose shortcuts manager
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await unregisterAll();
      await _channel.invokeMethod('dispose');
      removeAllListeners();

      if (kDebugMode) {
        print('ShortcutsManager: Disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ShortcutsManager: Failed to dispose: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }
}

/// Global shortcut configuration
class GlobalShortcut {
  final String keys;
  final VoidCallback? onPressed;
  final String? description;
  final bool isEnabled;

  GlobalShortcut({
    required this.keys,
    this.onPressed,
    this.description,
    this.isEnabled = true,
  });

  /// Create from map
  factory GlobalShortcut.fromMap(Map<String, dynamic> map) {
    return GlobalShortcut(
      keys: map['keys'] ?? '',
      description: map['description'],
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'keys': keys,
      'description': description,
      'isEnabled': isEnabled,
    };
  }

  @override
  String toString() => 'GlobalShortcut(keys: $keys, description: $description)';
}
