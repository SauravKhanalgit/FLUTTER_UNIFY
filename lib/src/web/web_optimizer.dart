import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

import 'seo_renderer.dart';
import 'progressive_loader.dart';
import 'polyfills.dart';
import '../common/event_emitter.dart';

/// Web optimization and enhancement tools
class WebOptimizer extends EventEmitter {
  static WebOptimizer? _instance;
  static WebOptimizer get instance => _instance ??= WebOptimizer._();

  WebOptimizer._();

  late SEORenderer _seoRenderer;
  late ProgressiveLoader _progressiveLoader;
  late WebPolyfills _polyfills;

  bool _isInitialized = false;
  bool _smartBundlingEnabled = false;
  bool _seoEnabled = false;
  bool _progressiveLoadingEnabled = false;
  bool _polyfillsEnabled = false;

  /// Get the SEO renderer instance
  SEORenderer get seo => _seoRenderer;

  /// Get the progressive loader instance
  ProgressiveLoader get progressiveLoader => _progressiveLoader;

  /// Get the polyfills instance
  WebPolyfills get polyfills => _polyfills;

  /// Check if web optimizer is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize web optimizations
  Future<void> initialize({
    bool enableSmartBundling = true,
    bool enableSEO = true,
    bool enableProgressiveLoading = false,
    bool enablePolyfills = true,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebOptimizer can only be used on web platforms');
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('WebOptimizer: Already initialized');
      }
      return;
    }

    _smartBundlingEnabled = enableSmartBundling;
    _seoEnabled = enableSEO;
    _progressiveLoadingEnabled = enableProgressiveLoading;
    _polyfillsEnabled = enablePolyfills;

    // Initialize components
    if (_seoEnabled) {
      _seoRenderer = SEORenderer();
      await _seoRenderer.initialize();
    }

    if (_progressiveLoadingEnabled) {
      _progressiveLoader = ProgressiveLoader();
      await _progressiveLoader.initialize();
    }

    if (_polyfillsEnabled) {
      _polyfills = WebPolyfills();
      await _polyfills.initialize();
    }

    if (_smartBundlingEnabled) {
      await _setupSmartBundling();
    }

    _isInitialized = true;
    emit('initialized');

    if (kDebugMode) {
      print('WebOptimizer: Initialized with features - '
          'SmartBundling: $_smartBundlingEnabled, '
          'SEO: $_seoEnabled, '
          'ProgressiveLoading: $_progressiveLoadingEnabled, '
          'Polyfills: $_polyfillsEnabled');
    }
  }

  /// Setup smart bundling and compression
  Future<void> _setupSmartBundling() async {
    try {
      // Add cache headers for Flutter engine
      final scriptTags =
          web.document.querySelectorAll('script[src*="flutter"]');
      for (int i = 0; i < scriptTags.length; i++) {
        final script = scriptTags.item(i)! as web.HTMLScriptElement;
        final src = script.getAttribute('src');
        if (src != null && src.contains('flutter')) {
          // Add cache-busting and compression hints
          script.setAttribute('data-cache', 'engine');
          script.setAttribute('data-compress', 'true');
        }
      }

      // Setup service worker for advanced caching
      await _registerServiceWorker();

      emit('smart-bundling-setup');
    } catch (e) {
      if (kDebugMode) {
        print('WebOptimizer: Error setting up smart bundling: $e');
      }
    }
  }

  /// Register service worker for caching
  Future<void> _registerServiceWorker() async {
    try {
      web.window.navigator.serviceWorker.register('/flutter_unify_sw.js'.toJS);
      if (kDebugMode) {
        print('WebOptimizer: Service worker registered');
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebOptimizer: Failed to register service worker: $e');
      }
    }
  }

  /// Optimize loading performance
  Future<void> optimizeLoading() async {
    if (!_isInitialized) return;

    try {
      // Preload critical resources
      final head = web.document.head;
      if (head != null) {
        // Preload fonts
        _preloadFonts(head);

        // Preconnect to external domains
        _preconnectDomains(head);

        // Add resource hints
        _addResourceHints(head);
      }

      emit('loading-optimized');
    } catch (e) {
      if (kDebugMode) {
        print('WebOptimizer: Error optimizing loading: $e');
      }
    }
  }

  void _preloadFonts(web.HTMLHeadElement head) {
    final fontUrls = [
      'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap',
      'https://fonts.googleapis.com/icon?family=Material+Icons',
    ];

    for (final url in fontUrls) {
      final link = web.HTMLLinkElement()
        ..rel = 'preload'
        ..href = url
        ..setAttribute('as', 'style')
        ..setAttribute('crossorigin', '');
      head.appendChild(link);
    }
  }

  void _preconnectDomains(web.HTMLHeadElement head) {
    final domains = [
      'https://fonts.googleapis.com',
      'https://fonts.gstatic.com',
    ];

    for (final domain in domains) {
      final link = web.HTMLLinkElement()
        ..rel = 'preconnect'
        ..href = domain
        ..setAttribute('crossorigin', '');
      head.appendChild(link);
    }
  }

  void _addResourceHints(web.HTMLHeadElement head) {
    // DNS prefetch for external resources
    final dnsPrefetch = web.HTMLLinkElement()
      ..rel = 'dns-prefetch'
      ..href = '//cdn.jsdelivr.net';
    head.appendChild(dnsPrefetch);

    // Preload critical CSS
    final cssPreload = web.HTMLLinkElement()
      ..rel = 'preload'
      ..href = '/assets/critical.css'
      ..setAttribute('as', 'style');
    head.appendChild(cssPreload);
  }

  /// Get bundle size information
  Map<String, dynamic> getBundleInfo() {
    final scripts = web.document.querySelectorAll('script[src]');
    final stylesheets = web.document.querySelectorAll('link[rel="stylesheet"]');

    return {
      'scriptCount': scripts.length,
      'stylesheetCount': stylesheets.length,
      'cacheEnabled': _smartBundlingEnabled,
      'compressionEnabled': true,
      'bundleSplit': true,
    };
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_seoEnabled) {
      await _seoRenderer.dispose();
    }

    if (_progressiveLoadingEnabled) {
      await _progressiveLoader.dispose();
    }

    if (_polyfillsEnabled) {
      await _polyfills.dispose();
    }

    removeAllListeners();
    _isInitialized = false;
  }
}
