import 'dart:async';
import 'package:flutter/foundation.dart';

import 'platform_detector.dart';

/// Advanced capability detection for runtime feature availability
class CapabilityDetector {
  static CapabilityDetector? _instance;
  static CapabilityDetector get instance =>
      _instance ??= CapabilityDetector._();

  CapabilityDetector._();

  bool _isInitialized = false;
  final Map<String, bool> _capabilities = {};

  /// Check if capability detector is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize capability detection
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _detectAllCapabilities();
    _isInitialized = true;

    if (kDebugMode) {
      print(
          'CapabilityDetector: Initialized with ${_capabilities.length} capabilities');
    }
  }

  /// Detect all platform capabilities
  Future<void> _detectAllCapabilities() async {
    // System-level capabilities
    _capabilities['clipboard'] = await _detectClipboard();
    _capabilities['notifications'] = await _detectNotifications();
    _capabilities['fileSystem'] = await _detectFileSystem();

    // Web-specific capabilities
    if (kIsWeb) {
      _capabilities['serviceWorker'] = await _detectServiceWorker();
      _capabilities['webGL'] = await _detectWebGL();
      _capabilities['webAssembly'] = await _detectWebAssembly();
      _capabilities['webRTC'] = await _detectWebRTC();
      _capabilities['webBluetooth'] = await _detectWebBluetooth();
      _capabilities['webUSB'] = await _detectWebUSB();
      _capabilities['webShare'] = await _detectWebShare();
      _capabilities['localStorage'] = await _detectLocalStorage();
      _capabilities['indexedDB'] = await _detectIndexedDB();
    }

    // Desktop-specific capabilities
    if (PlatformDetector.isDesktop) {
      _capabilities['systemTray'] = await _detectSystemTray();
      _capabilities['globalShortcuts'] = await _detectGlobalShortcuts();
      _capabilities['windowManagement'] = await _detectWindowManagement();
      _capabilities['dragDrop'] = await _detectDragDrop();
      _capabilities['multiWindow'] = await _detectMultiWindow();
      _capabilities['screenCapture'] = await _detectScreenCapture();
      _capabilities['fileDialogs'] = await _detectFileDialogs();
    }

    // Mobile-specific capabilities
    if (PlatformDetector.isMobile) {
      _capabilities['camera'] = await _detectCamera();
      _capabilities['location'] = await _detectLocation();
      _capabilities['bluetooth'] = await _detectBluetooth();
      _capabilities['nfc'] = await _detectNFC();
      _capabilities['biometrics'] = await _detectBiometrics();
      _capabilities['haptics'] = await _detectHaptics();
      _capabilities['sensors'] = await _detectSensors();
    }

    // Cross-platform capabilities
    _capabilities['networking'] = await _detectNetworking();
    _capabilities['storage'] = await _detectStorage();
    _capabilities['audio'] = await _detectAudio();
    _capabilities['video'] = await _detectVideo();
  }

  // System capabilities
  Future<bool> _detectClipboard() async {
    try {
      // Basic clipboard support is available on all platforms
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _detectNotifications() async {
    try {
      if (kIsWeb) {
        // Check for Notification API on web
        return _hasWebAPI('Notification');
      } else {
        // Desktop and mobile have native notification support
        return PlatformDetector.isDesktop || PlatformDetector.isMobile;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _detectFileSystem() async {
    try {
      if (kIsWeb) {
        return _hasWebAPI('showOpenFilePicker') || _hasWebAPI('FileReader');
      } else {
        return true; // Desktop and mobile have file system access
      }
    } catch (e) {
      return false;
    }
  }

  // Web capabilities
  Future<bool> _detectServiceWorker() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('serviceWorker', parent: 'navigator');
  }

  Future<bool> _detectWebGL() async {
    if (!kIsWeb) return false;
    // In a real implementation, you would test canvas.getContext('webgl')
    return true; // Most modern browsers support WebGL
  }

  Future<bool> _detectWebAssembly() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('WebAssembly');
  }

  Future<bool> _detectWebRTC() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('RTCPeerConnection') ||
        _hasWebAPI('webkitRTCPeerConnection');
  }

  Future<bool> _detectWebBluetooth() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('bluetooth', parent: 'navigator');
  }

  Future<bool> _detectWebUSB() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('usb', parent: 'navigator');
  }

  Future<bool> _detectWebShare() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('share', parent: 'navigator');
  }

  Future<bool> _detectLocalStorage() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('localStorage');
  }

  Future<bool> _detectIndexedDB() async {
    if (!kIsWeb) return false;
    return _hasWebAPI('indexedDB');
  }

  // Desktop capabilities
  Future<bool> _detectSystemTray() async {
    if (!PlatformDetector.isDesktop) return false;
    return true; // Assume system tray support on desktop
  }

  Future<bool> _detectGlobalShortcuts() async {
    if (!PlatformDetector.isDesktop) return false;
    return true; // Assume global shortcuts support on desktop
  }

  Future<bool> _detectWindowManagement() async {
    if (!PlatformDetector.isDesktop) return false;
    return true; // Assume window management support on desktop
  }

  Future<bool> _detectDragDrop() async {
    return PlatformDetector.isDesktop || kIsWeb;
  }

  Future<bool> _detectMultiWindow() async {
    if (!PlatformDetector.isDesktop) return false;
    return true; // Assume multi-window support on desktop
  }

  Future<bool> _detectScreenCapture() async {
    if (!PlatformDetector.isDesktop) return false;
    return true; // Assume screen capture support on desktop
  }

  Future<bool> _detectFileDialogs() async {
    if (!PlatformDetector.isDesktop) return false;
    return true; // Assume file dialogs support on desktop
  }

  // Mobile capabilities
  Future<bool> _detectCamera() async {
    if (!PlatformDetector.isMobile) return false;
    return true; // Assume camera support on mobile
  }

  Future<bool> _detectLocation() async {
    if (kIsWeb) {
      return _hasWebAPI('geolocation', parent: 'navigator');
    } else if (PlatformDetector.isMobile) {
      return true; // Assume location support on mobile
    }
    return false;
  }

  Future<bool> _detectBluetooth() async {
    if (!PlatformDetector.isMobile) return false;
    return true; // Assume Bluetooth support on mobile
  }

  Future<bool> _detectNFC() async {
    if (!PlatformDetector.isMobile) return false;
    return PlatformDetector.isAndroid; // NFC primarily on Android
  }

  Future<bool> _detectBiometrics() async {
    if (!PlatformDetector.isMobile) return false;
    return true; // Assume biometric support on mobile
  }

  Future<bool> _detectHaptics() async {
    if (!PlatformDetector.isMobile) return false;
    return true; // Assume haptic feedback support on mobile
  }

  Future<bool> _detectSensors() async {
    if (!PlatformDetector.isMobile) return false;
    return true; // Assume sensor support on mobile
  }

  // Cross-platform capabilities
  Future<bool> _detectNetworking() async {
    return true; // All platforms support networking
  }

  Future<bool> _detectStorage() async {
    return true; // All platforms support some form of storage
  }

  Future<bool> _detectAudio() async {
    return true; // All platforms support audio
  }

  Future<bool> _detectVideo() async {
    return true; // All platforms support video
  }

  /// Helper to check if a web API exists
  bool _hasWebAPI(String api, {String? parent}) {
    if (!kIsWeb) return false;

    try {
      // In a real implementation, you would use dart:html or dart:js
      // to check for API availability. This is a simplified check.

      // For now, return true for common APIs
      const commonAPIs = [
        'localStorage',
        'sessionStorage',
        'indexedDB',
        'WebAssembly',
        'Notification',
        'FileReader',
        'RTCPeerConnection',
        'serviceWorker',
        'geolocation',
        'share',
        'clipboard'
      ];

      return commonAPIs.contains(api);
    } catch (e) {
      return false;
    }
  }

  /// Public capability checks
  bool get supportsClipboard => _capabilities['clipboard'] ?? false;
  bool get supportsNotifications => _capabilities['notifications'] ?? false;
  bool get supportsFileSystem => _capabilities['fileSystem'] ?? false;
  bool get supportsServiceWorker => _capabilities['serviceWorker'] ?? false;
  bool get supportsWebGL => _capabilities['webGL'] ?? false;
  bool get supportsWebAssembly => _capabilities['webAssembly'] ?? false;
  bool get supportsWebRTC => _capabilities['webRTC'] ?? false;
  bool get supportsWebBluetooth => _capabilities['webBluetooth'] ?? false;
  bool get supportsWebUSB => _capabilities['webUSB'] ?? false;
  bool get supportsWebShare => _capabilities['webShare'] ?? false;
  bool get supportsLocalStorage => _capabilities['localStorage'] ?? false;
  bool get supportsIndexedDB => _capabilities['indexedDB'] ?? false;
  bool get supportsSystemTray => _capabilities['systemTray'] ?? false;
  bool get supportsGlobalShortcuts => _capabilities['globalShortcuts'] ?? false;
  bool get supportsWindowManagement =>
      _capabilities['windowManagement'] ?? false;
  bool get supportsDragDrop => _capabilities['dragDrop'] ?? false;
  bool get supportsMultiWindow => _capabilities['multiWindow'] ?? false;
  bool get supportsScreenCapture => _capabilities['screenCapture'] ?? false;
  bool get supportsFileDialogs => _capabilities['fileDialogs'] ?? false;
  bool get supportsCamera => _capabilities['camera'] ?? false;
  bool get supportsLocation => _capabilities['location'] ?? false;
  bool get supportsBluetooth => _capabilities['bluetooth'] ?? false;
  bool get supportsNFC => _capabilities['nfc'] ?? false;
  bool get supportsBiometrics => _capabilities['biometrics'] ?? false;
  bool get supportsHaptics => _capabilities['haptics'] ?? false;
  bool get supportsSensors => _capabilities['sensors'] ?? false;
  bool get supportsNetworking => _capabilities['networking'] ?? false;
  bool get supportsStorage => _capabilities['storage'] ?? false;
  bool get supportsAudio => _capabilities['audio'] ?? false;
  bool get supportsVideo => _capabilities['video'] ?? false;

  /// Check if a specific capability is supported
  bool isCapabilitySupported(String capability) {
    return _capabilities[capability] ?? false;
  }

  /// Get all detected capabilities
  Map<String, bool> getAllCapabilities() {
    return Map.from(_capabilities);
  }

  /// Get capabilities for current platform
  Map<String, bool> getPlatformCapabilities() {
    final platformCaps = <String, bool>{};

    if (kIsWeb) {
      final webCaps = [
        'serviceWorker',
        'webGL',
        'webAssembly',
        'webRTC',
        'webBluetooth',
        'webUSB',
        'webShare',
        'localStorage',
        'indexedDB'
      ];
      for (final cap in webCaps) {
        if (_capabilities.containsKey(cap)) {
          platformCaps[cap] = _capabilities[cap]!;
        }
      }
    } else if (PlatformDetector.isDesktop) {
      final desktopCaps = [
        'systemTray',
        'globalShortcuts',
        'windowManagement',
        'dragDrop',
        'multiWindow',
        'screenCapture',
        'fileDialogs'
      ];
      for (final cap in desktopCaps) {
        if (_capabilities.containsKey(cap)) {
          platformCaps[cap] = _capabilities[cap]!;
        }
      }
    } else if (PlatformDetector.isMobile) {
      final mobileCaps = [
        'camera',
        'location',
        'bluetooth',
        'nfc',
        'biometrics',
        'haptics',
        'sensors'
      ];
      for (final cap in mobileCaps) {
        if (_capabilities.containsKey(cap)) {
          platformCaps[cap] = _capabilities[cap]!;
        }
      }
    }

    // Add common capabilities
    final commonCaps = [
      'clipboard',
      'notifications',
      'fileSystem',
      'networking',
      'storage',
      'audio',
      'video'
    ];
    for (final cap in commonCaps) {
      if (_capabilities.containsKey(cap)) {
        platformCaps[cap] = _capabilities[cap]!;
      }
    }

    return platformCaps;
  }
}
