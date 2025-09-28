import 'dart:async';
import 'package:flutter/foundation.dart';
import '../common/platform_detector.dart';
import '../common/event_emitter.dart';

/// Media types
enum MediaType {
  image,
  video,
  audio,
  document,
  any,
}

/// Media source
enum MediaSource {
  camera,
  gallery,
  files,
  microphone,
  screen,
  window,
  url,
}

/// Media quality settings
enum MediaQuality {
  low,
  medium,
  high,
  max,
}

/// Camera facing direction
enum CameraFacing {
  front,
  back,
  external,
}

/// Media capture result
class MediaResult {
  final bool success;
  final List<MediaFile>? files;
  final String? error;
  final Map<String, dynamic>? metadata;

  const MediaResult({
    required this.success,
    this.files,
    this.error,
    this.metadata,
  });

  factory MediaResult.success(
    List<MediaFile> files, {
    Map<String, dynamic>? metadata,
  }) {
    return MediaResult(
      success: true,
      files: files,
      metadata: metadata,
    );
  }

  factory MediaResult.failure(String error) {
    return MediaResult(
      success: false,
      error: error,
    );
  }
}

/// Media file representation
class MediaFile {
  final String? path;
  final String? name;
  final String? mimeType;
  final int? size;
  final Uint8List? bytes;
  final String? url;
  final int? width;
  final int? height;
  final int? duration;
  final Map<String, dynamic>? metadata;

  const MediaFile({
    this.path,
    this.name,
    this.mimeType,
    this.size,
    this.bytes,
    this.url,
    this.width,
    this.height,
    this.duration,
    this.metadata,
  });

  /// Check if file is an image
  bool get isImage => mimeType?.startsWith('image/') ?? false;

  /// Check if file is a video
  bool get isVideo => mimeType?.startsWith('video/') ?? false;

  /// Check if file is audio
  bool get isAudio => mimeType?.startsWith('audio/') ?? false;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'mimeType': mimeType,
      'size': size,
      'url': url,
      'width': width,
      'height': height,
      'duration': duration,
      'metadata': metadata,
    };
  }
}

/// Camera configuration
class CameraConfig {
  final CameraFacing facing;
  final MediaQuality quality;
  final bool enableFlash;
  final bool enableZoom;
  final double? aspectRatio;
  final int? maxDuration;
  final int? maxFileSize;

  const CameraConfig({
    this.facing = CameraFacing.back,
    this.quality = MediaQuality.high,
    this.enableFlash = true,
    this.enableZoom = true,
    this.aspectRatio,
    this.maxDuration,
    this.maxFileSize,
  });
}

/// Screen capture configuration
class ScreenCaptureConfig {
  final bool includeAudio;
  final bool entireScreen;
  final String? windowId;
  final MediaQuality quality;
  final int? maxDuration;

  const ScreenCaptureConfig({
    this.includeAudio = false,
    this.entireScreen = true,
    this.windowId,
    this.quality = MediaQuality.high,
    this.maxDuration,
  });
}

/// File picker options
class FilePickerOptions {
  final List<MediaType> allowedTypes;
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  final bool withData;
  final bool withReadStream;
  final int? maxFiles;
  final int? maxFileSize;

  const FilePickerOptions({
    this.allowedTypes = const [MediaType.any],
    this.allowedExtensions,
    this.allowMultiple = false,
    this.withData = false,
    this.withReadStream = false,
    this.maxFiles,
    this.maxFileSize,
  });
}

/// Audio recording configuration
class AudioRecordingConfig {
  final MediaQuality quality;
  final int? sampleRate;
  final int? bitRate;
  final int? maxDuration;
  final String? outputFormat;

  const AudioRecordingConfig({
    this.quality = MediaQuality.high,
    this.sampleRate,
    this.bitRate,
    this.maxDuration,
    this.outputFormat,
  });
}

/// Device info
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final bool isAvailable;
  final Map<String, dynamic>? capabilities;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.isAvailable,
    this.capabilities,
  });
}

/// Permission result
class PermissionResult {
  final bool granted;
  final bool permanentlyDenied;
  final String? error;

  const PermissionResult({
    required this.granted,
    this.permanentlyDenied = false,
    this.error,
  });
}

/// Unified media and device access API
class UnifiedMedia extends EventEmitter {
  static UnifiedMedia? _instance;
  static UnifiedMedia get instance => _instance ??= UnifiedMedia._();

  UnifiedMedia._();

  bool _isInitialized = false;
  final Map<String, StreamController> _activeStreams = {};

  /// Initialize media system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (kIsWeb) {
        await _initializeWeb();
      } else if (PlatformDetector.isDesktop) {
        await _initializeDesktop();
      } else if (PlatformDetector.isMobile) {
        await _initializeMobile();
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedMedia: Failed to initialize: $e');
      }
      return false;
    }
  }

  /// Take a photo
  Future<MediaResult> takePhoto([CameraConfig? config]) async {
    try {
      if (!await _requestCameraPermission()) {
        return MediaResult.failure('Camera permission denied');
      }

      if (kIsWeb) {
        return await _takePhotoWeb(config);
      } else if (PlatformDetector.isDesktop) {
        return await _takePhotoDesktop(config);
      } else if (PlatformDetector.isMobile) {
        return await _takePhotoMobile(config);
      }

      return MediaResult.failure('Platform not supported');
    } catch (e) {
      return MediaResult.failure(e.toString());
    }
  }

  /// Record video
  Future<MediaResult> recordVideo([CameraConfig? config]) async {
    try {
      if (!await _requestCameraPermission()) {
        return MediaResult.failure('Camera permission denied');
      }

      if (kIsWeb) {
        return await _recordVideoWeb(config);
      } else if (PlatformDetector.isDesktop) {
        return await _recordVideoDesktop(config);
      } else if (PlatformDetector.isMobile) {
        return await _recordVideoMobile(config);
      }

      return MediaResult.failure('Platform not supported');
    } catch (e) {
      return MediaResult.failure(e.toString());
    }
  }

  /// Record audio
  Future<MediaResult> recordAudio([AudioRecordingConfig? config]) async {
    try {
      if (!await _requestMicrophonePermission()) {
        return MediaResult.failure('Microphone permission denied');
      }

      if (kIsWeb) {
        return await _recordAudioWeb(config);
      } else if (PlatformDetector.isDesktop) {
        return await _recordAudioDesktop(config);
      } else if (PlatformDetector.isMobile) {
        return await _recordAudioMobile(config);
      }

      return MediaResult.failure('Platform not supported');
    } catch (e) {
      return MediaResult.failure(e.toString());
    }
  }

  /// Capture screen
  Future<MediaResult> captureScreen([ScreenCaptureConfig? config]) async {
    try {
      if (kIsWeb) {
        return await _captureScreenWeb(config);
      } else if (PlatformDetector.isDesktop) {
        return await _captureScreenDesktop(config);
      } else if (PlatformDetector.isMobile) {
        return await _captureScreenMobile(config);
      }

      return MediaResult.failure('Platform not supported');
    } catch (e) {
      return MediaResult.failure(e.toString());
    }
  }

  /// Pick files from device
  Future<MediaResult> pickFiles([FilePickerOptions? options]) async {
    try {
      final opts = options ?? const FilePickerOptions();

      if (kIsWeb) {
        return await _pickFilesWeb(opts);
      } else if (PlatformDetector.isDesktop) {
        return await _pickFilesDesktop(opts);
      } else if (PlatformDetector.isMobile) {
        return await _pickFilesMobile(opts);
      }

      return MediaResult.failure('Platform not supported');
    } catch (e) {
      return MediaResult.failure(e.toString());
    }
  }

  /// Pick images from gallery
  Future<MediaResult> pickFromGallery({
    bool allowMultiple = false,
    MediaQuality quality = MediaQuality.high,
  }) async {
    try {
      if (kIsWeb) {
        return await _pickFromGalleryWeb(allowMultiple, quality);
      } else if (PlatformDetector.isDesktop) {
        return await _pickFromGalleryDesktop(allowMultiple, quality);
      } else if (PlatformDetector.isMobile) {
        return await _pickFromGalleryMobile(allowMultiple, quality);
      }

      return MediaResult.failure('Platform not supported');
    } catch (e) {
      return MediaResult.failure(e.toString());
    }
  }

  /// Get available cameras
  Future<List<DeviceInfo>> getAvailableCameras() async {
    try {
      if (kIsWeb) {
        return await _getAvailableCamerasWeb();
      } else if (PlatformDetector.isDesktop) {
        return await _getAvailableCamerasDesktop();
      } else if (PlatformDetector.isMobile) {
        return await _getAvailableCamerasMobile();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedMedia: Failed to get cameras: $e');
      }
      return [];
    }
  }

  /// Get available microphones
  Future<List<DeviceInfo>> getAvailableMicrophones() async {
    try {
      if (kIsWeb) {
        return await _getAvailableMicrophonesWeb();
      } else if (PlatformDetector.isDesktop) {
        return await _getAvailableMicrophonesDesktop();
      } else if (PlatformDetector.isMobile) {
        return await _getAvailableMicrophonesMobile();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedMedia: Failed to get microphones: $e');
      }
      return [];
    }
  }

  /// Start camera preview stream
  Stream<Uint8List>? startCameraPreview({
    CameraFacing facing = CameraFacing.back,
    MediaQuality quality = MediaQuality.medium,
  }) {
    try {
      final streamId = '${facing.name}_${quality.name}';

      if (_activeStreams.containsKey(streamId)) {
        return _activeStreams[streamId]!.stream.cast<Uint8List>();
      }

      final controller = StreamController<Uint8List>.broadcast();
      _activeStreams[streamId] = controller;

      // Start platform-specific camera preview
      _startCameraPreviewPlatform(facing, quality, controller);

      return controller.stream;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedMedia: Failed to start camera preview: $e');
      }
      return null;
    }
  }

  /// Stop camera preview stream
  Future<void> stopCameraPreview({
    CameraFacing facing = CameraFacing.back,
    MediaQuality quality = MediaQuality.medium,
  }) async {
    final streamId = '${facing.name}_${quality.name}';

    if (_activeStreams.containsKey(streamId)) {
      await _activeStreams[streamId]!.close();
      _activeStreams.remove(streamId);
    }
  }

  /// Check if feature is supported on current platform
  bool isFeatureSupported(String feature) {
    switch (feature.toLowerCase()) {
      case 'camera':
        return kIsWeb ||
            PlatformDetector.isMobile ||
            PlatformDetector.isDesktop;
      case 'microphone':
        return true;
      case 'screen_capture':
        return kIsWeb || PlatformDetector.isDesktop;
      case 'gallery':
        return PlatformDetector.isMobile || PlatformDetector.isDesktop;
      case 'file_picker':
        return true;
      case 'biometrics':
        return PlatformDetector.isMobile;
      default:
        return false;
    }
  }

  /// Request camera permission
  Future<PermissionResult> requestCameraPermission() async {
    return await _requestPermission('camera');
  }

  /// Request microphone permission
  Future<PermissionResult> requestMicrophonePermission() async {
    return await _requestPermission('microphone');
  }

  /// Request storage permission
  Future<PermissionResult> requestStoragePermission() async {
    return await _requestPermission('storage');
  }

  // Internal permission helpers
  Future<bool> _requestCameraPermission() async {
    final result = await requestCameraPermission();
    return result.granted;
  }

  Future<bool> _requestMicrophonePermission() async {
    final result = await requestMicrophonePermission();
    return result.granted;
  }

  Future<PermissionResult> _requestPermission(String permission) async {
    try {
      if (kIsWeb) {
        return await _requestPermissionWeb(permission);
      } else if (PlatformDetector.isDesktop) {
        return await _requestPermissionDesktop(permission);
      } else if (PlatformDetector.isMobile) {
        return await _requestPermissionMobile(permission);
      }

      return const PermissionResult(
          granted: false, error: 'Platform not supported');
    } catch (e) {
      return PermissionResult(granted: false, error: e.toString());
    }
  }

  // Platform-specific initialization
  Future<void> _initializeWeb() async {
    // Initialize web media APIs
  }

  Future<void> _initializeDesktop() async {
    // Initialize desktop media APIs
  }

  Future<void> _initializeMobile() async {
    // Initialize mobile media APIs
  }

  // Platform-specific implementations (stubs)
  Future<MediaResult> _takePhotoWeb(CameraConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _takePhotoDesktop(CameraConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _takePhotoMobile(CameraConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _recordVideoWeb(CameraConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _recordVideoDesktop(CameraConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _recordVideoMobile(CameraConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _recordAudioWeb(AudioRecordingConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _recordAudioDesktop(AudioRecordingConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _recordAudioMobile(AudioRecordingConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _captureScreenWeb(ScreenCaptureConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _captureScreenDesktop(ScreenCaptureConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _captureScreenMobile(ScreenCaptureConfig? config) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _pickFilesWeb(FilePickerOptions options) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _pickFilesDesktop(FilePickerOptions options) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _pickFilesMobile(FilePickerOptions options) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _pickFromGalleryWeb(
      bool allowMultiple, MediaQuality quality) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _pickFromGalleryDesktop(
      bool allowMultiple, MediaQuality quality) async {
    return MediaResult.failure('Not implemented');
  }

  Future<MediaResult> _pickFromGalleryMobile(
      bool allowMultiple, MediaQuality quality) async {
    return MediaResult.failure('Not implemented');
  }

  Future<List<DeviceInfo>> _getAvailableCamerasWeb() async {
    return [];
  }

  Future<List<DeviceInfo>> _getAvailableCamerasDesktop() async {
    return [];
  }

  Future<List<DeviceInfo>> _getAvailableCamerasMobile() async {
    return [];
  }

  Future<List<DeviceInfo>> _getAvailableMicrophonesWeb() async {
    return [];
  }

  Future<List<DeviceInfo>> _getAvailableMicrophonesDesktop() async {
    return [];
  }

  Future<List<DeviceInfo>> _getAvailableMicrophonesMobile() async {
    return [];
  }

  Future<PermissionResult> _requestPermissionWeb(String permission) async {
    return const PermissionResult(granted: false, error: 'Not implemented');
  }

  Future<PermissionResult> _requestPermissionDesktop(String permission) async {
    return const PermissionResult(
        granted: true); // Desktop usually doesn't need explicit permissions
  }

  Future<PermissionResult> _requestPermissionMobile(String permission) async {
    return const PermissionResult(granted: false, error: 'Not implemented');
  }

  void _startCameraPreviewPlatform(
    CameraFacing facing,
    MediaQuality quality,
    StreamController<Uint8List> controller,
  ) {
    // Platform-specific camera preview implementation
  }

  /// Dispose resources
  Future<void> dispose() async {
    for (final controller in _activeStreams.values) {
      await controller.close();
    }
    _activeStreams.clear();
    _isInitialized = false;
  }
}
