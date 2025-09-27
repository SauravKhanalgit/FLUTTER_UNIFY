import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../common/event_emitter.dart';

/// SEO-friendly rendering layer for Flutter web apps
class SEORenderer extends EventEmitter {
  bool _isInitialized = false;
  html.Element? _ghostDOM;
  final Map<String, String> _metaTags = {};
  final List<String> _structuredData = [];

  /// Check if SEO renderer is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the SEO renderer
  Future<void> initialize() async {
    if (!kIsWeb) {
      throw UnsupportedError('SEORenderer can only be used on web platforms');
    }

    if (_isInitialized) return;

    await _createGhostDOM();
    _setupDefaultMetaTags();
    _injectStructuredData();

    _isInitialized = true;
    emit('seo-initialized');

    if (kDebugMode) {
      print('SEORenderer: Initialized with ghost DOM');
    }
  }

  /// Create a hidden DOM structure for search engine crawlers
  Future<void> _createGhostDOM() async {
    _ghostDOM = html.DivElement()
      ..id = 'flutter-seo-ghost'
      ..style.display = 'none'
      ..setAttribute('aria-hidden', 'true')
      ..setAttribute('data-flutter-seo', 'true');

    html.document.body?.append(_ghostDOM!);
  }

  /// Setup default meta tags for SEO
  void _setupDefaultMetaTags() {
    setMetaTag('viewport', 'width=device-width, initial-scale=1.0');
    setMetaTag('robots', 'index, follow');
    setMetaTag('googlebot', 'index, follow');
    setMetaTag('theme-color', '#ffffff');
  }

  /// Set a meta tag
  void setMetaTag(String name, String content) {
    _metaTags[name] = content;

    // Update or create the meta tag in the document
    html.MetaElement? meta =
        html.document.querySelector('meta[name="$name"]') as html.MetaElement?;

    if (meta == null) {
      meta = html.MetaElement()..name = name;
      html.document.head?.append(meta);
    }

    meta.content = content;

    emit('meta-tag-updated', {'name': name, 'content': content});
  }

  /// Set Open Graph meta tag
  void setOpenGraphTag(String property, String content) {
    final name = 'og:$property';
    _metaTags[name] = content;

    html.MetaElement? meta = html.document
        .querySelector('meta[property="$name"]') as html.MetaElement?;

    if (meta == null) {
      meta = html.MetaElement()..setAttribute('property', name);
      html.document.head?.append(meta);
    }

    meta.content = content;

    emit('og-tag-updated', {'property': property, 'content': content});
  }

  /// Set Twitter Card meta tag
  void setTwitterCardTag(String name, String content) {
    final tagName = 'twitter:$name';
    _metaTags[tagName] = content;

    html.MetaElement? meta = html.document
        .querySelector('meta[name="$tagName"]') as html.MetaElement?;

    if (meta == null) {
      meta = html.MetaElement()..name = tagName;
      html.document.head?.append(meta);
    }

    meta.content = content;

    emit('twitter-tag-updated', {'name': name, 'content': content});
  }

  /// Add structured data (JSON-LD)
  void addStructuredData(Map<String, dynamic> data) {
    final jsonLD = _mapToJsonLD(data);
    _structuredData.add(jsonLD);

    final script = html.ScriptElement()
      ..type = 'application/ld+json'
      ..text = jsonLD;

    html.document.head?.append(script);

    emit('structured-data-added', data);
  }

  /// Convert map to JSON-LD string
  String _mapToJsonLD(Map<String, dynamic> data) {
    // Add @context if not present
    if (!data.containsKey('@context')) {
      data['@context'] = 'https://schema.org';
    }

    // Simple JSON encoding (in a real implementation, use dart:convert)
    return _encodeJson(data);
  }

  /// Simple JSON encoding
  String _encodeJson(dynamic value) {
    if (value is String) {
      return '"${value.replaceAll('"', '\\"')}"';
    } else if (value is num) {
      return value.toString();
    } else if (value is bool) {
      return value.toString();
    } else if (value is Map) {
      final pairs =
          value.entries.map((e) => '"${e.key}": ${_encodeJson(e.value)}');
      return '{${pairs.join(', ')}}';
    } else if (value is List) {
      final items = value.map((e) => _encodeJson(e));
      return '[${items.join(', ')}]';
    } else {
      return 'null';
    }
  }

  /// Update ghost DOM with semantic content
  void updateGhostDOM(String content,
      {String? tag = 'div', Map<String, String>? attributes}) {
    if (_ghostDOM == null) return;

    final element = html.Element.tag(tag!)..innerHtml = content;

    if (attributes != null) {
      attributes.forEach((key, value) {
        element.setAttribute(key, value);
      });
    }

    _ghostDOM!.append(element);

    emit('ghost-dom-updated', {'content': content, 'tag': tag});
  }

  /// Add heading to ghost DOM
  void addHeading(String text, int level) {
    if (level < 1 || level > 6) level = 1;
    updateGhostDOM(text, tag: 'h$level');
  }

  /// Add paragraph to ghost DOM
  void addParagraph(String text) {
    updateGhostDOM(text, tag: 'p');
  }

  /// Add navigation structure to ghost DOM
  void addNavigation(List<Map<String, String>> links) {
    final nav = html.Element.tag('nav')..setAttribute('role', 'navigation');

    final ul = html.UListElement();
    for (final link in links) {
      final li = html.LIElement();
      final a = html.AnchorElement()
        ..href = link['href'] ?? '#'
        ..text = link['text'] ?? '';
      li.append(a);
      ul.append(li);
    }

    nav.append(ul);
    _ghostDOM?.append(nav);

    emit('navigation-added', links);
  }

  /// Add breadcrumbs to ghost DOM
  void addBreadcrumbs(List<Map<String, String>> breadcrumbs) {
    final nav = html.Element.tag('nav')
      ..setAttribute('aria-label', 'breadcrumb');

    final ol = html.OListElement();
    for (int i = 0; i < breadcrumbs.length; i++) {
      final breadcrumb = breadcrumbs[i];
      final li = html.LIElement();

      if (i == breadcrumbs.length - 1) {
        // Last item (current page)
        li.text = breadcrumb['text'] ?? '';
        li.setAttribute('aria-current', 'page');
      } else {
        final a = html.AnchorElement()
          ..href = breadcrumb['href'] ?? '#'
          ..text = breadcrumb['text'] ?? '';
        li.append(a);
      }

      ol.append(li);
    }

    nav.append(ol);
    _ghostDOM?.append(nav);

    emit('breadcrumbs-added', breadcrumbs);
  }

  /// Inject structured data scripts
  void _injectStructuredData() {
    // Add default website structured data
    addStructuredData({
      '@type': 'WebApplication',
      'name': html.document.title,
      'url': html.window.location.href,
      'applicationCategory': 'WebApplication',
      'operatingSystem': 'Web Browser',
    });
  }

  /// Set page title and update meta tags
  void setPageTitle(String title) {
    html.document.title = title;
    setMetaTag('title', title);
    setOpenGraphTag('title', title);
    setTwitterCardTag('title', title);
  }

  /// Set page description
  void setPageDescription(String description) {
    setMetaTag('description', description);
    setOpenGraphTag('description', description);
    setTwitterCardTag('description', description);
  }

  /// Set canonical URL
  void setCanonicalUrl(String url) {
    html.LinkElement? canonical = html.document
        .querySelector('link[rel="canonical"]') as html.LinkElement?;

    if (canonical == null) {
      canonical = html.LinkElement()..rel = 'canonical';
      html.document.head?.append(canonical);
    }

    canonical.href = url;
    setOpenGraphTag('url', url);
  }

  /// Get current meta tags
  Map<String, String> getMetaTags() => Map.from(_metaTags);

  /// Clear ghost DOM
  void clearGhostDOM() {
    _ghostDOM?.children.clear();
    emit('ghost-dom-cleared');
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _ghostDOM?.remove();
    _metaTags.clear();
    _structuredData.clear();
    removeAllListeners();
    _isInitialized = false;
  }
}
