import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _messageController = TextEditingController();
  final _chatMessages = <ChatMessage>[];
  bool _isLoading = false;
  String _statusMessage = '';
  AIProvider _selectedProvider = AIProvider.openai;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _chatMessages.add(ChatMessage(
        role: ChatRole.assistant,
        content: 'Hello! I\'m powered by Flutter Unify\'s AI integration. '
            'You can switch between OpenAI, Anthropic, and other AI providers. '
            'Try asking me anything!',
      ));
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Thinking...';
      _chatMessages.add(ChatMessage(
        role: ChatRole.user,
        content: message,
      ));
    });

    _messageController.clear();

    try {
      // Track performance
      final result = await Unify.performance.trackOperation(
        'ai_chat',
        () async {
          // Switch to selected provider
          await Unify.ai.setAdapter(_selectedProvider);

          // Send chat message
          final response = await Unify.ai.chat(message);
          return response;
        },
      );

      setState(() {
        _chatMessages.add(ChatMessage(
          role: ChatRole.assistant,
          content: result.choices.first.message.content,
        ));
        _statusMessage = 'Response received!';
      });

      // Record event
      Unify.dev.recordEvent(DashboardEvent(
        type: EventType.ai,
        title: 'AI Chat Message',
        timestamp: DateTime.now(),
        description: 'User sent message to AI',
        data: {
          'provider': _selectedProvider.name,
          'messageLength': message.length,
          'responseLength': result.choices.first.message.content.length,
        },
        success: true,
      ));

    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          role: ChatRole.assistant,
          content: 'Sorry, I encountered an error: $e\n\n'
              'Make sure you have set your AI API key in the main.dart file.',
        ));
        _statusMessage = 'Error occurred';
      });

      // Record error event
      Unify.dev.recordEvent(DashboardEvent(
        type: EventType.error,
        title: 'AI Chat Error',
        timestamp: DateTime.now(),
        description: 'Error occurred during AI chat',
        data: {'error': e.toString()},
        success: false,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStreaming() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting streaming chat...';
      _chatMessages.add(ChatMessage(
        role: ChatRole.user,
        content: 'Tell me a short story about Flutter development.',
      ));
    });

    String streamingContent = '';

    try {
      await Unify.ai.setAdapter(_selectedProvider);

      await for (final chunk in Unify.ai.streamChat(
        ChatCompletionRequest(
          messages: [ChatMessage(
            role: ChatRole.user,
            content: 'Tell me a short story about Flutter development.',
          )],
        ),
      )) {
        final content = chunk.choices.first.delta?.content ?? '';
        if (content.isNotEmpty) {
          streamingContent += content;
          setState(() {
            // Update the last message (assistant response)
            if (_chatMessages.last.role == ChatRole.assistant) {
              _chatMessages.last = ChatMessage(
                role: ChatRole.assistant,
                content: streamingContent,
              );
            } else {
              _chatMessages.add(ChatMessage(
                role: ChatRole.assistant,
                content: streamingContent,
              ));
            }
          });
        }
      }

      setState(() {
        _statusMessage = 'Streaming complete!';
      });

    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          role: ChatRole.assistant,
          content: 'Streaming failed: $e',
        ));
        _statusMessage = 'Streaming failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testEmbeddings() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating embeddings...';
    });

    try {
      await Unify.ai.setAdapter(_selectedProvider);

      final response = await Unify.ai.embed(
        EmbeddingRequest(
          input: 'Flutter Unify is an amazing framework for cross-platform development.',
        ),
      );

      final embedding = response.data.first.embedding;
      final dimensions = embedding.length;

      setState(() {
        _chatMessages.add(ChatMessage(
          role: ChatRole.user,
          content: 'Generate embeddings for: "Flutter Unify is amazing"',
        ));
        _chatMessages.add(ChatMessage(
          role: ChatRole.assistant,
          content: 'Generated embedding with $dimensions dimensions. '
              'First 5 values: ${embedding.take(5).map((v) => v.toStringAsFixed(3)).join(', ')}',
        ));
        _statusMessage = 'Embeddings generated!';
      });

    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          role: ChatRole.assistant,
          content: 'Embeddings failed: $e',
        ));
        _statusMessage = 'Embeddings failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearChat() {
    setState(() {
      _chatMessages.clear();
      _addWelcomeMessage();
      _statusMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Provider Selection
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Provider',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<AIProvider>(
                value: _selectedProvider,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProvider = value;
                    });
                  }
                },
                items: AIProvider.values.map((provider) {
                  return DropdownMenuItem(
                    value: provider,
                    child: Text(provider.name.toUpperCase()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _statusMessage.contains('Error') || _statusMessage.contains('failed')
                      ? Colors.red
                      : Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testStreaming,
                  child: const Text('Test Streaming'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testEmbeddings,
                  child: const Text('Test Embeddings'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearChat,
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Chat',
              ),
            ],
          ),
        ),

        // Chat Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              final isUser = message.role == ChatRole.user;

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ask me anything...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                tooltip: 'Send Message',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

