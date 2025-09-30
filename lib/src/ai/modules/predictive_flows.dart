/// Predictive Flow Engine (behavior-driven adaptive UX) - skeleton
class PredictiveSignal {
  final String type; // navigation | interaction | purchase
  final Map<String, dynamic> data;
  final DateTime ts = DateTime.now();
  PredictiveSignal(this.type, this.data);
}

class PredictedAction {
  final String action; // e.g. show_prompt, preload_screen
  final double confidence;
  PredictedAction(this.action, this.confidence);
}

abstract class Predictor {
  String get name;
  Future<PredictedAction?> infer(List<PredictiveSignal> signals);
}

class MockPredictor implements Predictor {
  @override
  String get name => 'mock_predictor';
  @override
  Future<PredictedAction?> infer(List<PredictiveSignal> signals) async {
    if (signals.isEmpty) return null;
    return PredictedAction('preload_next_screen', 0.78);
  }
}

class PredictiveFlowEngine {
  PredictiveFlowEngine._();
  static PredictiveFlowEngine? _instance;
  static PredictiveFlowEngine get instance =>
      _instance ??= PredictiveFlowEngine._();

  final List<PredictiveSignal> _signals = [];
  final List<Predictor> _predictors = [MockPredictor()];

  void registerPredictor(Predictor p) => _predictors.add(p);
  void addSignal(PredictiveSignal s) => _signals.add(s);

  Future<PredictedAction?> predict() async {
    for (final p in _predictors) {
      final result = await p.infer(_signals);
      if (result != null) return result;
    }
    return null;
  }
}
