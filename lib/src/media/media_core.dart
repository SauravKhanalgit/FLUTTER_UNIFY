/// Unified Media Core (camera, microphone, gallery, screen capture)
///
/// Goals:
/// - Provide a single abstraction that defers to platform specific
///   implementations lazily via adapters.
/// - Keep initial surface minimal; extend via feature flags.
/// - Non-blocking async acquisition and stream based access.
///
/// Roadmap Phases:
///  - Phase A: Capability descriptors + mock adapter
///  - Phase B: Real platform adapter bindings (camera/mic)
///  - Phase C: Screen capture + gallery + permissions mediation
///  - Phase D: ML pipeline hooks (vision/audio) + filter graph
library media_core;

import 'dart:async';

import 'package:flutter_unify/src/feature_flags/feature_flags.dart';

/// Describes a media capability supported by an adapter.
class MediaCapability {
  final String id; // e.g. camera.front, audio.input
  final String type; // camera | audio | screen | gallery
  final Map<String, dynamic>? metadata; // resolution, fps etc.
  MediaCapability({
    required this.id,
    required this.type,
    this.metadata,
  });
}

/// Abstracts a unified media stream handle (opaque for now).
class MediaStreamHandle {
  final String id;
  final String capabilityId;
  bool _active = true;
  MediaStreamHandle(this.id, this.capabilityId);
  bool get isActive => _active;
  Future<void> stop() async {
    _active = false;
  }
}

/// Base adapter interface for platform media providers.
abstract class MediaAdapter {
  String get name;
  Future<bool> initialize();
  Future<List<MediaCapability>> listCapabilities();
  Future<MediaStreamHandle> open(String capabilityId,
      {Map<String, dynamic>? constraints});
  Future<void> close(MediaStreamHandle handle);
  Future<void> dispose();
}

/// Mock adapter for early experimentation.
class MockMediaAdapter implements MediaAdapter {
  final List<MediaCapability> _caps = [
    MediaCapability(id: 'camera.front', type: 'camera', metadata: {
      'facing': 'front',
      'resolutions': ['720p', '1080p']
    }),
    MediaCapability(
        id: 'camera.back', type: 'camera', metadata: {'facing': 'back'}),
    MediaCapability(
        id: 'audio.input', type: 'audio', metadata: {'channels': 2}),
    MediaCapability(
        id: 'screen.main', type: 'screen', metadata: {'maxFps': 30}),
  ];
  bool _initialized = false;
  @override
  String get name => 'mock_media';
  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<List<MediaCapability>> listCapabilities() async => _caps;
  @override
  Future<MediaStreamHandle> open(String capabilityId,
      {Map<String, dynamic>? constraints}) async {
    if (!_initialized) throw StateError('Media adapter not initialized');
    final cap = _caps.firstWhere((c) => c.id == capabilityId,
        orElse: () => throw ArgumentError('Unknown capability: $capabilityId'));
    // constraints ignored in mock
    return MediaStreamHandle(
        'ms_${DateTime.now().millisecondsSinceEpoch}', cap.id);
  }

  @override
  Future<void> close(MediaStreamHandle handle) async {
    await handle.stop();
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}

/// Unified Media facade.
class UnifiedMedia {
  UnifiedMedia._();
  static UnifiedMedia? _instance;
  static UnifiedMedia get instance => _instance ??= UnifiedMedia._();

  MediaAdapter? _adapter;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  MediaAdapter? get adapter => _adapter;

  Future<void> initialize({MediaAdapter? adapter}) async {
    if (_initialized) return;
    if (!UnifyFeatures.instance.isEnabled('media_core')) {
      throw StateError('media_core feature flag disabled');
    }
    _adapter = adapter ?? MockMediaAdapter();
    await _adapter!.initialize();
    _initialized = true;
  }

  Future<List<MediaCapability>> listCapabilities() async {
    if (!_initialized) throw StateError('UnifiedMedia not initialized');
    return _adapter!.listCapabilities();
  }

  Future<MediaStreamHandle> open(String capabilityId,
      {Map<String, dynamic>? constraints}) async {
    if (!_initialized) throw StateError('UnifiedMedia not initialized');
    return _adapter!.open(capabilityId, constraints: constraints);
  }

  Future<void> close(MediaStreamHandle handle) async {
    if (!_initialized) return;
    await _adapter!.close(handle);
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await _adapter?.dispose();
    _initialized = false;
  }
}
