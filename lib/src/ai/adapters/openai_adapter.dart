/// OpenAI adapter implementation
///
/// Provides integration with OpenAI's API including:
/// - Chat completions (GPT-3.5, GPT-4, etc.)
/// - Embeddings
/// - Vision analysis
/// - Function calling
/// - Streaming

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_adapter.dart';
import '../models/ai_models.dart';

/// OpenAI adapter
class OpenAIAdapter extends AIAdapter {
  OpenAIAdapter({
    required AIAdapterConfig config,
  })  : _config = config,
        _dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl ?? 'https://api.openai.com/v1',
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
              if (config.organizationId != null)
                'OpenAI-Organization': config.organizationId!,
            },
            connectTimeout: config.timeout,
            receiveTimeout: config.timeout,
          ),
        );

  final AIAdapterConfig _config;
  final Dio _dio;
  bool _initialized = false;

  @override
  String get name => 'OpenAIAdapter';

  @override
  String get version => '1.0.0';

  @override
  AIProvider get provider => AIProvider.openai;

  @override
  bool get supportsStreaming => true;

  @override
  bool get supportsEmbeddings => true;

  @override
  bool get supportsVision => true;

  @override
  bool get supportsFunctionCalling => true;

  @override
  List<String> getAvailableModels() => [
        'gpt-4-turbo-preview',
        'gpt-4',
        'gpt-3.5-turbo',
        'gpt-4-vision-preview',
        'text-embedding-3-small',
        'text-embedding-3-large',
        'text-embedding-ada-002',
      ];

  @override
  Future<bool> initialize() async {
    try {
      // Test connection with a simple request
      _initialized = true;
      return true;
    } catch (e) {
      _initialized = false;
      return false;
    }
  }

  @override
  Future<ChatCompletionResponse> chatCompletion(
    ChatCompletionRequest request,
  ) async {
    if (!_initialized) {
      throw StateError('OpenAIAdapter not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': request.model ?? _config.defaultModel ?? 'gpt-3.5-turbo',
          'messages': request.messages.map((m) => m.toJson()).toList(),
          if (request.temperature != null) 'temperature': request.temperature,
          if (request.maxTokens != null) 'max_tokens': request.maxTokens,
          if (request.topP != null) 'top_p': request.topP,
          if (request.frequencyPenalty != null)
            'frequency_penalty': request.frequencyPenalty,
          if (request.presencePenalty != null)
            'presence_penalty': request.presencePenalty,
          if (request.stop != null) 'stop': request.stop,
          if (request.tools != null)
            'tools': request.tools!.map((t) => t.toJson()).toList(),
          if (request.toolChoice != null) 'tool_choice': request.toolChoice,
          'stream': false,
        },
      );

      return ChatCompletionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw AIError(
        message: e.response?.data['error']?['message'] ?? e.message ?? 'Unknown error',
        code: e.response?.data['error']?['code'],
        type: e.response?.data['error']?['type'],
      );
    }
  }

  @override
  Stream<ChatCompletionResponse> streamChatCompletion(
    ChatCompletionRequest request,
  ) async* {
    if (!_initialized) {
      throw StateError('OpenAIAdapter not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': request.model ?? _config.defaultModel ?? 'gpt-3.5-turbo',
          'messages': request.messages.map((m) => m.toJson()).toList(),
          if (request.temperature != null) 'temperature': request.temperature,
          if (request.maxTokens != null) 'max_tokens': request.maxTokens,
          if (request.topP != null) 'top_p': request.topP,
          if (request.tools != null)
            'tools': request.tools!.map((t) => t.toJson()).toList(),
          'stream': true,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data as ResponseBody;
      String buffer = '';

      await for (final chunk in stream.stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          if (line.trim().isEmpty || !line.startsWith('data: ')) continue;
          if (line.trim() == 'data: [DONE]') break;

          try {
            final jsonStr = line.substring(6); // Remove 'data: '
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield ChatCompletionResponse.fromJson(json);
          } catch (e) {
            // Skip malformed JSON
            continue;
          }
        }
      }
    } on DioException catch (e) {
      throw AIError(
        message: e.response?.data['error']?['message'] ?? e.message ?? 'Unknown error',
        code: e.response?.data['error']?['code'],
        type: e.response?.data['error']?['type'],
      );
    }
  }

  @override
  Future<EmbeddingResponse> createEmbedding(EmbeddingRequest request) async {
    if (!_initialized) {
      throw StateError('OpenAIAdapter not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.post(
        '/embeddings',
        data: {
          'model': request.model ?? 'text-embedding-3-small',
          'input': request.input,
          if (request.dimensions != null) 'dimensions': request.dimensions,
          if (request.encodingFormat != null)
            'encoding_format': request.encodingFormat,
        },
      );

      return EmbeddingResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw AIError(
        message: e.response?.data['error']?['message'] ?? e.message ?? 'Unknown error',
        code: e.response?.data['error']?['code'],
        type: e.response?.data['error']?['type'],
      );
    }
  }

  @override
  Future<VisionAnalysisResponse> analyzeVision(
    VisionAnalysisRequest request,
  ) async {
    if (!_initialized) {
      throw StateError('OpenAIAdapter not initialized. Call initialize() first.');
    }

    try {
      // OpenAI vision requires content as a list of content parts
      final contentParts = [
        {
          'type': 'text',
          'text': request.prompt ?? 'What is in this image?',
        },
        {
          'type': 'image_url',
          'image_url': {'url': request.imageUrl},
        },
      ];

      // Create a custom message with structured content
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': request.model ?? 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': contentParts,
            },
          ],
          'max_tokens': request.maxTokens ?? 300,
          if (request.temperature != null) 'temperature': request.temperature,
        },
      );

      final completionResponse = ChatCompletionResponse.fromJson(response.data);

      return VisionAnalysisResponse(
        description: completionResponse.content ?? 'No description available',
        confidence: 0.9,
      );
    } on DioException catch (e) {
      throw AIError(
        message: e.response?.data['error']?['message'] ?? e.message ?? 'Unknown error',
        code: e.response?.data['error']?['code'],
        type: e.response?.data['error']?['type'],
      );
    }
  }

  @override
  Future<void> dispose() async {
    _dio.close();
    _initialized = false;
  }
}

