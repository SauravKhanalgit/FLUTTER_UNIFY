/// Feature flag registry for staged rollout of upcoming capabilities.
///
/// This allows enabling experimental systems (bridge, ai_cli, offline_networking)
/// without breaking existing stable API surfaces.
class UnifyFeatures {
  UnifyFeatures._();
  static final UnifyFeatures instance = UnifyFeatures._();

  final Map<String, bool> _flags = {
    // Networking
    'offline_networking': false,
    'edge_routing': false,
    'graphQL_client': false,

    // AI & DX
    'ai_cli': false,
    'ai_adapter_recommendations': false,

    // Bridging
    'native_bridge_v2': false,
    'hybrid_surface_embedding': false,

    // Background
    'universal_scheduler': false,

    // Media / AR
    'ar_hooks': false,
    'ml_media_pipeline': false,
    'media_core': false, // unified media (camera/mic/gallery/screen)

    // Security
    'anomaly_detection': false,
    'encryption_envelopes': false,
    'token_rotation': false,
    'privacy_toolkit': false,

    // Analytics / flags
    'dynamic_feature_flags': false,

    // Developer Ergonomics
    'dev_dashboards': false,
    'scenario_scripting': false,
    'multi_platform_test_harness': false,
  };

  bool isEnabled(String key) => _flags[key] == true;
  void enable(String key) => _flags[key] = true;
  void disable(String key) => _flags[key] = false;
  Map<String, bool> all() => Map.unmodifiable(_flags);
}
