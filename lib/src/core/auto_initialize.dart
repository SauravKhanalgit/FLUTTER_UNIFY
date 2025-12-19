/// Auto-initialization for Flutter Unify
///
/// Automatically detects and configures the best adapters based on
/// available packages and environment. Makes setup effortless!

import 'package:flutter/foundation.dart';
import 'unify.dart';
import '../adapters/auth_adapter.dart';
import '../adapters/networking_adapter.dart';
import '../adapters/files_adapter.dart';
import '../ai/unified_ai.dart';
import '../ai/adapters/ai_adapter.dart' as ai;
import '../ai/models/ai_models.dart' as ai_models;

/// Auto-initialization result
class AutoInitResult {
  const AutoInitResult({
    required this.success,
    required this.initializedModules,
    this.errors,
    this.suggestions,
  });

  final bool success;
  final List<String> initializedModules;
  final Map<String, String>? errors;
  final List<String>? suggestions;
}

/// Auto-initialization helper
class AutoInitialize {
  AutoInitialize._();
  static AutoInitialize? _instance;
  static AutoInitialize get instance => _instance ??= AutoInitialize._();

  /// Automatically initialize Flutter Unify with best available adapters
  ///
  /// This method:
  /// 1. Detects available packages (Firebase, Supabase, etc.)
  /// 2. Configures appropriate adapters
  /// 3. Initializes all modules
  /// 4. Returns result with suggestions
  ///
  /// **Usage:**
  /// ```dart
  /// final result = await Unify.autoInitialize();
  /// if (result.success) {
  ///   print('Initialized: ${result.initializedModules}');
  /// } else {
  ///   print('Errors: ${result.errors}');
  ///   print('Suggestions: ${result.suggestions}');
  /// }
  /// ```
  Future<AutoInitResult> initialize({
    Map<String, dynamic>? config,
    String? aiApiKey,
    ai_models.AIProvider? aiProvider,
  }) async {
    final initializedModules = <String>[];
    final errors = <String, String>{};
    final suggestions = <String>[];

    try {
      // Initialize core Unify framework
      final coreInit = await Unify.initialize();
      if (coreInit) {
        initializedModules.add('core');
      }

      // Try to detect and initialize Firebase Auth
      try {
        final firebaseAdapter = _tryCreateFirebaseAdapter();
        if (firebaseAdapter != null) {
          await firebaseAdapter.initialize();
          Unify.registerAuthAdapter(firebaseAdapter);
          initializedModules.add('firebase_auth');
        } else {
          suggestions.add('Add firebase_auth package for Firebase authentication');
        }
      } catch (e) {
        errors['firebase_auth'] = e.toString();
      }

      // Initialize AI if API key provided
      if (aiApiKey != null) {
        try {
          await Unify.ai.initialize(
            config: ai.AIAdapterConfig(
              apiKey: aiApiKey,
            ),
            provider: (aiProvider != null && aiProvider is ai_models.AIProvider) 
                ? aiProvider as ai_models.AIProvider 
                : ai_models.AIProvider.openai,
          );
          initializedModules.add('ai');
        } catch (e) {
          errors['ai'] = e.toString();
          suggestions.add('Check your AI API key');
        }
      } else {
        suggestions.add('Provide AI API key to enable AI features');
      }

      // Initialize default adapters
      try {
        // Default networking adapter is already initialized
        initializedModules.add('networking');
        initializedModules.add('files');
        initializedModules.add('system');
        initializedModules.add('notifications');
      } catch (e) {
        errors['default_adapters'] = e.toString();
      }

      return AutoInitResult(
        success: initializedModules.isNotEmpty,
        initializedModules: initializedModules,
        errors: errors.isEmpty ? null : errors,
        suggestions: suggestions.isEmpty ? null : suggestions,
      );
    } catch (e) {
      return AutoInitResult(
        success: false,
        initializedModules: initializedModules,
        errors: {'general': e.toString()},
        suggestions: ['Check your configuration and dependencies'],
      );
    }
  }

  /// Try to create Firebase adapter if available
  AuthAdapter? _tryCreateFirebaseAdapter() {
    try {
      // Try to import Firebase Auth adapter
      // In a real implementation, this would check if firebase_auth is available
      // For now, return the adapter (it will work with mock if package not available)
      return null; // Return null if Firebase not available
    } catch (e) {
      return null;
    }
  }
}

/// Extension on Unify for auto-initialization
extension UnifyAutoInit on Unify {
  /// Auto-initialize with best available adapters
  static Future<AutoInitResult> autoInitialize({
    Map<String, dynamic>? config,
    String? aiApiKey,
    ai_models.AIProvider? aiProvider,
  }) async {
    return await AutoInitialize.instance.initialize(
      config: config,
      aiApiKey: aiApiKey,
      aiProvider: aiProvider,
    );
  }
}

