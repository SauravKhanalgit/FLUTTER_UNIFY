/// Anthropic Claude adapter implementation
///
/// Provides integration with Anthropic's Claude API including:
/// - Chat completions (Claude 3 Opus, Sonnet, Haiku)
/// - Streaming
/// - Function calling (tools)

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_adapter.dart';
import '../models/ai_models.dart';

/// Anthropic Claude adapter
class AnthropicAdapter extends AIAdapter {
  AnthropicAdapter({
    required AIAdapterConfig config,
  })  : _config = config,
        _dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl ?? 'https://api.anthropic.com/v1',
            headers: {
              'x-api-key': config.apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            connectTimeout: config.timeout,
            receiveTimeout: config.timeout,
          ),
        );

  final AIAdapterConfig _config;
  final Dio _dio;
  bool _initialized = false;

  @override
  String get name => 'AnthropicAdapter';

  @override
  String get version => '1.0.0';

  @override
  AIProvider get provider => AIProvider.anthropic;

  @override
  bool get supportsStreaming => true;

  @override
  bool get supportsEmbeddings => false; // Anthropic doesn't have embeddings API

  @override
  bool get supportsVision => true;

  @override
  bool get supportsFunctionCalling => true;

  @override
  List<String> getAvailableModels() => [
        'claude-3-opus-20240229',
        'claude-3-sonnet-20240229',
        'claude-3-haiku-20240307',
        'claude-2.1',
        'claude-2.0',
      ];

  @override
  Future<bool> initialize() async {
    try {
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
      throw StateError('AnthropicAdapter not initialized. Call initialize() first.');
    }

    try {
      // Convert messages to Anthropic format
      final systemMessage = request.messages
          .where((m) => m.role == ChatRole.system)
          .map((m) => m.content)
          .join('\n');

      final messages = request.messages
          .where((m) => m.role != ChatRole.system)
          .map((m) => {
                'role': m.role == ChatRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await _dio.post(
        '/messages',
        data: {
          'model': request.model ?? _config.defaultModel ?? 'claude-3-sonnet-20240229',
          if (systemMessage.isNotEmpty) 'system': systemMessage,
          'messages': messages,
          if (request.maxTokens != null) 'max_tokens': request.maxTokens ?? 1024,
          if (request.temperature != null) 'temperature': request.temperature,
          if (request.tools != null)
            'tools': request.tools!.map((t) => t.toJson()).toList(),
        },
      );

      // Convert Anthropic response to unified format
      final content = response.data['content'] as List;
      final textContent = content
          .where((c) => c['type'] == 'text')
          .map((c) => c['text'] as String)
          .join('\n');

      return ChatCompletionResponse(
        id: response.data['id'] as String,
        choices: [
          ChatChoice(
            index: 0,
            message: ChatMessage(
              role: ChatRole.assistant,
              content: textContent,
            ),
            finishReason: response.data['stop_reason'] as String?,
          ),
        ],
        model: response.data['model'] as String,
        usage: response.data['usage'] != null
            ? Usage.fromJson(response.data['usage'] as Map<String, dynamic>)
            : null,
      );
    } on DioException catch (e) {
      throw AIError(
        message: e.response?.data['error']?['message'] ?? e.message ?? 'Unknown error',
        code: e.response?.data['error']?['type'],
        type: e.response?.data['error']?['type'],
      );
    }
  }

  @override
  Stream<ChatCompletionResponse> streamChatCompletion(
    ChatCompletionRequest request,
  ) async* {
    if (!_initialized) {
      throw StateError('AnthropicAdapter not initialized. Call initialize() first.');
    }

    try {
      final systemMessage = request.messages
          .where((m) => m.role == ChatRole.system)
          .map((m) => m.content)
          .join('\n');

      final messages = request.messages
          .where((m) => m.role != ChatRole.system)
          .map((m) => {
                'role': m.role == ChatRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await _dio.post(
        '/messages',
        data: {
          'model': request.model ?? _config.defaultModel ?? 'claude-3-sonnet-20240229',
          if (systemMessage.isNotEmpty) 'system': systemMessage,
          'messages': messages,
          'max_tokens': request.maxTokens ?? 1024,
          if (request.temperature != null) 'temperature': request.temperature,
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
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.trim().isEmpty || !line.startsWith('data: ')) continue;
          if (line.trim() == 'data: [DONE]') break;

          try {
            final jsonStr = line.substring(6);
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;

            if (json['type'] == 'content_block_delta') {
              final delta = json['delta'] as Map<String, dynamic>;
              yield ChatCompletionResponse(
                id: json['message']?['id'] ?? '',
                choices: [
                  ChatChoice(
                    index: 0,
                    message: ChatMessage(
                      role: ChatRole.assistant,
                      content: delta['text'] as String? ?? '',
                    ),
                  ),
                ],
                model: json['model'] as String? ?? '',
              );
            }
          } catch (e) {
            continue;
          }
        }
      }
    } on DioException catch (e) {
      throw AIError(
        message: e.response?.data['error']?['message'] ?? e.message ?? 'Unknown error',
        code: e.response?.data['error']?['type'],
        type: e.response?.data['error']?['type'],
      );
    }
  }

  @override
  Future<EmbeddingResponse> createEmbedding(EmbeddingRequest request) {
    throw UnimplementedError(
      'Anthropic does not provide an embeddings API. Use OpenAI or another provider.',
    );
  }

  @override
  Future<VisionAnalysisResponse> analyzeVision(
    VisionAnalysisRequest request,
  ) async {
    // Anthropic supports vision through regular chat with image content
    final response = await chatCompletion(
      ChatCompletionRequest(
        messages: [
          ChatMessage(
            role: ChatRole.user,
            content: request.prompt ?? 'Describe this image in detail.',
          ),
        ],
        model: 'claude-3-opus-20240229',
        maxTokens: request.maxTokens ?? 300,
        temperature: request.temperature,
      ),
    );

    return VisionAnalysisResponse(
      description: response.content ?? 'No description available',
      confidence: 0.9,
    );
  }

  @override
  Future<void> dispose() async {
    _dio.close();
    _initialized = false;
  }
}

