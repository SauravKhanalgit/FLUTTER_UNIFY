/// Scenario scripting + synthetic telemetry injection - skeleton
import 'dart:async';

class ScenarioStep {
  final String id;
  final String description;
  final Future<void> Function() action;
  ScenarioStep(
      {required this.id, required this.description, required this.action});
}

class ScenarioResult {
  final String id;
  final bool success;
  final String? error;
  final Duration duration;
  ScenarioResult(this.id, this.success, this.duration, {this.error});
}

class Scenario {
  final String id;
  final String name;
  final List<ScenarioStep> steps;
  Scenario({required this.id, required this.name, required this.steps});
}

class ScenarioRunner {
  ScenarioRunner._();
  static ScenarioRunner? _instance;
  static ScenarioRunner get instance => _instance ??= ScenarioRunner._();

  final StreamController<ScenarioResult> _results =
      StreamController.broadcast();
  Stream<ScenarioResult> get results => _results.stream;

  Future<List<ScenarioResult>> run(Scenario scenario) async {
    final results = <ScenarioResult>[];
    for (final step in scenario.steps) {
      final start = DateTime.now();
      try {
        await step.action();
        final dur = DateTime.now().difference(start);
        final res = ScenarioResult(step.id, true, dur);
        _results.add(res);
        results.add(res);
      } catch (e) {
        final dur = DateTime.now().difference(start);
        final res = ScenarioResult(step.id, false, dur, error: e.toString());
        _results.add(res);
        results.add(res);
        break; // stop scenario on failure
      }
    }
    return results;
  }

  Future<void> dispose() async {
    await _results.close();
  }
}
