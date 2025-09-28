# 🚀 Flutter Unify - The Ultimate Unified API

[![pub package](https://img.shields.io/pub/v/flutter_unify.svg)](https://pub.dev/packages/flutter_unify)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](https://flutter.dev/docs/development/tools/sdk/release-notes)

**Flutter Unify** is not just another package - it's a **complete development platform** that provides a single, consistent API surface for all your cross-platform development needs. Think of it as **Bloc for everything else** - authentication, notifications, storage, networking, and so much more.

## 🌟 Why Flutter Unify is Legendary

### 🧩 One API, All Platforms
```dart
// Authentication - works the same everywhere
await Unify.auth.signInWithGoogle();
await Unify.auth.signInWithApple();
await Unify.auth.signInWithBiometrics();

// Notifications - unified across all platforms
await Unify.notifications.show('Hello World!');

// System monitoring - reactive streams everywhere
Unify.system.onConnectivityChanged.listen((state) {
  print('Network: ${state.description}');
});
```

### 🔄 Everything is Reactive
Just like BlocBuilder for state management, everything in Flutter Unify is stream-based:

```dart
// Listen to auth state changes
StreamBuilder<AuthStateChangeEvent>(
  stream: Unify.auth.onAuthStateChanged,
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data!.user != null) {
      return DashboardScreen();
    }
    return LoginScreen();
  },
);

// Monitor battery level
StreamBuilder<BatteryState>(
  stream: Unify.system.onBatteryChanged,
  builder: (context, snapshot) {
    final battery = snapshot.data;
    return Text('Battery: ${battery?.percentage ?? 0}%');
  },
);
```

### 🔌 Pluggable Architecture
Swap backends without changing a single line of your app code:

```dart
// Switch from Firebase to Supabase
Unify.registerAdapter('auth', SupabaseAuthAdapter());

// Use different storage backends
Unify.registerAdapter('storage', HiveStorageAdapter());
Unify.registerAdapter('storage', SqliteStorageAdapter());

// Custom implementations
Unify.registerAdapter('auth', MyCustomAuthAdapter());
```

### 🏗️ Legendary Developer Experience

**Powerful CLI Tools:**
```bash
# Create a new project with everything set up
dart run flutter_unify:cli create my_app --template=full

# Add features to existing project
dart run flutter_unify:cli add auth notifications storage

# Generate custom adapters
dart run flutter_unify:cli generate adapter --type=auth --name=MyAuthAdapter

# Validate your setup
dart run flutter_unify:cli doctor

# Run cross-platform tests
dart run flutter_unify:cli test --platforms=web,android,ios
```

## 🚀 Features

### 🔹 Web Enhancements

#### Smart Bundling & Compression
- Advanced tree-shaking & compression strategies (leveraging esbuild/rollup under the hood)
- Splits core Flutter engine from app logic → only downloads once, cached separately
- Intelligent code splitting for optimal loading performance

#### SEO-friendly Rendering Layer
- Hybrid rendering: Canvas for UI but also exports semantic HTML "ghost DOM" for crawlers
- Works like a built-in version of seo_renderer, but official and maintained
- Automatic meta tag generation and structured data support

#### Progressive Loading (Lite Mode)
- Ships a lightweight HTML/JS "skeleton" that loads instantly on low-bandwidth
- Flutter app hydrates later for full functionality
- Think of it like Next.js SSR → but for Flutter

#### Cross-browser Polyfills
- Provides stable wrappers for APIs (FileSystem, Bluetooth, WebRTC) with graceful fallbacks
- Consistent behavior across all modern browsers

### 🔹 Desktop Enhancements

#### Unified System Menus & Tray API
- One API → maps to macOS menu bar, Windows system tray, Linux DBus indicators
- Global shortcuts supported out of the box
- Context menus with native look and feel

#### Native Drag & Drop
- First-class drag-drop API (text, files, URLs) that works consistently across macOS/Win/Linux
- Custom drag indicators and drop zones
- Multi-selection support

#### Window & Multi-monitor Manager
- Advanced window snapping, tiling, multi-window support
- Auto-detects OS capabilities (Aero Snap on Windows, Mission Control on macOS)
- Per-monitor DPI awareness

#### System Services Bridge
- Clipboard, notifications, file dialogs, screen capture → exposed via one stable API
- No need to import 5+ separate packages
- Native system integration without complexity

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_unify: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## 🎯 Quick Start

### Basic Setup

```dart
import 'package:flutter_unify/flutter_unify.dart';

void main() async {
  // Initialize Flutter Unify
  await Unify.initialize();
  
  runApp(MyApp());
}
```

### Cross-Platform System Operations

```dart
import 'package:flutter_unify/flutter_unify.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UnifiedScaffold(
      body: ElevatedButton(
        onPressed: () async {
          // Works on all platforms
          await Unify.system.clipboardWriteText('Hello World!');
          await Unify.system.showNotification(
            title: 'Success',
            body: 'Text copied to clipboard!',
          );
        },
        child: Text('Copy to Clipboard'),
      ),
    );
  }
}
```

### Platform-Specific Features

```dart
class PlatformSpecificFeatures extends StatefulWidget {
  @override
  _PlatformSpecificFeaturesState createState() => _PlatformSpecificFeaturesState();
}

class _PlatformSpecificFeaturesState extends State<PlatformSpecificFeatures> {
  @override
  void initState() {
    super.initState();
    _setupPlatformFeatures();
  }
  
  void _setupPlatformFeatures() async {
    // Web-specific optimizations
    if (PlatformDetector.isWeb) {
      Unify.web.seo.setPageTitle('My Flutter App');
      Unify.web.seo.setPageDescription('A unified Flutter experience');
      await Unify.web.progressiveLoader.initialize();
    }
    
    // Desktop integration
    if (PlatformDetector.isDesktop) {
      await Unify.desktop.systemTray.create(
        icon: 'assets/tray_icon.png',
        tooltip: 'My Flutter App',
      );
      
      await Unify.desktop.shortcuts.register(
        'Ctrl+Shift+A',
        () => print('Global shortcut activated!'),
      );
    }
    
    // Mobile features
    if (PlatformDetector.isMobile) {
      final deviceInfo = await Unify.mobile.deviceInfo.getDeviceInfo();
      print('Running on: ${deviceInfo.model}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return UnifiedScaffold(
      enableDragAndDrop: true,
      onFilesDropped: (files) => print('Files dropped: ${files.length}'),
      body: PlatformAdaptiveWidget(
        mobile: Text('Mobile UI'),
        web: Text('Web UI'),
        desktop: Text('Desktop UI'),
        fallback: Text('Universal UI'),
      ),
    );
  }
}
```

## 📚 Documentation

- [Web Optimizations Guide](https://pub.dev/documentation/flutter_unify/latest/web/web-library.html)
- [Desktop Integration Guide](https://pub.dev/documentation/flutter_unify/latest/desktop/desktop-library.html)
- [API Reference](https://pub.dev/documentation/flutter_unify/latest/)
- [Examples](https://github.com/flutter/flutter_unify/tree/main/example)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [window_manager](https://pub.dev/packages/window_manager) - Window management (complementary)
- [system_tray](https://pub.dev/packages/system_tray) - System tray integration (alternative)
- [seo_renderer](https://pub.dev/packages/seo_renderer) - SEO rendering (alternative)

## 🆘 Support

- [GitHub Issues](https://github.com/flutter/flutter_unify/issues)
- [Flutter Community Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter+flutter-unify)
# FLUTTER_UNIFY
