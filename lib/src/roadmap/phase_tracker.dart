/// Phase Tracker: computes progress across roadmap phases.
///
/// Heuristic: derives completion from feature flags / initialized subsystems.
/// Not persistent; lightweight runtime snapshot.
import '../feature_flags/feature_flags.dart';
import '../analytics/analytics_adapter.dart';

enum PhaseId { phase1, phase2, phase3, phase4, phase5 }

class PhaseStatus {
  final PhaseId id;
  final String label;
  final List<PhaseItem> items;
  PhaseStatus(this.id, this.label, this.items);
  double get completionRatio =>
      items.isEmpty ? 0 : items.where((i) => i.done).length / items.length;
  int get completedCount => items.where((i) => i.done).length;
  int get totalCount => items.length;
  Map<String, dynamic> toJson() => {
        'id': id.name,
        'label': label,
        'completed': completedCount,
        'total': totalCount,
        'ratio': completionRatio,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class PhaseItem {
  final String key;
  final bool done;
  final String description;
  PhaseItem(this.key, this.done, this.description);
  Map<String, dynamic> toJson() => {
        'key': key,
        'done': done,
        'description': description,
      };
}

class PhaseTracker {
  PhaseTracker._();
  static PhaseTracker? _instance;
  static PhaseTracker get instance => _instance ??= PhaseTracker._();

  PhaseStatus snapshotPhase(PhaseId id, {AnalyticsAdapter? analyticsAdapter}) {
    final f = UnifyFeatures.instance;
    switch (id) {
      case PhaseId.phase1:
        return PhaseStatus(id, 'Phase 1: Foundations', [
          PhaseItem('ai_cli', f.isEnabled('ai_cli'), 'AI CLI'),
          PhaseItem('offline_networking', f.isEnabled('offline_networking'),
              'Offline networking'),
          PhaseItem('roadmap_publication', true, 'Roadmap publication'),
        ]);
      case PhaseId.phase2:
        return PhaseStatus(id, 'Phase 2: Bridging + Background', [
          PhaseItem('native_bridge_v2', f.isEnabled('native_bridge_v2'),
              'Native bridging layer'),
          PhaseItem('universal_scheduler', f.isEnabled('universal_scheduler'),
              'Background scheduler'),
        ]);
      case PhaseId.phase3:
        final analyticsReady = (analyticsAdapter?.name ?? 'noop') != 'noop';
        return PhaseStatus(id, 'Phase 3: Immersive + Analytics', [
          PhaseItem('ar_hooks', f.isEnabled('ar_hooks'), 'AR/VR hooks'),
          PhaseItem('ml_media_pipeline', f.isEnabled('ml_media_pipeline'),
              'ML media pipelines'),
          PhaseItem('analytics_adapters', analyticsReady,
              'Analytics adapters (non-noop)'),
        ]);
      case PhaseId.phase4:
        return PhaseStatus(id, 'Phase 4: Edge + Experimentation', [
          PhaseItem('webgpu_probe', true,
              'WebGPU/WASM probe (heuristic placeholder)'),
          PhaseItem(
              'edge_routing', f.isEnabled('edge_routing'), 'Edge routing'),
          PhaseItem(
              'dynamic_feature_flags',
              f.isEnabled('dynamic_feature_flags'),
              'Experimentation framework'),
        ]);
      case PhaseId.phase5:
        return PhaseStatus(id, 'Phase 5: Security + Legacy Hybrid', [
          PhaseItem('encryption_envelopes', f.isEnabled('encryption_envelopes'),
              'Encryption envelopes'),
          PhaseItem('anomaly_detection', f.isEnabled('anomaly_detection'),
              'Anomaly detection'),
          PhaseItem('privacy_toolkit', f.isEnabled('privacy_toolkit'),
              'Privacy toolkit'),
          PhaseItem('token_rotation', f.isEnabled('token_rotation'),
              'Token rotation'),
          PhaseItem(
              'hybrid_surface_embedding',
              f.isEnabled('hybrid_surface_embedding'),
              'Hybrid embedding maturity'),
        ]);
    }
  }

  List<PhaseStatus> snapshotAll({AnalyticsAdapter? analyticsAdapter}) =>
      PhaseId.values
          .map((p) => snapshotPhase(p, analyticsAdapter: analyticsAdapter))
          .toList();
}
