/// AI Suggester skeleton.
///
/// Provides placeholder logic for adapter recommendations and boilerplate
/// generation hints. Future integrations may call local AI models or
/// remote APIs.
class AiSuggestion {
  final String title;
  final String rationale;
  final Map<String, dynamic>? meta;
  final double score; // confidence 0-1
  AiSuggestion(this.title, this.rationale, {this.meta, this.score = 0.6});
}

class AiSuggester {
  AiSuggester._();
  static AiSuggester? _instance;
  static AiSuggester get instance => _instance ??= AiSuggester._();

  AiSuggestion suggestAdapter(String domain) {
    switch (domain) {
      case 'network':
        return AiSuggestion(
          'Dio + Offline Layer',
          'Robust interceptors, supports retries; pair with OfflineClient for caching and queueing.',
          meta: {'retry': true, 'graphQLReady': true},
          score: 0.92,
        );
      case 'auth':
        return AiSuggestion(
          'MockAuth + OAuth Adapter Roadmap',
          'Start fast with mock; plan provider adapters for Google/Apple later.',
          meta: {'biometric': true},
          score: 0.88,
        );
      case 'storage':
        return AiSuggestion(
          'Hive + Secure Wrapper',
          'Fast structured storage; add encryption layer for sensitive data.',
          meta: {'encryption': 'planned'},
          score: 0.85,
        );
      default:
        return AiSuggestion(
          'General Strategy',
          'Provide more context (network, auth, storage) for sharper suggestion.',
          score: 0.40,
        );
    }
  }

  List<String> generateRetryBoilerplate() => [
        '// Retry wrapper example',
        'Future<T> withRetry<T>(Future<T> Function() run,{int max=3,Duration delay=const Duration(milliseconds:300)}) async {',
        '  int attempt=0; while(true){',
        '    try { return await run(); } catch(e){ if(attempt++>=max) rethrow; await Future.delayed(delay * (attempt+1)); }',
        '  }',
        '}',
      ];
}
