/// Recommendation Engine (skeleton) for AI modules
class RecommendationContext {
  final String userId;
  final Map<String, dynamic> features;
  RecommendationContext(this.userId, this.features);
}

class RecommendationResult {
  final List<Map<String, dynamic>> items;
  final DateTime generatedAt = DateTime.now();
  RecommendationResult(this.items);
}

abstract class Recommender {
  String get name;
  Future<RecommendationResult> generate(RecommendationContext ctx);
}

class MockRecommender implements Recommender {
  @override
  String get name => 'mock_recommender';
  @override
  Future<RecommendationResult> generate(RecommendationContext ctx) async {
    return RecommendationResult([
      {'id': 'item1', 'score': 0.91},
      {'id': 'item2', 'score': 0.84},
    ]);
  }
}

class RecommendationEngine {
  RecommendationEngine._();
  static RecommendationEngine? _instance;
  static RecommendationEngine get instance =>
      _instance ??= RecommendationEngine._();

  final List<Recommender> _recommenders = [MockRecommender()];

  void register(Recommender r) => _recommenders.add(r);

  Future<RecommendationResult> recommend(RecommendationContext ctx) async {
    // For now just aggregate naive outputs
    final items = <Map<String, dynamic>>[];
    for (final r in _recommenders) {
      final res = await r.generate(ctx);
      items.addAll(res.items);
    }
    items.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));
    return RecommendationResult(items);
  }
}
