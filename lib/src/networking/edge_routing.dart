/// Edge routing strategy (skeleton).
///
/// Purpose: Choose the most suitable backend endpoint based on
/// region preference and (future) dynamic latency measurements.
///
/// Roadmap targets:
/// - Active latency probing (HTTP HEAD / lightweight ping)
/// - Health scoring & failover rotation
/// - Per-service endpoint maps
/// - Integration with adapter request pipeline
class EdgeEndpoint {
  final String region; // e.g. 'us-east', 'eu-west'
  final Uri uri;
  final int? lastLatencyMs; // placeholder for metrics
  final bool healthy;
  const EdgeEndpoint({
    required this.region,
    required this.uri,
    this.lastLatencyMs,
    this.healthy = true,
  });

  EdgeEndpoint copyWith({int? lastLatencyMs, bool? healthy}) => EdgeEndpoint(
        region: region,
        uri: uri,
        lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
        healthy: healthy ?? this.healthy,
      );
}

class EdgeRouter {
  EdgeRouter._();
  static EdgeRouter? _instance;
  static EdgeRouter get instance => _instance ??= EdgeRouter._();

  final Map<String, List<EdgeEndpoint>> _serviceMap =
      {}; // service -> endpoints
  String? preferredRegion;

  void registerService(String service, List<EdgeEndpoint> endpoints) {
    _serviceMap[service] = endpoints;
  }

  void clearService(String service) => _serviceMap.remove(service);

  List<EdgeEndpoint> endpointsFor(String service) =>
      List.unmodifiable(_serviceMap[service] ?? const []);

  /// Select an endpoint for a service.
  /// Simple strategy now:
  /// 1. If preferredRegion set & exists & healthy -> choose it.
  /// 2. Otherwise pick first healthy endpoint.
  /// 3. Fallback: first endpoint if none marked healthy.
  EdgeEndpoint? select(String service) {
    final eps = _serviceMap[service];
    if (eps == null || eps.isEmpty) return null;

    if (preferredRegion != null) {
      final match = eps.firstWhere(
        (e) => e.region == preferredRegion && e.healthy,
        orElse: () => eps.first,
      );
      return match;
    }
    final healthy = eps.firstWhere(
      (e) => e.healthy,
      orElse: () => eps.first,
    );
    return healthy;
  }

  /// Build a full URL by replacing only the origin with the selected edge endpoint.
  /// If no mapping exists returns original.
  Uri rewrite(String service, Uri original) {
    final chosen = select(service);
    if (chosen == null) return original;
    // Preserve path/query from original; use scheme+host+port of chosen.
    return chosen.uri.replace(
      path: original.path,
      query: original.query,
      fragment: original.fragment,
    );
  }
}
