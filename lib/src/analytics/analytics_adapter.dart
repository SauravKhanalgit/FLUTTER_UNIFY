/// Analytics adapter abstraction and registry.
///
/// Roadmap alignment:
/// - Pluggable analytics backends (Firebase, Supabase, Segment, Custom)
/// - Unified event + user property API
/// - Future: automatic enrichment + AI anomaly tagging
library analytics_adapter;

abstract class AnalyticsAdapter {
  String get name;
  String get version;
  Future<bool> initialize();
  Future<void> logEvent(String name, {Map<String, Object?> parameters});
  Future<void> setUserId(String? id);
  Future<void> setUserProperty(String key, String value);
  Future<void> flush();
  Future<void> dispose();
}

/// Basic no-op adapter (default when none registered).
class NoopAnalyticsAdapter extends AnalyticsAdapter {
  @override
  String get name => 'noop';
  @override
  String get version => '0.0.1';
  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<void> logEvent(String name,
      {Map<String, Object?> parameters = const {}}) async {}
  @override
  Future<void> setUserId(String? id) async {}
  @override
  Future<void> setUserProperty(String key, String value) async {}
  @override
  Future<void> flush() async {}
  @override
  Future<void> dispose() async {}
}

/// Registry + facade.
class UnifiedAnalytics {
  UnifiedAnalytics._();
  static UnifiedAnalytics? _instance;
  static UnifiedAnalytics get instance => _instance ??= UnifiedAnalytics._();

  AnalyticsAdapter _adapter = NoopAnalyticsAdapter();
  bool _initialized = false;

  bool get isInitialized => _initialized;
  String get adapterName => _adapter.name;

  void registerAdapter(AnalyticsAdapter adapter) {
    if (_initialized) {
      // In production might throw or queue for swap
    }
    _adapter = adapter;
  }

  Future<void> initialize([AnalyticsAdapter? adapter]) async {
    if (adapter != null) _adapter = adapter;
    if (_initialized) return;
    await _adapter.initialize();
    _initialized = true;
  }

  Future<void> log(String event, {Map<String, Object?> params = const {}}) =>
      _adapter.logEvent(event, parameters: params);

  Future<void> userId(String? id) => _adapter.setUserId(id);

  Future<void> userProperty(String key, String value) =>
      _adapter.setUserProperty(key, value);

  Future<void> flush() => _adapter.flush();

  Future<void> dispose() async {
    await _adapter.dispose();
    _initialized = false;
  }
}
