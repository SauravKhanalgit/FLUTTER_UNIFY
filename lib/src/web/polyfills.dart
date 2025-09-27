import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;
// ignore: deprecated_member_use
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../common/event_emitter.dart';

/// Cross-browser polyfills for web APIs
class WebPolyfills extends EventEmitter {
  bool _isInitialized = false;
  final Map<String, bool> _supportedAPIs = {};

  /// Check if polyfills are initialized
  bool get isInitialized => _isInitialized;

  /// Get supported APIs
  Map<String, bool> get supportedAPIs => Map.from(_supportedAPIs);

  /// Initialize web polyfills
  Future<void> initialize() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebPolyfills can only be used on web platforms');
    }

    if (_isInitialized) return;

    await _detectAPISupport();
    await _loadPolyfills();

    _isInitialized = true;
    emit('polyfills-initialized');

    if (kDebugMode) {
      print('WebPolyfills: Initialized with support detection');
    }
  }

  /// Detect browser API support
  Future<void> _detectAPISupport() async {
    // File System Access API
    _supportedAPIs['fileSystem'] = js.context.hasProperty('showOpenFilePicker');

    // Web Bluetooth API
    _supportedAPIs['bluetooth'] = _hasNavigatorProperty('bluetooth');

    // WebRTC API
    _supportedAPIs['webRTC'] = js.context.hasProperty('RTCPeerConnection') ||
        js.context.hasProperty('webkitRTCPeerConnection');

    // Web Share API
    _supportedAPIs['webShare'] = _hasNavigatorProperty('share');

    // Clipboard API
    _supportedAPIs['clipboard'] = _hasNavigatorProperty('clipboard');

    // Notifications API
    _supportedAPIs['notifications'] = js.context.hasProperty('Notification');

    // Geolocation API
    _supportedAPIs['geolocation'] = _hasNavigatorProperty('geolocation');

    // Service Worker API
    _supportedAPIs['serviceWorker'] = _hasNavigatorProperty('serviceWorker');

    // Web Workers API
    _supportedAPIs['webWorkers'] = js.context.hasProperty('Worker');

    // IndexedDB API
    _supportedAPIs['indexedDB'] = js.context.hasProperty('indexedDB');

    // Local Storage API
    _supportedAPIs['localStorage'] = js.context.hasProperty('localStorage');

    // Session Storage API
    _supportedAPIs['sessionStorage'] = js.context.hasProperty('sessionStorage');

    emit('api-support-detected', _supportedAPIs);
  }

  /// Check if navigator has a specific property
  bool _hasNavigatorProperty(String property) {
    try {
      final navigator = js.context['navigator'];
      return navigator != null && navigator.hasProperty(property);
    } catch (e) {
      return false;
    }
  }

  /// Load necessary polyfills
  Future<void> _loadPolyfills() async {
    final polyfillsToLoad = <Future>[];

    // File System Access API polyfill
    if (!_supportedAPIs['fileSystem']!) {
      polyfillsToLoad.add(_loadFileSystemPolyfill());
    }

    // Clipboard API polyfill
    if (!_supportedAPIs['clipboard']!) {
      polyfillsToLoad.add(_loadClipboardPolyfill());
    }

    // Web Share API polyfill
    if (!_supportedAPIs['webShare']!) {
      polyfillsToLoad.add(_loadWebSharePolyfill());
    }

    // Intersection Observer polyfill (for older browsers)
    if (!js.context.hasProperty('IntersectionObserver')) {
      polyfillsToLoad.add(_loadIntersectionObserverPolyfill());
    }

    // ResizeObserver polyfill (for older browsers)
    if (!js.context.hasProperty('ResizeObserver')) {
      polyfillsToLoad.add(_loadResizeObserverPolyfill());
    }

    await Future.wait(polyfillsToLoad);
  }

  /// Load File System Access API polyfill
  Future<void> _loadFileSystemPolyfill() async {
    try {
      // Create a polyfill for showOpenFilePicker
      js.context['showOpenFilePicker'] = js.allowInterop((options) {
        return _createFilePickerPolyfill(options);
      });

      // Create a polyfill for showSaveFilePicker
      js.context['showSaveFilePicker'] = js.allowInterop((options) {
        return _createSaveFilePolyfill(options);
      });

      if (kDebugMode) {
        print('WebPolyfills: File System API polyfill loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebPolyfills: Error loading File System polyfill: $e');
      }
    }
  }

  /// Create file picker polyfill using input element
  Future<List<dynamic>> _createFilePickerPolyfill(dynamic options) async {
    final completer = Completer<List<dynamic>>();

    final input = html.FileUploadInputElement()
      ..accept = _getAcceptTypes(options)
      ..multiple = _getBoolOption(options, 'multiple', false);

    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final fileHandles =
            files.map((file) => _createFileHandle(file)).toList();
        completer.complete(fileHandles);
      } else {
        completer.complete([]);
      }
    });

    input.click();

    return completer.future;
  }

  /// Create save file polyfill using download
  Future<dynamic> _createSaveFilePolyfill(dynamic options) async {
    // For now, return a simple download-based implementation
    return _createDownloadFileHandle(options);
  }

  /// Create a file handle wrapper
  Map<String, dynamic> _createFileHandle(html.File file) {
    return {
      'name': file.name,
      'size': file.size,
      'type': file.type,
      'lastModified': file.lastModified,
      'getFile': () => file,
    };
  }

  /// Create a download file handle
  Map<String, dynamic> _createDownloadFileHandle(dynamic options) {
    return {
      'name': _getStringOption(options, 'suggestedName', 'download.txt'),
      'createWritable': () => _createWritableStream(),
    };
  }

  /// Create a writable stream polyfill
  Map<String, dynamic> _createWritableStream() {
    final chunks = <dynamic>[];

    return {
      'write': (data) => chunks.add(data),
      'close': () => _downloadFile(chunks),
    };
  }

  /// Download file using blob and URL
  void _downloadFile(List<dynamic> chunks) {
    final blob = html.Blob(chunks);
    final url = html.Url.createObjectUrlFromBlob(blob);

    (html.AnchorElement()
          ..href = url
          ..download = 'download.txt')
        .click();

    html.Url.revokeObjectUrl(url);
  }

  /// Load Clipboard API polyfill
  Future<void> _loadClipboardPolyfill() async {
    try {
      if (js.context['navigator'] != null) {
        final navigator = js.context['navigator'];

        if (!navigator.hasProperty('clipboard')) {
          navigator['clipboard'] = js.JsObject.jsify({
            'writeText': js.allowInterop((text) => _writeTextPolyfill(text)),
            'readText': js.allowInterop(() => _readTextPolyfill()),
          });
        }
      }

      if (kDebugMode) {
        print('WebPolyfills: Clipboard API polyfill loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebPolyfills: Error loading Clipboard polyfill: $e');
      }
    }
  }

  /// Write text polyfill using deprecated execCommand
  Future<void> _writeTextPolyfill(String text) async {
    final textarea = html.TextAreaElement()
      ..value = text
      ..style.position = 'fixed'
      ..style.left = '-999px';

    html.document.body?.append(textarea);
    textarea.select();

    try {
      html.document.execCommand('copy');
    } catch (e) {
      if (kDebugMode) {
        print('WebPolyfills: Copy command failed: $e');
      }
    } finally {
      textarea.remove();
    }
  }

  /// Read text polyfill (limited functionality)
  Future<String> _readTextPolyfill() async {
    // Note: Reading clipboard is very limited without user gesture
    throw UnsupportedError(
        'Reading clipboard requires user gesture and modern browser support');
  }

  /// Load Web Share API polyfill
  Future<void> _loadWebSharePolyfill() async {
    try {
      if (js.context['navigator'] != null) {
        final navigator = js.context['navigator'];

        if (!navigator.hasProperty('share')) {
          navigator['share'] = js.allowInterop((data) => _sharePolyfill(data));
        }
      }

      if (kDebugMode) {
        print('WebPolyfills: Web Share API polyfill loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebPolyfills: Error loading Web Share polyfill: $e');
      }
    }
  }

  /// Share polyfill using fallback methods
  Future<void> _sharePolyfill(dynamic data) async {
    final title = _getStringOption(data, 'title', '');
    final text = _getStringOption(data, 'text', '');
    final url = _getStringOption(data, 'url', '');

    // Create share URL for common platforms
    final shareText = '$title $text $url'.trim();
    final encodedText = Uri.encodeComponent(shareText);

    // Try different sharing methods
    final shareUrls = [
      'https://twitter.com/intent/tweet?text=$encodedText',
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}',
      'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(url)}',
    ];

    // Open share dialog
    _showShareDialog(shareUrls, shareText);
  }

  /// Show custom share dialog
  void _showShareDialog(List<String> shareUrls, String text) {
    // Create simple share dialog
    final dialog = html.DivElement()
      ..style.cssText = '''
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        z-index: 10000;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      ''';

    dialog.innerHtml = '''
      <h3>Share</h3>
      <p>Copy link or share on social media:</p>
      <input type="text" value="$text" readonly style="width: 100%; margin-bottom: 10px; padding: 5px;">
      <div style="display: flex; gap: 10px;">
        <button onclick="navigator.clipboard.writeText('$text')">Copy</button>
        <button onclick="window.open('${shareUrls[0]}', '_blank')">Twitter</button>
        <button onclick="window.open('${shareUrls[1]}', '_blank')">Facebook</button>
        <button onclick="this.parentElement.parentElement.remove()">Close</button>
      </div>
    ''';

    html.document.body?.append(dialog);

    // Auto-remove after 10 seconds
    Timer(Duration(seconds: 10), () => dialog.remove());
  }

  /// Load Intersection Observer polyfill
  Future<void> _loadIntersectionObserverPolyfill() async {
    // In a real implementation, you would load from a CDN
    if (kDebugMode) {
      print('WebPolyfills: IntersectionObserver polyfill would be loaded here');
    }
  }

  /// Load ResizeObserver polyfill
  Future<void> _loadResizeObserverPolyfill() async {
    // In a real implementation, you would load from a CDN
    if (kDebugMode) {
      print('WebPolyfills: ResizeObserver polyfill would be loaded here');
    }
  }

  /// Helper methods for extracting options
  String _getAcceptTypes(dynamic options) {
    try {
      if (options != null && options['types'] != null) {
        final types = options['types'] as List;
        return types.map((type) => type['accept'] ?? '*/*').join(',');
      }
    } catch (e) {
      // Ignore errors
    }
    return '*/*';
  }

  bool _getBoolOption(dynamic options, String key, bool defaultValue) {
    try {
      return options != null && options[key] != null
          ? options[key] as bool
          : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  String _getStringOption(dynamic options, String key, String defaultValue) {
    try {
      return options != null && options[key] != null
          ? options[key].toString()
          : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Check if a specific API is supported
  bool isAPISupported(String api) {
    return _supportedAPIs[api] ?? false;
  }

  /// Get browser capabilities report
  Map<String, dynamic> getBrowserCapabilities() {
    return {
      'userAgent': html.window.navigator.userAgent,
      'supportedAPIs': _supportedAPIs,
      'cookieEnabled': html.window.navigator.cookieEnabled,
      'onLine': html.window.navigator.onLine,
      'platform': html.window.navigator.platform,
      'language': html.window.navigator.language,
      'languages': html.window.navigator.languages,
    };
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _supportedAPIs.clear();
    removeAllListeners();
    _isInitialized = false;
  }
}
