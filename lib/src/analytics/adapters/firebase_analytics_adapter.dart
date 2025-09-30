/// Firebase Analytics adapter (skeleton)
import 'package:flutter_unify/src/analytics/analytics_adapter.dart';

class FirebaseAnalyticsAdapter extends AnalyticsAdapter {
  @override
  String get name => 'firebase_analytics';
  @override
  String get version => '0.0.1';

  bool _init = false;

  @override
  Future<bool> initialize() async {
    _init = true; // placeholder (no firebase dependency wired)
    return true;
  }

  void _ensure() {
    if (!_init) throw StateError('FirebaseAnalyticsAdapter not initialized');
  }

  @override
  Future<void> logEvent(String name,
      {Map<String, Object?> parameters = const {}}) async {
    _ensure();
  }

  @override
  Future<void> setUserId(String? id) async {
    _ensure();
  }

  @override
  Future<void> setUserProperty(String key, String value) async {
    _ensure();
  }

  @override
  Future<void> flush() async {
    _ensure();
  }

  @override
  Future<void> dispose() async {
    _init = false;
  }
}
