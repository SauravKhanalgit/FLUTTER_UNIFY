/// Anomaly detection (auth + traffic patterns) - skeleton
import 'dart:math';

class AnomalyEvent {
  final String id;
  final String type; // auth_bruteforce | traffic_spike | token_abuse
  final double score; // 0..1
  final Map<String, dynamic>? context;
  final DateTime ts = DateTime.now();
  AnomalyEvent(this.id, this.type, this.score, {this.context});
}

class AnomalyDetector {
  AnomalyDetector._();
  static AnomalyDetector? _instance;
  static AnomalyDetector get instance => _instance ??= AnomalyDetector._();

  final List<AnomalyEvent> _events = [];
  double threshold = 0.75;

  AnomalyEvent register(String type, {Map<String, dynamic>? context}) {
    final score = _score(type, context: context);
    final evt = AnomalyEvent(
        'an_${DateTime.now().millisecondsSinceEpoch}', type, score,
        context: context);
    if (score >= threshold) {
      _events.add(evt);
    }
    return evt;
  }

  List<AnomalyEvent> recent({int limit = 50}) =>
      _events.reversed.take(limit).toList();

  double _score(String type, {Map<String, dynamic>? context}) {
    // Placeholder heuristic
    final base = {
          'auth_bruteforce': 0.9,
          'traffic_spike': 0.8,
          'token_abuse': 0.85,
        }[type] ??
        0.5;
    return (base + Random().nextDouble() * 0.1).clamp(0.0, 1.0);
  }
}
