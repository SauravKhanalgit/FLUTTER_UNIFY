# 🤖 Flutter Unify AI Integration - Usage Examples

## Quick Start

### 1. Initialize AI Module

```dart
import 'package:flutter_unify/flutter_unify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Unify framework
  await Unify.initialize();
  
  // Initialize AI with OpenAI
  await Unify.ai.initialize(
    config: AIAdapterConfig(
      apiKey: 'your-openai-api-key',
      defaultModel: 'gpt-3.5-turbo',
    ),
    provider: AIProvider.openai,
  );
  
  runApp(MyApp());
}
```

### 2. Simple Chat

```dart
// Simple chat completion
final response = await Unify.ai.chat('Hello, how are you?');
print(response); // "Hello! I'm doing well, thank you for asking..."

// With system prompt
final response = await Unify.ai.chat(
  'What is Flutter?',
  systemPrompt: 'You are a helpful assistant that explains technical concepts.',
);
```

### 3. Advanced Chat Completion

```dart
final response = await Unify.ai.chatCompletion(
  ChatCompletionRequest(
    messages: [
      ChatMessage(
        role: ChatRole.system,
        content: 'You are a helpful coding assistant.',
      ),
      ChatMessage(
        role: ChatRole.user,
        content: 'How do I implement authentication in Flutter?',
      ),
    ],
    model: 'gpt-4',
    temperature: 0.7,
    maxTokens: 500,
  ),
);

print(response.content);
```

### 4. Streaming Responses

```dart
// Stream chat for real-time responses
await for (final chunk in Unify.ai.streamChat('Tell me a story')) {
  print(chunk); // Prints chunks as they arrive
}
```

### 5. Multi-Provider Setup with Fallback

```dart
// Initialize primary provider (OpenAI)
await Unify.ai.initialize(
  config: AIAdapterConfig(apiKey: 'openai-key'),
  provider: AIProvider.openai,
);

// Add fallback provider (Anthropic)
final anthropicAdapter = AnthropicAdapter(
  config: AIAdapterConfig(apiKey: 'anthropic-key'),
);
await anthropicAdapter.initialize();
Unify.ai.addFallback(anthropicAdapter);

// Now requests will automatically fallback if OpenAI fails
final response = await Unify.ai.chat('Hello!');
```

### 6. Embeddings

```dart
// Create embeddings for text
final embedding = await Unify.ai.createEmbedding(
  EmbeddingRequest(
    input: 'Flutter is a UI toolkit',
    model: 'text-embedding-3-small',
  ),
);

print(embedding.data.first.embedding); // Vector representation
```

### 7. Vision Analysis

```dart
// Analyze an image
final analysis = await Unify.ai.analyzeVision(
  VisionAnalysisRequest(
    imageUrl: 'https://example.com/image.jpg',
    prompt: 'What objects are in this image?',
  ),
);

print(analysis.description);
```

### 8. Function Calling (Tools)

```dart
final response = await Unify.ai.chatCompletion(
  ChatCompletionRequest(
    messages: [
      ChatMessage(
        role: ChatRole.user,
        content: 'What is the weather in San Francisco?',
      ),
    ],
    tools: [
      AITool(
        type: 'function',
        function: ToolFunction(
          name: 'get_weather',
          description: 'Get the current weather for a location',
          parameters: {
            'type': 'object',
            'properties': {
              'location': {
                'type': 'string',
                'description': 'The city and state, e.g. San Francisco, CA',
              },
            },
            'required': ['location'],
          },
        ),
      ),
    ],
  ),
);

// Check if AI wants to call a function
if (response.choices.first.message.toolCalls != null) {
  // Execute function and send result back
}
```

## Provider-Specific Examples

### OpenAI

```dart
final openaiAdapter = OpenAIAdapter(
  config: AIAdapterConfig(
    apiKey: 'sk-...',
    organizationId: 'org-...', // Optional
  ),
);

await openaiAdapter.initialize();
Unify.ai.setAdapter(openaiAdapter);
```

### Anthropic Claude

```dart
final claudeAdapter = AnthropicAdapter(
  config: AIAdapterConfig(
    apiKey: 'sk-ant-...',
    defaultModel: 'claude-3-opus-20240229',
  ),
);

await claudeAdapter.initialize();
Unify.ai.setAdapter(claudeAdapter);
```

## Error Handling

```dart
try {
  final response = await Unify.ai.chat('Hello');
} on AIError catch (e) {
  print('AI Error: ${e.message}');
  print('Code: ${e.code}');
  print('Type: ${e.type}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Check Capabilities

```dart
// Check what the current adapter supports
if (Unify.ai.supportsStreaming) {
  // Use streaming
}

if (Unify.ai.supportsEmbeddings) {
  // Use embeddings
}

if (Unify.ai.supportsVision) {
  // Use vision
}

// Get available models
final models = Unify.ai.getAvailableModels();
print('Available models: $models');
```

## Complete Example App

```dart
import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

class AIChatScreen extends StatefulWidget {
  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _controller = TextEditingController();
  final _messages = <String>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    await Unify.ai.initialize(
      config: AIAdapterConfig(
        apiKey: 'your-api-key',
      ),
      provider: AIProvider.openai,
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add('You: ${_controller.text}');
      _loading = true;
    });

    try {
      final response = await Unify.ai.chat(_controller.text);
      setState(() {
        _messages.add('AI: $response');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add('Error: $e');
        _loading = false;
      });
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
              },
            ),
          ),
          if (_loading) LinearProgressIndicator(),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Best Practices

1. **Always initialize AI before use**
   ```dart
   await Unify.ai.initialize(...);
   ```

2. **Use fallback providers for reliability**
   ```dart
   Unify.ai.addFallback(backupAdapter);
   ```

3. **Handle errors gracefully**
   ```dart
   try {
     // AI operation
   } on AIError catch (e) {
     // Handle AI-specific errors
   }
   ```

4. **Check capabilities before using features**
   ```dart
   if (Unify.ai.supportsStreaming) {
     // Use streaming
   }
   ```

5. **Dispose resources when done**
   ```dart
   await Unify.ai.dispose();
   ```

