/// AI Adapter interface and implementations
///
/// This defines the interface that all AI adapters must implement,
/// allowing for pluggable AI backends like OpenAI, Anthropic, Gemini,
/// and local LLMs.

import 'dart:async';
import '../models/ai_models.dart';

/// Abstract base class for all AI adapters
///
/// This allows the unified AI system to work with different
/// AI providers depending on requirements and availability.
abstract class AIAdapter {
  /// Name of this adapter
  String get name;

  /// Version of this adapter
  String get version;

  /// Provider type
  AIProvider get provider;

  /// Initialize the adapter
  Future<bool> initialize();

  /// Chat completion
  Future<ChatCompletionResponse> chatCompletion(
    ChatCompletionRequest request,
  );

  /// Stream chat completion (for real-time responses)
  Stream<ChatCompletionResponse> streamChatCompletion(
    ChatCompletionRequest request,
  );

  /// Generate embeddings
  Future<EmbeddingResponse> createEmbedding(EmbeddingRequest request);

  /// Analyze image/vision
  Future<VisionAnalysisResponse> analyzeVision(VisionAnalysisRequest request);

  /// Check if adapter supports streaming
  bool get supportsStreaming;

  /// Check if adapter supports embeddings
  bool get supportsEmbeddings;

  /// Check if adapter supports vision
  bool get supportsVision;

  /// Check if adapter supports function calling
  bool get supportsFunctionCalling;

  /// Get available models
  List<String> getAvailableModels();

  /// Dispose resources
  Future<void> dispose();
}

/// AI adapter configuration
class AIAdapterConfig {
  const AIAdapterConfig({
    required this.apiKey,
    this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.defaultModel,
    this.organizationId,
  });

  final String apiKey;
  final String? baseUrl;
  final Duration timeout;
  final int maxRetries;
  final String? defaultModel;
  final String? organizationId;
}

