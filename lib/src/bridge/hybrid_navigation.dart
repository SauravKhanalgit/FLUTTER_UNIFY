/// Hybrid navigation facade.
///
/// Goal: Allow host (native) and Flutter pages to interoperate seamlessly.
/// This initial skeleton provides a unified API surface to later plug real
/// platform channel / JS / desktop IPC implementations.
///
/// Roadmap features (future phases):
/// - Native container detection & capability reporting
/// - Automatic route mapping (generated bindings)
/// - Result passing & lifecycle hooks
/// - Transition / gesture parity between native & Flutter stacks
///
/// Current status: Stub that simulates success and records attempted routes.
import 'dart:async';

class HybridNavigationResult {
  final bool succeeded;
  final bool usedNative;
  final String route;
  final Map<String, dynamic>? params;
  final String? message;
  HybridNavigationResult({
    required this.succeeded,
    required this.usedNative,
    required this.route,
    this.params,
    this.message,
  });
}

class HybridNavigator {
  HybridNavigator._();
  static HybridNavigator? _instance;
  static HybridNavigator get instance => _instance ??= HybridNavigator._();

  final StreamController<HybridNavigationResult> _events =
      StreamController.broadcast();
  final List<HybridNavigationResult> _history = [];

  Stream<HybridNavigationResult> get events => _events.stream;
  List<HybridNavigationResult> get history => List.unmodifiable(_history);

  /// Core API: attempt to push a native page if available, else Flutter route.
  ///
  /// For now this just returns a simulated success. Future implementation will:
  /// - Query registered native modules / platform channels for route support
  /// - Defer to Flutter Navigator when native not available or preferNative=false
  /// - Provide result channel for popped pages
  Future<HybridNavigationResult> pushNativeOrFlutter(
    String route, {
    Map<String, dynamic>? params,
    bool preferNative = true,
  }) async {
    // Simulated decision model.
    final usedNative = preferNative; // placeholder
    final result = HybridNavigationResult(
      succeeded: true,
      usedNative: usedNative,
      route: route,
      params: params,
      message: usedNative
          ? 'Simulated native route dispatch'
          : 'Simulated Flutter route dispatch',
    );
    _history.add(result);
    _events.add(result);
    return result;
  }

  Future<void> dispose() async {
    await _events.close();
    _history.clear();
  }
}
