import 'package:flutter/material.dart';
import '../common/platform_detector.dart';
import '../web/web_optimizer.dart';
import '../desktop/window_manager.dart';
import '../widgets/drop_target.dart' as widgets;

/// A unified scaffold that adapts to different platforms
class UnifiedScaffold extends StatefulWidget {
  /// The body of the scaffold
  final Widget body;

  /// The app bar for the scaffold
  final PreferredSizeWidget? appBar;

  /// The drawer for the scaffold
  final Widget? drawer;

  /// The end drawer for the scaffold
  final Widget? endDrawer;

  /// The bottom navigation bar
  final Widget? bottomNavigationBar;

  /// The floating action button
  final Widget? floatingActionButton;

  /// The background color
  final Color? backgroundColor;

  /// Whether to show the desktop window controls
  final bool showDesktopWindowControls;

  /// Whether to enable drag and drop
  final bool enableDragAndDrop;

  /// Callback for handling dropped files
  final Function(List<String> filePaths)? onFilesDropped;

  /// Whether to enable web optimizations
  final bool enableWebOptimizations;

  /// Whether to show mobile safe area
  final bool showMobileSafeArea;

  /// Custom window title for desktop
  final String? windowTitle;

  /// Whether the window can be resized (desktop only)
  final bool resizable;

  /// Minimum window size (desktop only)
  final Size? minimumSize;

  /// Maximum window size (desktop only)
  final Size? maximumSize;

  /// Whether to enable progressive loading on web
  final bool enableProgressiveLoading;

  /// Loading widget to show during progressive loading
  final Widget? loadingWidget;

  const UnifiedScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.showDesktopWindowControls = true,
    this.enableDragAndDrop = false,
    this.onFilesDropped,
    this.enableWebOptimizations = true,
    this.showMobileSafeArea = true,
    this.windowTitle,
    this.resizable = true,
    this.minimumSize,
    this.maximumSize,
    this.enableProgressiveLoading = false,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<UnifiedScaffold> createState() => _UnifiedScaffoldState();
}

class _UnifiedScaffoldState extends State<UnifiedScaffold> {
  WebOptimizer? _webOptimizer;
  WindowManager? _windowManager;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePlatformSpecificFeatures();
  }

  void _initializePlatformSpecificFeatures() {
    // Initialize web optimizations
    if (PlatformDetector.isWeb && widget.enableWebOptimizations) {
      _initializeWebOptimizations();
    }

    // Initialize desktop window management
    if (PlatformDetector.isDesktop && widget.showDesktopWindowControls) {
      _initializeDesktopFeatures();
    }

    // Initialize progressive loading
    if (widget.enableProgressiveLoading) {
      _initializeProgressiveLoading();
    }
  }

  void _initializeWebOptimizations() {
    try {
      _webOptimizer = WebOptimizer.instance;
      _webOptimizer!.initialize();
    } catch (e) {
      // Web optimizer not available
    }
  }

  void _initializeDesktopFeatures() {
    try {
      _windowManager = WindowManager();
      _windowManager!.initialize().then((_) {
        _configureWindow();
      });
    } catch (e) {
      // Window manager not available
    }
  }

  void _configureWindow() {
    if (_windowManager == null) return;

    // Set window title
    if (widget.windowTitle != null) {
      _windowManager!.setTitle(widget.windowTitle!);
    }

    // Set window properties
    _windowManager!.setResizable(widget.resizable);

    if (widget.minimumSize != null) {
      _windowManager!.setMinimumSize(
        widget.minimumSize!.width.toInt(),
        widget.minimumSize!.height.toInt(),
      );
    }

    if (widget.maximumSize != null) {
      _windowManager!.setMaximumSize(
        widget.maximumSize!.width.toInt(),
        widget.maximumSize!.height.toInt(),
      );
    }
  }

  void _initializeProgressiveLoading() {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate progressive loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget scaffold = _buildBaseScaffold();

    // Wrap with drag and drop if enabled
    if (widget.enableDragAndDrop && widget.onFilesDropped != null) {
      scaffold = widgets.DropTarget(
        onDropFiles: widget.onFilesDropped!,
        child: scaffold,
      );
    }

    // Wrap with safe area for mobile
    if (PlatformDetector.isMobile && widget.showMobileSafeArea) {
      scaffold = SafeArea(child: scaffold);
    }

    // Show loading overlay during progressive loading
    if (_isLoading && widget.loadingWidget != null) {
      scaffold = Stack(
        children: [
          scaffold,
          Container(
            color: Colors.black54,
            child: Center(
              child: widget.loadingWidget!,
            ),
          ),
        ],
      );
    }

    return scaffold;
  }

  Widget _buildBaseScaffold() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: widget.body,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
      backgroundColor: widget.backgroundColor,
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (widget.appBar == null) return null;

    // On desktop, add window controls to the app bar
    if (PlatformDetector.isDesktop && widget.showDesktopWindowControls) {
      return _DesktopAppBar(
        child: widget.appBar!,
        windowManager: _windowManager,
      );
    }

    return widget.appBar;
  }

  @override
  void dispose() {
    _webOptimizer?.dispose();
    _windowManager?.dispose();
    super.dispose();
  }
}

/// Custom app bar for desktop with window controls
class _DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;
  final WindowManager? windowManager;

  const _DesktopAppBar({
    required this.child,
    this.windowManager,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Window controls
        Positioned(
          top: 0,
          right: 0,
          child: _WindowControls(windowManager: windowManager),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => child.preferredSize;
}

/// Desktop window controls (minimize, maximize, close)
class _WindowControls extends StatelessWidget {
  final WindowManager? windowManager;

  const _WindowControls({this.windowManager});

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isDesktop) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.minimize,
          onPressed: () => windowManager?.minimize(),
        ),
        _WindowButton(
          icon: Icons.crop_square,
          onPressed: () => windowManager?.maximize(),
        ),
        _WindowButton(
          icon: Icons.close,
          onPressed: () => windowManager?.hide(),
          isClose: true,
        ),
      ],
    );
  }
}

/// Individual window control button
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    Color iconColor = Colors.grey;

    if (_isHovered) {
      backgroundColor =
          widget.isClose ? Colors.red : Colors.grey.withValues(alpha: 0.2);
      iconColor = widget.isClose ? Colors.white : Colors.black;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          color: backgroundColor,
          child: Icon(
            widget.icon,
            size: 16,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// A responsive layout widget that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  /// Widget for mobile layout (width < 768)
  final Widget mobile;

  /// Widget for tablet layout (768 <= width < 1024)
  final Widget? tablet;

  /// Widget for desktop layout (width >= 1024)
  final Widget? desktop;

  /// Custom breakpoints
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBreakpoint = 768,
    this.tabletBreakpoint = 1024,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= tabletBreakpoint && desktop != null) {
      return desktop!;
    } else if (screenWidth >= mobileBreakpoint && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// A widget that adapts its behavior based on the current platform
class PlatformAdaptiveWidget extends StatelessWidget {
  /// Widget for mobile platforms
  final Widget? mobile;

  /// Widget for web platform
  final Widget? web;

  /// Widget for desktop platforms
  final Widget? desktop;

  /// Fallback widget if platform-specific widget is not provided
  final Widget fallback;

  const PlatformAdaptiveWidget({
    Key? key,
    this.mobile,
    this.web,
    this.desktop,
    required this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformDetector.isMobile && mobile != null) {
      return mobile!;
    } else if (PlatformDetector.isWeb && web != null) {
      return web!;
    } else if (PlatformDetector.isDesktop && desktop != null) {
      return desktop!;
    } else {
      return fallback;
    }
  }
}

/// A builder widget that provides platform information
class PlatformBuilder extends StatelessWidget {
  /// Builder function that receives platform information
  final Widget Function(BuildContext context, PlatformInfo platform) builder;

  const PlatformBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = PlatformInfo(
      isMobile: PlatformDetector.isMobile,
      isWeb: PlatformDetector.isWeb,
      isDesktop: PlatformDetector.isDesktop,
      isAndroid: PlatformDetector.isAndroid,
      isIOS: PlatformDetector.isIOS,
      isLinux: PlatformDetector.isLinux,
      isMacOS: PlatformDetector.isMacOS,
      isWindows: PlatformDetector.isWindows,
      screenSize: MediaQuery.of(context).size,
    );

    return builder(context, platform);
  }
}

/// Platform information for PlatformBuilder
class PlatformInfo {
  final bool isMobile;
  final bool isWeb;
  final bool isDesktop;
  final bool isAndroid;
  final bool isIOS;
  final bool isLinux;
  final bool isMacOS;
  final bool isWindows;
  final Size screenSize;

  const PlatformInfo({
    required this.isMobile,
    required this.isWeb,
    required this.isDesktop,
    required this.isAndroid,
    required this.isIOS,
    required this.isLinux,
    required this.isMacOS,
    required this.isWindows,
    required this.screenSize,
  });

  /// Whether the screen is mobile-sized (width < 768)
  bool get isMobileScreen => screenSize.width < 768;

  /// Whether the screen is tablet-sized (768 <= width < 1024)
  bool get isTabletScreen => screenSize.width >= 768 && screenSize.width < 1024;

  /// Whether the screen is desktop-sized (width >= 1024)
  bool get isDesktopScreen => screenSize.width >= 1024;
}
