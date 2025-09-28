/// 🖥️ System Models
///
/// Data structures for system monitoring and device information.
/// These models provide a unified interface for system state
/// across all platforms.

import 'package:meta/meta.dart';

/// System connectivity state
@immutable
class ConnectivityState {
  const ConnectivityState({
    required this.isConnected,
    required this.connectionType,
    this.networkName,
    this.signalStrength,
    this.bandwidth,
    this.isMetered = false,
    this.isRoaming = false,
    this.timestamp,
  });

  /// Whether device is connected to internet
  final bool isConnected;

  /// Type of network connection
  final ConnectionType connectionType;

  /// Network name (WiFi SSID, cellular carrier, etc.)
  final String? networkName;

  /// Signal strength (0.0 to 1.0)
  final double? signalStrength;

  /// Available bandwidth in bytes per second
  final int? bandwidth;

  /// Whether connection is metered (limited data)
  final bool isMetered;

  /// Whether device is roaming
  final bool isRoaming;

  /// When this state was recorded
  final DateTime? timestamp;

  /// Whether device is offline
  bool get isOffline => !isConnected;

  /// Human-readable connection description
  String get description {
    if (!isConnected) return 'Offline';

    switch (connectionType) {
      case ConnectionType.none:
        return 'No Connection';
      case ConnectionType.wifi:
        return 'WiFi${networkName != null ? ' ($networkName)' : ''}';
      case ConnectionType.cellular:
        return 'Cellular${networkName != null ? ' ($networkName)' : ''}${isRoaming ? ' (Roaming)' : ''}';
      case ConnectionType.ethernet:
        return 'Ethernet';
      case ConnectionType.bluetooth:
        return 'Bluetooth';
      case ConnectionType.vpn:
        return 'VPN';
      case ConnectionType.unknown:
        return 'Connected';
    }
  }

  @override
  String toString() {
    return 'ConnectivityState(isConnected: $isConnected, type: $connectionType, network: $networkName)';
  }
}

/// Network connection types
enum ConnectionType {
  /// No connection
  none,

  /// WiFi connection
  wifi,

  /// Cellular/mobile data
  cellular,

  /// Ethernet (wired)
  ethernet,

  /// Bluetooth connection
  bluetooth,

  /// VPN connection
  vpn,

  /// Unknown connection type
  unknown,
}

/// Battery state information
@immutable
class BatteryState {
  const BatteryState({
    required this.level,
    required this.isCharging,
    this.batteryState = BatteryStatus.unknown,
    this.powerSource,
    this.timeRemaining,
    this.health,
    this.temperature,
    this.voltage,
    this.technology,
    this.timestamp,
  });

  /// Battery level (0.0 to 1.0)
  final double level;

  /// Whether device is currently charging
  final bool isCharging;

  /// Current battery status
  final BatteryStatus batteryState;

  /// Power source when charging
  final PowerSource? powerSource;

  /// Estimated time remaining (discharge or charge)
  final Duration? timeRemaining;

  /// Battery health (0.0 to 1.0, where 1.0 is perfect)
  final double? health;

  /// Battery temperature in Celsius
  final double? temperature;

  /// Battery voltage in volts
  final double? voltage;

  /// Battery technology
  final String? technology;

  /// When this state was recorded
  final DateTime? timestamp;

  /// Battery level as percentage
  int get percentage => (level * 100).round();

  /// Whether battery is low (< 20%)
  bool get isLow => level < 0.2;

  /// Whether battery is critical (< 10%)
  bool get isCritical => level < 0.1;

  /// Whether battery is full
  bool get isFull => level >= 0.99;

  @override
  String toString() {
    return 'BatteryState(level: ${percentage}%, isCharging: $isCharging, state: $batteryState)';
  }
}

/// Battery status types
enum BatteryStatus {
  /// Status unknown
  unknown,

  /// Battery is charging
  charging,

  /// Battery is discharging
  discharging,

  /// Battery is not charging (plugged in but full)
  notCharging,

  /// Battery is full
  full,
}

/// Power source types
enum PowerSource {
  /// Unknown power source
  unknown,

  /// AC adapter
  ac,

  /// USB connection
  usb,

  /// Wireless charging
  wireless,

  /// Battery (when not charging)
  battery,
}

/// Memory usage information
@immutable
class MemoryInfo {
  const MemoryInfo({
    required this.totalPhysical,
    required this.availablePhysical,
    required this.usedPhysical,
    this.totalVirtual,
    this.availableVirtual,
    this.usedVirtual,
    this.appUsage,
    this.systemUsage,
    this.timestamp,
  });

  /// Total physical memory in bytes
  final int totalPhysical;

  /// Available physical memory in bytes
  final int availablePhysical;

  /// Used physical memory in bytes
  final int usedPhysical;

  /// Total virtual memory in bytes
  final int? totalVirtual;

  /// Available virtual memory in bytes
  final int? availableVirtual;

  /// Used virtual memory in bytes
  final int? usedVirtual;

  /// Memory used by current app in bytes
  final int? appUsage;

  /// Memory used by system in bytes
  final int? systemUsage;

  /// When this info was recorded
  final DateTime? timestamp;

  /// Physical memory usage as percentage
  double get physicalUsagePercentage => usedPhysical / totalPhysical;

  /// Virtual memory usage as percentage (if available)
  double? get virtualUsagePercentage {
    if (totalVirtual == null || usedVirtual == null) return null;
    return usedVirtual! / totalVirtual!;
  }

  /// Whether memory usage is high (> 80%)
  bool get isHighUsage => physicalUsagePercentage > 0.8;

  /// Whether memory usage is critical (> 95%)
  bool get isCriticalUsage => physicalUsagePercentage > 0.95;

  /// Format bytes as human-readable string
  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  @override
  String toString() {
    return 'MemoryInfo(total: ${formatBytes(totalPhysical)}, used: ${formatBytes(usedPhysical)}, usage: ${(physicalUsagePercentage * 100).toStringAsFixed(1)}%)';
  }
}

/// CPU usage information
@immutable
class CPUInfo {
  const CPUInfo({
    required this.usage,
    this.cores,
    this.frequency,
    this.architecture,
    this.model,
    this.vendor,
    this.temperature,
    this.loadAverage,
    this.timestamp,
  });

  /// CPU usage percentage (0.0 to 1.0)
  final double usage;

  /// Number of CPU cores
  final int? cores;

  /// CPU frequency in Hz
  final int? frequency;

  /// CPU architecture (x86_64, arm64, etc.)
  final String? architecture;

  /// CPU model name
  final String? model;

  /// CPU vendor
  final String? vendor;

  /// CPU temperature in Celsius
  final double? temperature;

  /// Load average (1, 5, 15 minutes)
  final List<double>? loadAverage;

  /// When this info was recorded
  final DateTime? timestamp;

  /// CPU usage as percentage
  int get usagePercentage => (usage * 100).round();

  /// Whether CPU usage is high (> 80%)
  bool get isHighUsage => usage > 0.8;

  /// Whether CPU usage is critical (> 95%)
  bool get isCriticalUsage => usage > 0.95;

  /// CPU frequency in GHz
  double? get frequencyGHz {
    if (frequency == null) return null;
    return frequency! / 1000000000;
  }

  @override
  String toString() {
    return 'CPUInfo(usage: ${usagePercentage}%, cores: $cores, frequency: ${frequencyGHz?.toStringAsFixed(2)} GHz)';
  }
}

/// Storage information
@immutable
class StorageInfo {
  const StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
    this.type,
    this.mountPoint,
    this.filesystem,
    this.isRemovable = false,
    this.isReadOnly = false,
    this.timestamp,
  });

  /// Total storage space in bytes
  final int totalSpace;

  /// Free storage space in bytes
  final int freeSpace;

  /// Used storage space in bytes
  final int usedSpace;

  /// Storage type
  final StorageType? type;

  /// Mount point or drive letter
  final String? mountPoint;

  /// Filesystem type
  final String? filesystem;

  /// Whether storage is removable
  final bool isRemovable;

  /// Whether storage is read-only
  final bool isReadOnly;

  /// When this info was recorded
  final DateTime? timestamp;

  /// Storage usage as percentage
  double get usagePercentage => usedSpace / totalSpace;

  /// Whether storage is nearly full (> 90%)
  bool get isNearlyFull => usagePercentage > 0.9;

  /// Whether storage is full (> 95%)
  bool get isFull => usagePercentage > 0.95;

  /// Format bytes as human-readable string
  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)} TB';
    } else if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  @override
  String toString() {
    return 'StorageInfo(total: ${formatBytes(totalSpace)}, free: ${formatBytes(freeSpace)}, usage: ${(usagePercentage * 100).toStringAsFixed(1)}%)';
  }
}

/// Storage types
enum StorageType {
  /// Unknown storage type
  unknown,

  /// Hard disk drive
  hdd,

  /// Solid state drive
  ssd,

  /// SD card
  sdCard,

  /// USB storage
  usb,

  /// Network attached storage
  nas,

  /// Cloud storage
  cloud,

  /// RAM disk
  ramdisk,
}

/// System theme information
@immutable
class SystemTheme {
  const SystemTheme({
    required this.brightness,
    this.accentColor,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.highContrast = false,
    this.reducedMotion = false,
    this.timestamp,
  });

  /// System brightness preference
  final Brightness brightness;

  /// System accent color (if available)
  final int? accentColor;

  /// Primary color
  final int? primaryColor;

  /// Background color
  final int? backgroundColor;

  /// Text color
  final int? textColor;

  /// Whether high contrast is enabled
  final bool highContrast;

  /// Whether reduced motion is enabled
  final bool reducedMotion;

  /// When this theme info was recorded
  final DateTime? timestamp;

  /// Whether system is in dark mode
  bool get isDark => brightness == Brightness.dark;

  /// Whether system is in light mode
  bool get isLight => brightness == Brightness.light;

  @override
  String toString() {
    return 'SystemTheme(brightness: $brightness, highContrast: $highContrast, reducedMotion: $reducedMotion)';
  }
}

/// System brightness
enum Brightness {
  /// Light theme
  light,

  /// Dark theme
  dark,
}

/// Window focus state
@immutable
class WindowFocusState {
  const WindowFocusState({
    required this.hasFocus,
    this.windowId,
    this.timestamp,
  });

  /// Whether window has focus
  final bool hasFocus;

  /// Window identifier
  final String? windowId;

  /// When focus state changed
  final DateTime? timestamp;

  @override
  String toString() {
    return 'WindowFocusState(hasFocus: $hasFocus, windowId: $windowId)';
  }
}

/// System performance metrics
@immutable
class PerformanceMetrics {
  const PerformanceMetrics({
    this.cpuInfo,
    this.memoryInfo,
    this.batteryState,
    this.storageInfo,
    this.networkBandwidth,
    this.frameRate,
    this.temperature,
    this.timestamp,
  });

  /// CPU information
  final CPUInfo? cpuInfo;

  /// Memory information
  final MemoryInfo? memoryInfo;

  /// Battery state
  final BatteryState? batteryState;

  /// Storage information
  final StorageInfo? storageInfo;

  /// Network bandwidth in bytes per second
  final int? networkBandwidth;

  /// Current frame rate (FPS)
  final double? frameRate;

  /// Device temperature in Celsius
  final double? temperature;

  /// When metrics were recorded
  final DateTime? timestamp;

  /// Whether system performance is good
  bool get isPerformanceGood {
    if (cpuInfo != null && cpuInfo!.isHighUsage) return false;
    if (memoryInfo != null && memoryInfo!.isHighUsage) return false;
    if (batteryState != null && batteryState!.isCritical) return false;
    if (frameRate != null && frameRate! < 30) return false;
    return true;
  }

  @override
  String toString() {
    return 'PerformanceMetrics(cpu: ${cpuInfo?.usagePercentage}%, memory: ${memoryInfo?.physicalUsagePercentage.toStringAsFixed(1)}%, fps: $frameRate)';
  }
}

/// Device orientation
enum DeviceOrientation {
  /// Portrait up
  portraitUp,

  /// Portrait down
  portraitDown,

  /// Landscape left
  landscapeLeft,

  /// Landscape right
  landscapeRight,

  /// Unknown orientation
  unknown,
}

/// Device information
@immutable
class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.platformVersion,
    this.model,
    this.manufacturer,
    this.brand,
    this.hardware,
    this.screenSize,
    this.screenDensity,
    this.isPhysicalDevice = true,
    this.supportedAbis,
    this.capabilities,
  });

  /// Unique device identifier
  final String deviceId;

  /// Device name
  final String deviceName;

  /// Platform (iOS, Android, Windows, etc.)
  final String platform;

  /// Platform version
  final String? platformVersion;

  /// Device model
  final String? model;

  /// Device manufacturer
  final String? manufacturer;

  /// Device brand
  final String? brand;

  /// Hardware information
  final String? hardware;

  /// Screen size in pixels
  final Size? screenSize;

  /// Screen density (DPI)
  final double? screenDensity;

  /// Whether this is a physical device (not emulator)
  final bool isPhysicalDevice;

  /// Supported CPU architectures
  final List<String>? supportedAbis;

  /// Device capabilities
  final Map<String, bool>? capabilities;

  /// Whether device is an emulator/simulator
  bool get isEmulator => !isPhysicalDevice;

  @override
  String toString() {
    return 'DeviceInfo(name: $deviceName, platform: $platform $platformVersion, model: $model)';
  }
}

/// Screen size representation
@immutable
class Size {
  const Size({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  /// Aspect ratio (width / height)
  double get aspectRatio => width / height;

  /// Whether size is portrait
  bool get isPortrait => height > width;

  /// Whether size is landscape
  bool get isLandscape => width > height;

  @override
  String toString() {
    return 'Size(${width.toStringAsFixed(0)} x ${height.toStringAsFixed(0)})';
  }
}
