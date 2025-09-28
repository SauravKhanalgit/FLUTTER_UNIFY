/// Storage-related models for unified files system
///
/// This file contains all the data models used by the unified files system
/// including file information, upload/download progress, and storage statistics.

import 'dart:typed_data';

/// Represents a unified file across all platforms
class UnifiedFile {
  /// Unique identifier for the file
  final String id;

  /// File name with extension
  final String name;

  /// File path (if available)
  final String? path;

  /// File size in bytes
  final int size;

  /// File bytes
  final Uint8List bytes;

  /// MIME type of the file
  final String? mimeType;

  /// File extension (without dot)
  final String? extension;

  /// Last modified date
  final DateTime? lastModified;

  /// Whether this is a directory
  final bool isDirectory;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const UnifiedFile({
    required this.id,
    required this.name,
    this.path,
    required this.size,
    required this.bytes,
    this.mimeType,
    this.extension,
    this.lastModified,
    this.isDirectory = false,
    this.metadata,
  });

  /// Create from platform-specific file
  factory UnifiedFile.fromPlatform({
    required String id,
    required String name,
    String? path,
    required int size,
    required Uint8List bytes,
    String? mimeType,
    DateTime? lastModified,
    bool isDirectory = false,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedFile(
      id: id,
      name: name,
      path: path,
      size: size,
      bytes: bytes,
      mimeType: mimeType,
      extension: _extractExtension(name),
      lastModified: lastModified,
      isDirectory: isDirectory,
      metadata: metadata,
    );
  }

  /// Extract file extension from name
  static String? _extractExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return null;
  }

  /// Check if file is an image
  bool get isImage {
    if (mimeType != null) {
      return mimeType!.startsWith('image/');
    }
    if (extension != null) {
      return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg']
          .contains(extension);
    }
    return false;
  }

  /// Check if file is a video
  bool get isVideo {
    if (mimeType != null) {
      return mimeType!.startsWith('video/');
    }
    if (extension != null) {
      return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(extension);
    }
    return false;
  }

  /// Check if file is audio
  bool get isAudio {
    if (mimeType != null) {
      return mimeType!.startsWith('audio/');
    }
    if (extension != null) {
      return ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].contains(extension);
    }
    return false;
  }

  /// Check if file is a document
  bool get isDocument {
    if (extension != null) {
      return ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'].contains(extension);
    }
    return false;
  }

  /// Get human-readable file size
  String get sizeString {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() =>
      'UnifiedFile(name: $name, size: $sizeString, type: $mimeType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedFile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// File information structure
class FileInfo {
  /// File path
  final String path;

  /// File/directory name
  final String name;

  /// File size in bytes (0 for directories)
  final int size;

  /// Whether this is a directory
  final bool isDirectory;

  /// Last modified date
  final DateTime lastModified;

  /// Last accessed date (if available)
  final DateTime? lastAccessed;

  /// Creation date (if available)
  final DateTime? created;

  /// File permissions (platform-specific)
  final String? permissions;

  /// File owner (if available)
  final String? owner;

  /// MIME type (if available)
  final String? mimeType;

  const FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.isDirectory,
    required this.lastModified,
    this.lastAccessed,
    this.created,
    this.permissions,
    this.owner,
    this.mimeType,
  });

  /// File extension (without dot)
  String? get extension {
    if (isDirectory) return null;
    final lastDot = name.lastIndexOf('.');
    if (lastDot != -1 && lastDot < name.length - 1) {
      return name.substring(lastDot + 1).toLowerCase();
    }
    return null;
  }

  /// Get human-readable file size
  String get sizeString {
    if (isDirectory) return 'Directory';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() =>
      'FileInfo(name: $name, size: $sizeString, isDirectory: $isDirectory)';
}

/// Upload progress information
class UploadProgress {
  /// Unique upload identifier
  final String id;

  /// Name of file being uploaded
  final String fileName;

  /// Total bytes to upload
  final int totalBytes;

  /// Bytes uploaded so far
  final int uploadedBytes;

  /// Upload percentage (0-100)
  final double percentage;

  /// Whether upload is complete
  final bool isComplete;

  /// Upload error (if any)
  final String? error;

  /// Upload speed in bytes/second (if available)
  final double? speed;

  /// Estimated time remaining in seconds (if available)
  final int? remainingTime;

  const UploadProgress({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.percentage,
    required this.isComplete,
    this.error,
    this.speed,
    this.remainingTime,
  });

  /// Whether upload failed
  bool get hasError => error != null;

  /// Whether upload is in progress
  bool get isInProgress => !isComplete && !hasError;

  @override
  String toString() =>
      'UploadProgress($fileName: ${percentage.toStringAsFixed(1)}%)';
}

/// Download progress information
class DownloadProgress {
  /// Unique download identifier
  final String id;

  /// URL being downloaded
  final String url;

  /// Local save path
  final String savePath;

  /// Total bytes to download
  final int totalBytes;

  /// Bytes downloaded so far
  final int downloadedBytes;

  /// Download percentage (0-100)
  final double percentage;

  /// Whether download is complete
  final bool isComplete;

  /// Download error (if any)
  final String? error;

  /// Download speed in bytes/second (if available)
  final double? speed;

  /// Estimated time remaining in seconds (if available)
  final int? remainingTime;

  const DownloadProgress({
    required this.id,
    required this.url,
    required this.savePath,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.percentage,
    required this.isComplete,
    this.error,
    this.speed,
    this.remainingTime,
  });

  /// Whether download failed
  bool get hasError => error != null;

  /// Whether download is in progress
  bool get isInProgress => !isComplete && !hasError;

  @override
  String toString() => 'DownloadProgress(${percentage.toStringAsFixed(1)}%)';
}

/// File change event for file watching
class FileChangeEvent {
  /// Path of the changed file/directory
  final String path;

  /// Type of change
  final FileChangeType type;

  /// Timestamp of the change
  final DateTime timestamp;

  /// Whether the path is a directory
  final bool isDirectory;

  /// Additional event data
  final Map<String, dynamic>? data;

  const FileChangeEvent({
    required this.path,
    required this.type,
    required this.timestamp,
    this.isDirectory = false,
    this.data,
  });

  @override
  String toString() => 'FileChangeEvent($path: $type)';
}

/// Types of file changes
enum FileChangeType {
  /// File/directory was created
  created,

  /// File/directory was modified
  modified,

  /// File/directory was deleted
  deleted,

  /// File/directory was moved/renamed
  moved,
}

/// Storage statistics
class StorageStats {
  /// Total storage space in bytes
  final int totalSpace;

  /// Free storage space in bytes
  final int freeSpace;

  /// Used storage space in bytes
  final int usedSpace;

  const StorageStats({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
  });

  /// Usage percentage (0-100)
  double get usagePercentage => (usedSpace / totalSpace) * 100;

  /// Whether storage is nearly full (>90% used)
  bool get isNearlyFull => usagePercentage > 90;

  /// Whether storage is critically low (>95% used)
  bool get isCriticallyLow => usagePercentage > 95;

  /// Get human-readable sizes
  String get totalSpaceString => _formatBytes(totalSpace);
  String get freeSpaceString => _formatBytes(freeSpace);
  String get usedSpaceString => _formatBytes(usedSpace);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes < 1024 * 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)} TB';
  }

  @override
  String toString() =>
      'StorageStats(used: $usedSpaceString, free: $freeSpaceString, total: $totalSpaceString)';
}

/// Image source for picking images
enum ImageSource {
  /// Pick from photo gallery
  gallery,

  /// Take photo with camera
  camera,

  /// Both gallery and camera options
  both,
}

/// File picker mode
enum FilePickerMode {
  /// Single file selection
  single,

  /// Multiple file selection
  multiple,

  /// Directory selection
  directory,
}

/// Storage security level
enum StorageSecurityLevel {
  /// No encryption (plain storage)
  none,

  /// Basic encryption
  basic,

  /// Strong encryption with hardware-backed keys
  strong,

  /// Biometric-protected encryption
  biometric,
}
