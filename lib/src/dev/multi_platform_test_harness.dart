/// Multi-platform test harness (one spec -> multiple targets) - skeleton
class TestSpec {
  final String id;
  final String description;
  final Future<void> Function() body;
  TestSpec({required this.id, required this.description, required this.body});
}

class TestResult {
  final String specId;
  final bool success;
  final String? error;
  final Duration duration;
  final String platform; // web | android | ios | desktop
  TestResult(this.specId, this.success, this.duration, this.platform,
      {this.error});
}

class MultiPlatformTestHarness {
  MultiPlatformTestHarness._();
  static MultiPlatformTestHarness? _instance;
  static MultiPlatformTestHarness get instance =>
      _instance ??= MultiPlatformTestHarness._();

  Future<List<TestResult>> runOnPlatforms(
      List<TestSpec> specs, List<String> platforms) async {
    final results = <TestResult>[];
    for (final platform in platforms) {
      for (final spec in specs) {
        final start = DateTime.now();
        try {
          await spec.body();
          results.add(TestResult(
              spec.id, true, DateTime.now().difference(start), platform));
        } catch (e) {
          results.add(TestResult(
              spec.id, false, DateTime.now().difference(start), platform,
              error: e.toString()));
        }
      }
    }
    return results;
  }
}
