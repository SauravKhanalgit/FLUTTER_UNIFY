/// AI-related models for unified AI system
///
/// This file contains all the data models used by the unified AI system
/// including chat messages, completions, embeddings, and vision analysis.

import 'package:meta/meta.dart';

/// Role of a chat message
enum ChatRole {
  system,
  user,
  assistant,
  tool,
}

/// AI provider type
enum AIProvider {
  openai,
  anthropic,
  gemini,
  local,
  custom,
}

/// Chat message model
@immutable
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.name,
    this.toolCallId,
    this.toolCalls,
  });

  final ChatRole role;
  final String content;
  final String? name;
  final String? toolCallId;
  final List<ToolCall>? toolCalls;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        if (name != null) 'name': name,
        if (toolCallId != null) 'tool_call_id': toolCallId,
        if (toolCalls != null)
          'tool_calls': toolCalls!.map((tc) => tc.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: ChatRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ChatRole.user,
      ),
      content: json['content'] as String,
      name: json['name'] as String?,
      toolCallId: json['tool_call_id'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
              .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

/// Tool call for function calling
@immutable
class ToolCall {
  const ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  final String id;
  final String type;
  final FunctionCall function;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': function.toJson(),
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      type: json['type'] as String,
      function: FunctionCall.fromJson(json['function'] as Map<String, dynamic>),
    );
  }
}

/// Function call definition
@immutable
class FunctionCall {
  const FunctionCall({
    required this.name,
    required this.arguments,
  });

  final String name;
  final String arguments;

  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
      };

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      name: json['name'] as String,
      arguments: json['arguments'] as String,
    );
  }
}

/// Chat completion request
class ChatCompletionRequest {
  const ChatCompletionRequest({
    required this.messages,
    this.model,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.frequencyPenalty,
    this.presencePenalty,
    this.stop,
    this.stream = false,
    this.tools,
    this.toolChoice,
  });

  final List<ChatMessage> messages;
  final String? model;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final double? frequencyPenalty;
  final double? presencePenalty;
  final List<String>? stop;
  final bool stream;
  final List<AITool>? tools;
  final String? toolChoice;
}

/// AI Tool definition
@immutable
class AITool {
  const AITool({
    required this.type,
    required this.function,
  });

  final String type;
  final ToolFunction function;

  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function.toJson(),
      };
}

/// Tool function definition
@immutable
class ToolFunction {
  const ToolFunction({
    required this.name,
    required this.description,
    this.parameters,
  });

  final String name;
  final String description;
  final Map<String, dynamic>? parameters;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (parameters != null) 'parameters': parameters,
      };
}

/// Chat completion response
class ChatCompletionResponse {
  const ChatCompletionResponse({
    required this.id,
    required this.choices,
    required this.model,
    this.usage,
    this.systemFingerprint,
    this.created,
  });

  final String id;
  final List<ChatChoice> choices;
  final String model;
  final Usage? usage;
  final String? systemFingerprint;
  final int? created;

  /// Get the first message content
  String? get content => choices.isNotEmpty ? choices.first.message.content : null;

  /// Get the first message
  ChatMessage? get message =>
      choices.isNotEmpty ? choices.first.message : null;

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id'] as String,
      choices: (json['choices'] as List)
          .map((c) => ChatChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      model: json['model'] as String,
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      systemFingerprint: json['system_fingerprint'] as String?,
      created: json['created'] as int?,
    );
  }
}

/// Chat choice
@immutable
class ChatChoice {
  const ChatChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  final int index;
  final ChatMessage message;
  final String? finishReason;

  factory ChatChoice.fromJson(Map<String, dynamic> json) {
    return ChatChoice(
      index: json['index'] as int,
      message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

/// Token usage information
@immutable
class Usage {
  const Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
    );
  }
}

/// Embedding request
class EmbeddingRequest {
  const EmbeddingRequest({
    required this.input,
    this.model,
    this.dimensions,
    this.encodingFormat,
  });

  final dynamic input; // String or List<String>
  final String? model;
  final int? dimensions;
  final String? encodingFormat;
}

/// Embedding response
class EmbeddingResponse {
  const EmbeddingResponse({
    required this.data,
    required this.model,
    this.usage,
  });

  final List<EmbeddingData> data;
  final String model;
  final Usage? usage;

  factory EmbeddingResponse.fromJson(Map<String, dynamic> json) {
    return EmbeddingResponse(
      data: (json['data'] as List)
          .map((d) => EmbeddingData.fromJson(d as Map<String, dynamic>))
          .toList(),
      model: json['model'] as String,
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Embedding data
@immutable
class EmbeddingData {
  const EmbeddingData({
    required this.embedding,
    required this.index,
    this.object,
  });

  final List<double> embedding;
  final int index;
  final String? object;

  factory EmbeddingData.fromJson(Map<String, dynamic> json) {
    return EmbeddingData(
      embedding: (json['embedding'] as List).map((e) => (e as num).toDouble()).toList(),
      index: json['index'] as int,
      object: json['object'] as String?,
    );
  }
}

/// Vision analysis request
class VisionAnalysisRequest {
  const VisionAnalysisRequest({
    required this.imageUrl,
    this.prompt,
    this.maxTokens,
    this.temperature,
    this.model,
  });

  final String imageUrl;
  final String? prompt;
  final int? maxTokens;
  final double? temperature;
  final String? model;
}

/// Vision analysis response
class VisionAnalysisResponse {
  const VisionAnalysisResponse({
    required this.description,
    this.objects,
    this.text,
    this.confidence,
  });

  final String description;
  final List<String>? objects;
  final String? text;
  final double? confidence;
}

/// AI error
class AIError implements Exception {
  const AIError({
    required this.message,
    this.code,
    this.type,
    this.param,
  });

  final String message;
  final String? code;
  final String? type;
  final String? param;

  @override
  String toString() => 'AIError: $message${code != null ? ' (code: $code)' : ''}';
}

