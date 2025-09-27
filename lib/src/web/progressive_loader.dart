import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../common/event_emitter.dart';

/// Progressive loading system for Flutter web apps
class ProgressiveLoader extends EventEmitter {
  bool _isInitialized = false;
  html.Element? _skeletonContainer;
  html.Element? _loadingIndicator;
  bool _isHydrated = false;

  /// Check if progressive loader is initialized
  bool get isInitialized => _isInitialized;

  /// Check if the app is fully hydrated
  bool get isHydrated => _isHydrated;

  /// Initialize the progressive loader
  Future<void> initialize() async {
    if (!kIsWeb) {
      throw UnsupportedError(
          'ProgressiveLoader can only be used on web platforms');
    }

    if (_isInitialized) return;

    await _createSkeletonUI();
    _setupLoadingIndicator();
    _detectFlutterReady();

    _isInitialized = true;
    emit('progressive-loader-initialized');

    if (kDebugMode) {
      print('ProgressiveLoader: Initialized with skeleton UI');
    }
  }

  /// Create skeleton UI for instant loading
  Future<void> _createSkeletonUI() async {
    _skeletonContainer = html.DivElement()
      ..id = 'flutter-skeleton'
      ..className = 'flutter-skeleton-container';

    // Add CSS for skeleton animations
    _injectSkeletonCSS();

    // Create default skeleton structure
    _createDefaultSkeleton();

    // Insert skeleton before Flutter app loads
    final flutterApp = html.document.querySelector('flutter-view') ??
        html.document.querySelector('#app') ??
        html.document.body;

    if (flutterApp != null) {
      flutterApp.insertBefore(_skeletonContainer!, flutterApp.firstChild);
    }
  }

  /// Inject CSS for skeleton animations
  void _injectSkeletonCSS() {
    final css = '''
      .flutter-skeleton-container {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100vh;
        background: #ffffff;
        z-index: 9999;
        transition: opacity 0.3s ease-out;
      }
      
      .flutter-skeleton-container.hidden {
        opacity: 0;
        pointer-events: none;
      }
      
      .skeleton-element {
        background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
        background-size: 200% 100%;
        animation: skeleton-loading 1.5s infinite;
        border-radius: 4px;
      }
      
      @keyframes skeleton-loading {
        0% { background-position: 200% 0; }
        100% { background-position: -200% 0; }
      }
      
      .skeleton-header {
        height: 60px;
        margin-bottom: 20px;
      }
      
      .skeleton-nav {
        height: 40px;
        margin-bottom: 30px;
      }
      
      .skeleton-content {
        height: 200px;
        margin-bottom: 20px;
      }
      
      .skeleton-sidebar {
        width: 250px;
        height: 400px;
        float: right;
        margin-left: 20px;
      }
      
      .skeleton-text {
        height: 16px;
        margin-bottom: 10px;
      }
      
      .skeleton-text.short {
        width: 60%;
      }
      
      .skeleton-text.medium {
        width: 80%;
      }
      
      .skeleton-text.long {
        width: 95%;
      }
      
      .flutter-loading-indicator {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        text-align: center;
        color: #666;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      }
      
      .loading-spinner {
        width: 40px;
        height: 40px;
        border: 3px solid #e0e0e0;
        border-top: 3px solid #2196F3;
        border-radius: 50%;
        animation: spin 1s linear infinite;
        margin: 0 auto 16px;
      }
      
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    ''';

    final style = html.StyleElement()..text = css;
    html.document.head?.append(style);
  }

  /// Create default skeleton structure
  void _createDefaultSkeleton() {
    if (_skeletonContainer == null) return;

    final content = '''
      <div class="skeleton-element skeleton-header"></div>
      <div class="skeleton-element skeleton-nav"></div>
      <div class="skeleton-element skeleton-sidebar"></div>
      <div class="skeleton-element skeleton-content"></div>
      <div class="skeleton-element skeleton-text long"></div>
      <div class="skeleton-element skeleton-text medium"></div>
      <div class="skeleton-element skeleton-text short"></div>
      <div class="skeleton-element skeleton-text long"></div>
      <div class="skeleton-element skeleton-text medium"></div>
    ''';

    _skeletonContainer!.innerHtml = content;
  }

  /// Setup loading indicator
  void _setupLoadingIndicator() {
    _loadingIndicator = html.DivElement()
      ..className = 'flutter-loading-indicator'
      ..innerHtml = '''
        <div class="loading-spinner"></div>
        <div>Loading your app...</div>
      ''';

    _skeletonContainer?.append(_loadingIndicator!);
  }

  /// Create custom skeleton layout
  void createCustomSkeleton(String html) {
    if (_skeletonContainer == null) return;

    _skeletonContainer!.innerHtml = html;
    emit('custom-skeleton-created');
  }

  /// Add skeleton element
  void addSkeletonElement({
    required String className,
    String? width,
    String? height,
    String? marginBottom,
  }) {
    if (_skeletonContainer == null) return;

    final element = html.DivElement()
      ..className = 'skeleton-element $className';

    if (width != null) element.style.width = width;
    if (height != null) element.style.height = height;
    if (marginBottom != null) element.style.marginBottom = marginBottom;

    _skeletonContainer!.append(element);
  }

  /// Update loading message
  void updateLoadingMessage(String message) {
    final messageElement = _loadingIndicator?.querySelector('div:last-child');
    if (messageElement != null) {
      messageElement.text = message;
    }
    emit('loading-message-updated', message);
  }

  /// Show progress during loading
  void showProgress(double progress, {String? message}) {
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    // Update progress bar if it exists
    final progressBar = _loadingIndicator?.querySelector('.progress-bar');
    if (progressBar != null) {
      progressBar.style.width = '${(progress * 100).round()}%';
    } else {
      // Create progress bar
      final progressContainer = html.DivElement()
        ..className = 'progress-container'
        ..style.cssText = '''
          width: 200px;
          height: 4px;
          background: #e0e0e0;
          border-radius: 2px;
          margin: 16px auto;
          overflow: hidden;
        ''';

      final bar = html.DivElement()
        ..className = 'progress-bar'
        ..style.cssText = '''
          height: 100%;
          background: #2196F3;
          width: ${(progress * 100).round()}%;
          transition: width 0.3s ease;
        ''';

      progressContainer.append(bar);
      _loadingIndicator?.insertBefore(
          progressContainer, _loadingIndicator!.lastChild);
    }

    if (message != null) {
      updateLoadingMessage(message);
    }

    emit('progress-updated', {'progress': progress, 'message': message});
  }

  /// Detect when Flutter is ready
  void _detectFlutterReady() {
    // Listen for Flutter engine ready event
    html.window.addEventListener('flutter-engine-ready', (event) {
      _onFlutterReady();
    });

    // Fallback: check for Flutter app element periodically
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      final flutterElement =
          html.document.querySelector('flutter-view[flt-renderer]') ??
              html.document.querySelector('flt-glass-pane');

      if (flutterElement != null) {
        timer.cancel();
        _onFlutterReady();
      }
    });

    // Timeout fallback
    Timer(Duration(seconds: 10), () {
      if (!_isHydrated) {
        if (kDebugMode) {
          print('ProgressiveLoader: Timeout reached, hiding skeleton anyway');
        }
        _onFlutterReady();
      }
    });
  }

  /// Handle Flutter ready event
  void _onFlutterReady() {
    if (_isHydrated) return;

    _isHydrated = true;

    // Hide skeleton with animation
    _skeletonContainer?.className = 'flutter-skeleton-container hidden';

    // Remove skeleton after animation
    Timer(Duration(milliseconds: 300), () {
      _skeletonContainer?.remove();
    });

    emit('flutter-hydrated');

    if (kDebugMode) {
      print('ProgressiveLoader: Flutter app hydrated, skeleton removed');
    }
  }

  /// Manually trigger hydration (for testing or custom scenarios)
  void triggerHydration() {
    _onFlutterReady();
  }

  /// Get loading statistics
  Map<String, dynamic> getLoadingStats() {
    return {
      'isInitialized': _isInitialized,
      'isHydrated': _isHydrated,
      'skeletonVisible': _skeletonContainer?.style.display != 'none',
    };
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _skeletonContainer?.remove();
    _loadingIndicator?.remove();
    removeAllListeners();
    _isInitialized = false;
    _isHydrated = false;
  }
}
