import 'package:flutter/material.dart';
import '../web/seo_renderer.dart';
import '../common/platform_detector.dart';

/// A widget that automatically adds SEO metadata for web crawlers
class SEOWidget extends StatefulWidget {
  /// The child widget to render
  final Widget child;

  /// Page title for SEO
  final String? title;

  /// Page description for SEO
  final String? description;

  /// Keywords for SEO (comma-separated)
  final String? keywords;

  /// Canonical URL for this page
  final String? canonicalUrl;

  /// Open Graph image URL
  final String? ogImage;

  /// Open Graph type (website, article, etc.)
  final String? ogType;

  /// Twitter card type (summary, summary_large_image, etc.)
  final String? twitterCard;

  /// Structured data (JSON-LD)
  final Map<String, dynamic>? structuredData;

  /// Custom meta tags
  final Map<String, String>? customMetaTags;

  /// Whether to render semantic HTML for crawlers
  final bool renderSemanticHTML;

  /// Semantic content for ghost DOM
  final String? semanticContent;

  const SEOWidget({
    Key? key,
    required this.child,
    this.title,
    this.description,
    this.keywords,
    this.canonicalUrl,
    this.ogImage,
    this.ogType,
    this.twitterCard,
    this.structuredData,
    this.customMetaTags,
    this.renderSemanticHTML = true,
    this.semanticContent,
  }) : super(key: key);

  @override
  State<SEOWidget> createState() => _SEOWidgetState();
}

class _SEOWidgetState extends State<SEOWidget> {
  SEORenderer? _seoRenderer;

  @override
  void initState() {
    super.initState();
    _initializeSEO();
  }

  void _initializeSEO() {
    // Only initialize SEO renderer on web platform
    if (!PlatformDetector.isWeb) return;

    try {
      _seoRenderer = SEORenderer();
      _seoRenderer!.initialize().then((_) {
        _updateSEOData();
      });
    } catch (e) {
      // SEO renderer not available, continue without SEO features
    }
  }

  void _updateSEOData() {
    if (_seoRenderer == null) return;

    // Set page title
    if (widget.title != null) {
      _seoRenderer!.setPageTitle(widget.title!);
    }

    // Set page description
    if (widget.description != null) {
      _seoRenderer!.setPageDescription(widget.description!);
    }

    // Set keywords
    if (widget.keywords != null) {
      _seoRenderer!.setMetaTag('keywords', widget.keywords!);
    }

    // Set canonical URL
    if (widget.canonicalUrl != null) {
      _seoRenderer!.setCanonicalUrl(widget.canonicalUrl!);
    }

    // Set Open Graph tags
    if (widget.ogImage != null) {
      _seoRenderer!.setOpenGraphTag('image', widget.ogImage!);
    }

    if (widget.ogType != null) {
      _seoRenderer!.setOpenGraphTag('type', widget.ogType!);
    }

    // Set Twitter Card tags
    if (widget.twitterCard != null) {
      _seoRenderer!.setTwitterCardTag('card', widget.twitterCard!);
    }

    if (widget.ogImage != null) {
      _seoRenderer!.setTwitterCardTag('image', widget.ogImage!);
    }

    // Add structured data
    if (widget.structuredData != null) {
      _seoRenderer!.addStructuredData(widget.structuredData!);
    }

    // Add custom meta tags
    if (widget.customMetaTags != null) {
      widget.customMetaTags!.forEach((name, content) {
        _seoRenderer!.setMetaTag(name, content);
      });
    }

    // Add semantic content to ghost DOM
    if (widget.renderSemanticHTML && widget.semanticContent != null) {
      _seoRenderer!.updateGhostDOM(widget.semanticContent!);
    }
  }

  @override
  void didUpdateWidget(SEOWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update SEO data if any properties changed
    if (widget.title != oldWidget.title ||
        widget.description != oldWidget.description ||
        widget.keywords != oldWidget.keywords ||
        widget.canonicalUrl != oldWidget.canonicalUrl ||
        widget.ogImage != oldWidget.ogImage ||
        widget.ogType != oldWidget.ogType ||
        widget.twitterCard != oldWidget.twitterCard ||
        widget.structuredData != oldWidget.structuredData ||
        widget.customMetaTags != oldWidget.customMetaTags ||
        widget.semanticContent != oldWidget.semanticContent) {
      _updateSEOData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _seoRenderer?.dispose();
    super.dispose();
  }
}

/// A widget that provides SEO-friendly headings
class SEOHeading extends StatelessWidget {
  /// The heading text
  final String text;

  /// The heading level (1-6)
  final int level;

  /// The text style for the heading
  final TextStyle? style;

  /// Text alignment
  final TextAlign? textAlign;

  /// Whether to add this heading to the SEO ghost DOM
  final bool addToSEO;

  const SEOHeading({
    Key? key,
    required this.text,
    required this.level,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  }) : super(key: key);

  /// Create an H1 heading
  const SEOHeading.h1(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  })  : level = 1,
        super(key: key);

  /// Create an H2 heading
  const SEOHeading.h2(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  })  : level = 2,
        super(key: key);

  /// Create an H3 heading
  const SEOHeading.h3(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  })  : level = 3,
        super(key: key);

  /// Create an H4 heading
  const SEOHeading.h4(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  })  : level = 4,
        super(key: key);

  /// Create an H5 heading
  const SEOHeading.h5(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  })  : level = 5,
        super(key: key);

  /// Create an H6 heading
  const SEOHeading.h6(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  })  : level = 6,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add heading to SEO if enabled and on web
    if (addToSEO && PlatformDetector.isWeb) {
      _addToSEO();
    }

    // Get default style for heading level
    final defaultStyle = _getDefaultStyle(context);
    final finalStyle = defaultStyle.merge(style);

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
    );
  }

  void _addToSEO() {
    try {
      // In a real implementation, you would access the SEO renderer
      // from a provider or inherited widget
      // For now, this is a placeholder
    } catch (e) {
      // SEO renderer not available, continue without SEO
    }
  }

  TextStyle _getDefaultStyle(BuildContext context) {
    final theme = Theme.of(context);

    switch (level) {
      case 1:
        return theme.textTheme.headlineLarge ??
            const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
      case 2:
        return theme.textTheme.headlineMedium ??
            const TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
      case 3:
        return theme.textTheme.headlineSmall ??
            const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
      case 4:
        return theme.textTheme.titleLarge ??
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      case 5:
        return theme.textTheme.titleMedium ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
      case 6:
        return theme.textTheme.titleSmall ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
      default:
        return theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    }
  }
}

/// A widget that provides SEO-friendly paragraphs
class SEOParagraph extends StatelessWidget {
  /// The paragraph text
  final String text;

  /// The text style
  final TextStyle? style;

  /// Text alignment
  final TextAlign? textAlign;

  /// Whether to add this paragraph to the SEO ghost DOM
  final bool addToSEO;

  const SEOParagraph({
    Key? key,
    required this.text,
    this.style,
    this.textAlign,
    this.addToSEO = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add paragraph to SEO if enabled and on web
    if (addToSEO && PlatformDetector.isWeb) {
      _addToSEO();
    }

    return Text(
      text,
      style: style,
      textAlign: textAlign,
    );
  }

  void _addToSEO() {
    try {
      // In a real implementation, you would access the SEO renderer
      // from a provider or inherited widget
      // For now, this is a placeholder
    } catch (e) {
      // SEO renderer not available, continue without SEO
    }
  }
}

/// A widget that provides SEO-friendly links
class SEOLink extends StatelessWidget {
  /// The link text
  final String text;

  /// The URL to link to
  final String url;

  /// The text style
  final TextStyle? style;

  /// Callback when the link is tapped
  final VoidCallback? onTap;

  /// Whether to add this link to the SEO ghost DOM
  final bool addToSEO;

  const SEOLink({
    Key? key,
    required this.text,
    required this.url,
    this.style,
    this.onTap,
    this.addToSEO = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add link to SEO if enabled and on web
    if (addToSEO && PlatformDetector.isWeb) {
      _addToSEO();
    }

    final theme = Theme.of(context);
    final linkStyle = (style ?? const TextStyle()).copyWith(
      color: theme.primaryColor,
      decoration: TextDecoration.underline,
    );

    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: linkStyle,
      ),
    );
  }

  void _addToSEO() {
    try {
      // In a real implementation, you would access the SEO renderer
      // from a provider or inherited widget and add the link to ghost DOM
      // For now, this is a placeholder
    } catch (e) {
      // SEO renderer not available, continue without SEO
    }
  }
}
