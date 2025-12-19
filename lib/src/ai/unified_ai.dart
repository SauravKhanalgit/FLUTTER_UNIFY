/// Unified AI module
///
/// Provides a single, consistent API for all AI operations across
/// different providers. Automatically handles fallback and provider selection.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'adapters/ai_adapter.dart';
import 'adapters/openai_adapter.dart';
import 'adapters/anthropic_adapter.dart';
import 'models/ai_models.dart';

/// Unified AI interface
class UnifiedAI {
  UnifiedAI._();
  static UnifiedAI? _instance;
  static UnifiedAI get instance => _instance ??= UnifiedAI._();

  AIAdapter? _primaryAdapter;
  final List<AIAdapter> _fallbackAdapters = [];
  bool _initialized = false;

  /// Initialize with primary adapter
  Future<bool> initialize({
    AIAdapter? adapter,
    AIAdapterConfig? config,
    AIProvider? provider,
  }) async {
    if (_initialized) return true;

    try {
      if (adapter != null) {
        _primaryAdapter = adapter;
      } else if (config != null) {
        switch (provider ?? AIProvider.openai) {
          case AIProvider.openai:
            _primaryAdapter = OpenAIAdapter(config: config);
            break;
          case AIProvider.anthropic:
            _primaryAdapter = AnthropicAdapter(config: config);
            break;
          default:
            throw ArgumentError('Unsupported provider: $provider');
        }
      } else {
        throw ArgumentError('Either adapter or config must be provided');
      }

      final success = await _primaryAdapter!.initialize();
      if (success) {
        _initialized = true;
        if (kDebugMode) {
          print('UnifiedAI: Initialized with ${_primaryAdapter!.name}');
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedAI: Initialization failed: $e');
      }
      return false;
    }
  }

  /// Add fallback adapter
  void addFallback(AIAdapter adapter) {
    _fallbackAdapters.add(adapter);
  }

  /// Set primary adapter
  void setAdapter(AIAdapter adapter) {
    _primaryAdapter = adapter;
  }

  /// Get current adapter
  AIAdapter? get currentAdapter => _primaryAdapter;

  /// Chat completion with automatic fallback
  Future<ChatCompletionResponse> chatCompletion(
    ChatCompletionRequest request,
  ) async {
    _ensureInitialized();

    try {
      return await _primaryAdapter!.chatCompletion(request);
    } catch (e) {
      // Try fallback adapters
      for (final adapter in _fallbackAdapters) {
        try {
          if (!adapter.supportsStreaming && request.stream) continue;
          return await adapter.chatCompletion(request);
        } catch (_) {
          continue;
        }
      }
      rethrow;
    }
  }

  /// Stream chat completion
  Stream<ChatCompletionResponse> streamChatCompletion(
    ChatCompletionRequest request,
  ) {
    _ensureInitialized();

    if (!_primaryAdapter!.supportsStreaming) {
      throw StateError('Current adapter does not support streaming');
    }

    try {
      return _primaryAdapter!.streamChatCompletion(request);
    } catch (e) {
      // Try fallback adapters that support streaming
      for (final adapter in _fallbackAdapters) {
        if (!adapter.supportsStreaming) continue;
        try {
          return adapter.streamChatCompletion(request);
        } catch (_) {
          continue;
        }
      }
      throw e;
    }
  }

  /// Create embeddings
  Future<EmbeddingResponse> createEmbedding(EmbeddingRequest request) async {
    _ensureInitialized();

    if (!_primaryAdapter!.supportsEmbeddings) {
      // Try to find an adapter that supports embeddings
      for (final adapter in _fallbackAdapters) {
        if (adapter.supportsEmbeddings) {
          return await adapter.createEmbedding(request);
        }
      }
      throw StateError('No adapter available that supports embeddings');
    }

    try {
      return await _primaryAdapter!.createEmbedding(request);
    } catch (e) {
      // Try fallback adapters
      for (final adapter in _fallbackAdapters) {
        if (!adapter.supportsEmbeddings) continue;
        try {
          return await adapter.createEmbedding(request);
        } catch (_) {
          continue;
        }
      }
      rethrow;
    }
  }

  /// Analyze vision/image
  Future<VisionAnalysisResponse> analyzeVision(
    VisionAnalysisRequest request,
  ) async {
    _ensureInitialized();

    if (!_primaryAdapter!.supportsVision) {
      // Try to find an adapter that supports vision
      for (final adapter in _fallbackAdapters) {
        if (adapter.supportsVision) {
          return await adapter.analyzeVision(request);
        }
      }
      throw StateError('No adapter available that supports vision');
    }

    try {
      return await _primaryAdapter!.analyzeVision(request);
    } catch (e) {
      // Try fallback adapters
      for (final adapter in _fallbackAdapters) {
        if (!adapter.supportsVision) continue;
        try {
          return await adapter.analyzeVision(request);
        } catch (_) {
          continue;
        }
      }
      rethrow;
    }
  }

  /// Quick chat helper
  Future<String> chat(String message, {String? systemPrompt}) async {
    final response = await chatCompletion(
      ChatCompletionRequest(
        messages: [
          if (systemPrompt != null)
            ChatMessage(role: ChatRole.system, content: systemPrompt),
          ChatMessage(role: ChatRole.user, content: message),
        ],
      ),
    );
    return response.content ?? '';
  }

  /// Stream chat helper
  Stream<String> streamChat(String message, {String? systemPrompt}) async* {
    yield* streamChatCompletion(
      ChatCompletionRequest(
        messages: [
          if (systemPrompt != null)
            ChatMessage(role: ChatRole.system, content: systemPrompt),
          ChatMessage(role: ChatRole.user, content: message),
        ],
      ),
    ).map((response) => response.content ?? '');
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Get available models
  List<String> getAvailableModels() {
    _ensureInitialized();
    return _primaryAdapter!.getAvailableModels();
  }

  /// Check capabilities
  bool get supportsStreaming =>
      _primaryAdapter?.supportsStreaming ?? false;
  bool get supportsEmbeddings =>
      _primaryAdapter?.supportsEmbeddings ?? false;
  bool get supportsVision => _primaryAdapter?.supportsVision ?? false;
  bool get supportsFunctionCalling =>
      _primaryAdapter?.supportsFunctionCalling ?? false;

  void _ensureInitialized() {
    if (!_initialized || _primaryAdapter == null) {
      throw StateError(
        'UnifiedAI not initialized. Call UnifiedAI.instance.initialize() first.',
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _primaryAdapter?.dispose();
    for (final adapter in _fallbackAdapters) {
      await adapter.dispose();
    }
    _primaryAdapter = null;
    _fallbackAdapters.clear();
    _initialized = false;
  }
}

