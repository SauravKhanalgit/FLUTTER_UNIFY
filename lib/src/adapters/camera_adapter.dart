import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart' as ip;
import '../models/storage_models.dart';

/// Unified camera/image capture adapter
abstract class CameraAdapter {
  Future<void> initialize();

  /// Pick an image from gallery or camera
  Future<UnifiedFile?> pickImage({bool fromCamera = false});

  /// Pick a video from gallery or camera
  Future<UnifiedFile?> pickVideo(
      {bool fromCamera = false, Duration? maxDuration});
}

class DefaultCameraAdapter implements CameraAdapter {
  final ip.ImagePicker _picker = ip.ImagePicker();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // image_picker does not require explicit init
    _initialized = true;
  }

  @override
  Future<UnifiedFile?> pickImage({bool fromCamera = false}) async {
    final source = fromCamera ? ip.ImageSource.camera : ip.ImageSource.gallery;
    final ip.XFile? file = await _picker.pickImage(source: source);
    if (file == null) return null;
    final Uint8List bytes = await file.readAsBytes();
    return UnifiedFile.fromPlatform(
      id: file.path,
      name: _nameFromPath(file.name.isNotEmpty ? file.name : file.path),
      path: file.path,
      size: bytes.length,
      bytes: bytes,
      mimeType: 'image/${file.path.split('.').last.toLowerCase()}',
      lastModified: DateTime.now(),
    );
  }

  @override
  Future<UnifiedFile?> pickVideo(
      {bool fromCamera = false, Duration? maxDuration}) async {
    final source = fromCamera ? ip.ImageSource.camera : ip.ImageSource.gallery;
    final ip.XFile? file = await _picker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );
    if (file == null) return null;
    final Uint8List bytes = await file.readAsBytes();
    return UnifiedFile.fromPlatform(
      id: file.path,
      name: _nameFromPath(file.name.isNotEmpty ? file.name : file.path),
      path: file.path,
      size: bytes.length,
      bytes: bytes,
      mimeType: 'video/${file.path.split('.').last.toLowerCase()}',
      lastModified: DateTime.now(),
    );
  }

  String _nameFromPath(String path) {
    final idx = path.lastIndexOf('/');
    if (idx == -1) return path;
    return path.substring(idx + 1);
  }
}
