# Flutter Unify - Developer Experience Toolkit

## 🛠️ CLI Tools

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_unify: ^1.0.0

dev_dependencies:
  flutter_unify_cli: ^1.0.0  # Coming soon
```

### Quick Setup

```bash
# Initialize a new Flutter Unify project
flutter pub run flutter_unify:init

# Add unified APIs to existing project
flutter pub run flutter_unify:add auth notifications storage

# Generate platform-specific configurations
flutter pub run flutter_unify:generate-config

# Validate unified API usage
flutter pub run flutter_unify:validate

# Run cross-platform tests
flutter pub run flutter_unify:test-all-platforms
```

## 📱 Project Templates

### Full-Featured App Template

```bash
flutter create --template=flutter_unify my_app
cd my_app
flutter pub run flutter_unify:init --features=all
```

### Minimal Starter Template

```bash
flutter create --template=flutter_unify_minimal my_app
cd my_app
flutter pub run flutter_unify:init --features=basic
```

### Enterprise Template

```bash
flutter create --template=flutter_unify_enterprise my_app
cd my_app
flutter pub run flutter_unify:init --features=enterprise
```

## 🔧 Development Tools

### 1. VS Code Extension

Install the **Flutter Unify** VS Code extension for:

- 🎯 Smart auto-completion for unified APIs
- 🚀 Code snippets for common patterns
- 🔍 Real-time validation and warnings
- 📊 Platform capability detection
- 🛠️ Quick actions and refactoring

```json
// .vscode/settings.json
{
  "flutter-unify.enableSmartCompletion": true,
  "flutter-unify.validateOnSave": true,
  "flutter-unify.showPlatformWarnings": true
}
```

### 2. Flutter Inspector Integration

Enhanced Flutter Inspector with unified API insights:

```dart
// Enable unified API debugging
UnifiedAuth.instance.enableDebugMode();
UnifiedStorage.instance.enableVerboseLogging();
UnifiedNetworking.instance.enableRequestLogging();
```

### 3. DevTools Integration

Custom DevTools panel for Flutter Unify:

- 📊 Real-time API usage statistics
- 🌐 Network request monitoring
- 💾 Storage inspection
- 🔐 Auth state visualization
- 📱 Background task monitoring

## 🎯 Code Snippets

### VS Code Snippets

Create `.vscode/flutter_unify.code-snippets`:

```json
{
  "Unified Auth Setup": {
    "prefix": "fu-auth-init",
    "body": [
      "// Initialize authentication",
      "await UnifiedAuth.instance.initialize();",
      "",
      "// Listen to auth state changes",
      "UnifiedAuth.instance.authStateChanges.listen((user) {",
      "  if (user != null) {",
      "    print('User signed in: \\${user.email}');",
      "  } else {",
      "    print('User signed out');",
      "  }",
      "});"
    ],
    "description": "Initialize unified authentication"
  },

  "Unified Notification": {
    "prefix": "fu-notification",
    "body": [
      "await UnifiedNotifications.instance.show(",
      "  '${1:title}',",
      "  body: '${2:message}',",
      "  data: {'${3:key}': '${4:value}'},",
      ");"
    ],
    "description": "Send a unified notification"
  },

  "Unified Storage": {
    "prefix": "fu-storage",
    "body": [
      "// Store data",
      "await UnifiedStorage.instance.setJson('${1:key}', {",
      "  '${2:field}': '${3:value}',",
      "});",
      "",
      "// Retrieve data",
      "final data = await UnifiedStorage.instance.getJson('${1:key}');"
    ],
    "description": "Use unified storage"
  },

  "Unified HTTP Request": {
    "prefix": "fu-http",
    "body": [
      "final response = await UnifiedNetworking.instance.${1|get,post,put,delete|}(",
      "  '${2:url}',",
      "  headers: {'Authorization': 'Bearer \\$token'},",
      ");",
      "",
      "if (response.isSuccess) {",
      "  final data = response.getData<Map<String, dynamic>>();",
      "  // Handle success",
      "} else {",
      "  // Handle error: \\${response.error}",
      "}"
    ],
    "description": "Make unified HTTP request"
  }
}
```

## 🧪 Testing Utilities

### Unified Test Helpers

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';
import 'package:flutter_unify/testing.dart';

void main() {
  group('Unified APIs Tests', () {
    setUp(() async {
      // Initialize test environment
      await UnifiedTestHelper.setUp();
    });

    tearDown(() async {
      // Clean up test environment
      await UnifiedTestHelper.tearDown();
    });

    testWidgets('Authentication flow', (tester) async {
      // Mock auth provider
      UnifiedTestHelper.mockAuthProvider();
      
      // Test sign in
      final result = await UnifiedAuth.instance.signInAnonymously();
      expect(result.success, isTrue);
      
      // Verify auth state
      expect(UnifiedAuth.instance.isSignedIn, isTrue);
    });

    test('Storage operations', () async {
      // Test data storage
      await UnifiedStorage.instance.setString('test_key', 'test_value');
      final value = await UnifiedStorage.instance.getString('test_key');
      expect(value, equals('test_value'));
    });

    test('Network requests', () async {
      // Mock network responses
      UnifiedTestHelper.mockHttpResponse(
        url: 'https://api.example.com/data',
        response: {'status': 'success'},
      );
      
      final response = await UnifiedNetworking.instance.get(
        'https://api.example.com/data',
      );
      
      expect(response.isSuccess, isTrue);
      expect(response.getData()['status'], equals('success'));
    });

    testWidgets('Media access', (tester) async {
      // Mock file picker
      UnifiedTestHelper.mockFilePicker([
        MockFile(name: 'test.jpg', bytes: Uint8List(100)),
      ]);
      
      final result = await UnifiedMedia.instance.pickFiles();
      expect(result.success, isTrue);
      expect(result.files?.length, equals(1));
    });
  });
}
```

### Integration Testing

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('Complete app flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test authentication
      await tester.tap(find.text('🔐 Authentication'));
      await tester.pumpAndSettle();
      
      // Verify auth state change
      expect(find.text('✅ Anonymous sign in successful'), findsOneWidget);

      // Test notifications
      await tester.tap(find.text('📱 Notifications'));
      await tester.pumpAndSettle();
      
      // Test storage
      await tester.tap(find.text('💾 Storage'));
      await tester.pumpAndSettle();

      // Test networking
      await tester.tap(find.text('🌐 Networking'));
      await tester.pumpAndSettle();
    });
  });
}
```

## 📊 Performance Monitoring

### Built-in Analytics

```dart
// Enable performance monitoring
UnifiedAnalytics.instance.initialize(
  trackingId: 'your-tracking-id',
  enablePerformanceMonitoring: true,
);

// Track custom events
UnifiedAnalytics.instance.track('feature_used', {
  'feature': 'notifications',
  'platform': PlatformDetector.isWeb ? 'web' : 'native',
});

// Monitor API performance
UnifiedAnalytics.instance.timeOperation('auth_sign_in', () async {
  return await UnifiedAuth.instance.signInWithGoogle();
});
```

### Performance Dashboard

Access real-time performance metrics at:
- 📊 API response times
- 💾 Storage operation latency
- 📱 Notification delivery rates
- 🌐 Network request success rates
- 🔐 Authentication conversion rates

## 🔍 Debugging Tools

### Debug Console

```dart
// Enable debug mode for all services
if (kDebugMode) {
  UnifiedAuth.instance.enableDebugMode();
  UnifiedStorage.instance.enableVerboseLogging();
  UnifiedNetworking.instance.enableRequestLogging();
  UnifiedMedia.instance.enableDebugMode();
  UnifiedBackgroundServices.instance.enableDebugMode();
}
```

### Network Inspector

```dart
// Add request interceptor for debugging
UnifiedNetworking.instance.addInterceptor(
  DebugNetworkInterceptor(
    logRequests: true,
    logResponses: true,
    logErrors: true,
  ),
);
```

### Storage Inspector

```dart
// Inspect storage contents
if (kDebugMode) {
  final inspector = UnifiedStorageInspector();
  await inspector.exportStorageContents('./storage_dump.json');
  inspector.printStorageStats();
}
```

## 🚀 Deployment Tools

### Build Scripts

```bash
#!/bin/bash
# scripts/build-all-platforms.sh

echo "🏗️ Building Flutter Unify app for all platforms..."

# Web
echo "📱 Building for Web..."
flutter build web --release

# Android
echo "🤖 Building for Android..."
flutter build apk --release
flutter build appbundle --release

# iOS
echo "🍎 Building for iOS..."
flutter build ios --release

# Desktop
echo "💻 Building for Desktop..."
flutter build windows --release
flutter build macos --release
flutter build linux --release

echo "✅ All builds completed!"
```

### Deployment Configuration

```yaml
# deployment/config.yaml
environments:
  development:
    notifications:
      firebase_project: "your-dev-project"
    storage:
      encryption_key: "dev-key"
    auth:
      google_client_id: "dev-client-id"
  
  production:
    notifications:
      firebase_project: "your-prod-project"
    storage:
      encryption_key: "prod-key"
    auth:
      google_client_id: "prod-client-id"
```

## 📚 Documentation Generator

### API Documentation

```bash
# Generate comprehensive API documentation
flutter pub run flutter_unify:generate-docs

# Generate platform-specific guides
flutter pub run flutter_unify:generate-platform-docs --platform=web
flutter pub run flutter_unify:generate-platform-docs --platform=mobile
flutter pub run flutter_unify:generate-platform-docs --platform=desktop
```

### Interactive Examples

```bash
# Generate interactive example gallery
flutter pub run flutter_unify:generate-examples

# Create custom example
flutter pub run flutter_unify:create-example --name=my_example --features=auth,storage
```

## 🎨 Design System

### Unified Theme Generator

```dart
// Generate platform-adaptive themes
final theme = UnifiedThemeGenerator.generate(
  primaryColor: Colors.blue,
  adaptToMaterial3: true,
  adaptToCupertino: true,
  adaptToFluent: true,
);

MaterialApp(
  theme: theme.materialTheme,
  // ...
);
```

### Component Library

```dart
// Use unified components that adapt to platform
UnifiedButton(
  onPressed: () {},
  child: Text('Click me'),
  style: UnifiedButtonStyle.primary,
);

UnifiedCard(
  child: Text('Platform-adaptive card'),
  elevation: 4,
);

UnifiedNavigationBar(
  items: [
    UnifiedNavigationItem(icon: Icons.home, label: 'Home'),
    UnifiedNavigationItem(icon: Icons.settings, label: 'Settings'),
  ],
);
```

## 🔒 Security Tools

### Security Audit

```bash
# Run security audit
flutter pub run flutter_unify:security-audit

# Check for common vulnerabilities
flutter pub run flutter_unify:security-check --verbose

# Generate security report
flutter pub run flutter_unify:security-report --output=security_report.html
```

### Encryption Utilities

```dart
// Built-in encryption for sensitive data
final encrypted = await UnifiedCrypto.encrypt('sensitive data');
final decrypted = await UnifiedCrypto.decrypt(encrypted);

// Secure key management
final keyManager = UnifiedKeyManager.instance;
await keyManager.storeKey('api_key', 'secret_value');
final key = await keyManager.getKey('api_key');
```

## 📈 Analytics and Insights

### Usage Analytics

```dart
// Track feature usage
UnifiedAnalytics.instance.trackFeatureUsage('notifications', {
  'platform': PlatformDetector.currentPlatform,
  'success': true,
});

// Track performance metrics
UnifiedAnalytics.instance.trackPerformance('storage_write', {
  'duration_ms': 150,
  'data_size_bytes': 1024,
});
```

### A/B Testing

```dart
// Configure A/B tests
final experiment = await UnifiedExperiments.instance.getExperiment('new_ui');
if (experiment.variant == 'A') {
  // Show variant A
} else {
  // Show variant B
}
```

## 🎯 Best Practices Enforcer

### Lint Rules

```yaml
# analysis_options.yaml
include: package:flutter_unify_lints/recommended.yaml

flutter_unify_custom_lint:
  rules:
    - require_unified_apis: true
    - prefer_unified_storage: true
    - avoid_platform_specific_code: true
    - require_error_handling: true
```

### Code Quality Metrics

```bash
# Run code quality analysis
flutter pub run flutter_unify:quality-check

# Generate quality report
flutter pub run flutter_unify:quality-report --format=html
```

## 🚀 Migration Tools

### From Existing Packages

```bash
# Migrate from firebase_auth to UnifiedAuth
flutter pub run flutter_unify:migrate firebase_auth

# Migrate from shared_preferences to UnifiedStorage
flutter pub run flutter_unify:migrate shared_preferences

# Migrate from http to UnifiedNetworking
flutter pub run flutter_unify:migrate http
```

This comprehensive developer experience toolkit makes Flutter Unify truly "best in class" by providing developers with everything they need to build, test, deploy, and maintain cross-platform Flutter applications efficiently.
