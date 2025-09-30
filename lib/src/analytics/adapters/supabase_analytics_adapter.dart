/// Supabase Analytics adapter (skeleton)
import 'package:flutter_unify/src/analytics/analytics_adapter.dart';

class SupabaseAnalyticsAdapter extends AnalyticsAdapter {
  @override
  String get name => 'supabase';
  @override
  String get version => '0.0.1';

  bool _init = false;

  @override
  Future<bool> initialize() async {
    _init = true; // placeholder
    return true;
  }

  void _ensure() {
    if (!_init) throw StateError('SupabaseAnalyticsAdapter not initialized');
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
