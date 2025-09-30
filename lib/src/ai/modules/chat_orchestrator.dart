/// Chat Orchestrator (multi-provider routing) - skeleton
class ChatMessage {
  final String role; // user | system | assistant
  final String content;
  ChatMessage(this.role, this.content);
}

abstract class ChatProvider {
  String get name;
  Future<ChatMessage> respond(List<ChatMessage> history);
}

class MockChatProvider implements ChatProvider {
  @override
  String get name => 'mock_chat';
  @override
  Future<ChatMessage> respond(List<ChatMessage> history) async {
    return ChatMessage(
        'assistant', 'Mock response to: ' + history.last.content);
  }
}

class ChatOrchestrator {
  ChatOrchestrator._();
  static ChatOrchestrator? _instance;
  static ChatOrchestrator get instance => _instance ??= ChatOrchestrator._();

  final List<ChatProvider> _providers = [MockChatProvider()];

  void register(ChatProvider provider) => _providers.add(provider);

  Future<ChatMessage> ask(List<ChatMessage> history) async {
    // naive: pick first provider
    return _providers.first.respond(history);
  }
}
