/// 🚀 Flutter Unify - The Ultimate Unified API
///
/// Flutter Unify provides a single, consistent API surface for all your
/// cross-platform development needs. Like Bloc for state management,
/// but for everything else.
///
/// ## Features
///
/// ### 🧩 Unified API Surface
/// ```dart
/// // One API, all platforms
/// await Unify.auth.signIn();
/// await Unify.notifications.show('Hello');
/// Unify.system.onConnectivityChanged.listen(...);
/// ```
///
/// ### 🔄 Reactive Streams
/// ```dart
/// // Everything is a stream
/// Unify.system.onBatteryChanged.listen((level) => ...);
/// Unify.auth.onAuthStateChanged.listen((user) => ...);
/// Unify.files.onDownloadProgress.listen((progress) => ...);
/// ```
///
/// ### 🔌 Pluggable Adapters
/// ```dart
/// // Swap backends easily
/// Unify.registerAdapter('auth', FirebaseAuthAdapter());
/// Unify.registerAdapter('storage', SupabaseAdapter());
/// ```
///
/// ### 🏗️ Developer Experience
/// ```bash
/// # Legendary CLI tools
/// dart run flutter_unify:cli create my_app --template=full
/// dart run flutter_unify:cli add auth notifications
/// dart run flutter_unify:cli generate adapter --type=auth
/// ```
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_unify/flutter_unify.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Initialize with configuration
///   await Unify.initialize(
///     config: UnifyConfig(
///       enableOfflineSync: true,
///       enableAnalytics: false,
///     ),
///   );
///
///   runApp(MyApp());
/// }
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: StreamBuilder(
///         stream: Unify.auth.onAuthStateChanged,
///         builder: (context, snapshot) {
///           if (snapshot.hasData) {
///             return DashboardScreen();
///           }
///           return LoginScreen();
///         },
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Legendary Features
///
/// - 🌐 **Cross-app Communication**: Apps can talk to each other
/// - 🤖 **AI Integration**: Built-in ML/AI hooks for smart features
/// - 🎨 **Adaptive Theming**: Themes that adapt to user preferences
/// - 🔒 **Unified Security**: End-to-end encryption out of the box
/// - 📱 **Device Integration**: Deep OS integration on all platforms
/// - 🧪 **Advanced Testing**: Cross-platform testing made easy
/// - 📊 **DevTools Integration**: Rich debugging and profiling
/// - 🛍️ **Plugin Marketplace**: Extensible ecosystem
///
/// This is not just another package - it's a complete development platform
/// that makes Flutter development legendary.
library flutter_unify;

// Core exports - The main API surface
export 'src/core/unify.dart';
export 'src/core/config/unify_config.dart';

// Unified modules - Reactive APIs for everything
export 'src/core/auth/unified_auth.dart' hide AuthResult, AuthProvider;
export 'src/core/files/unified_files.dart';
export 'src/core/networking/unified_networking.dart'
    hide MockWebSocketConnection;

// Adapters - Pluggable backends
export 'src/adapters/auth_adapter.dart';
export 'src/adapters/networking_adapter.dart' hide MockWebSocketConnection;
export 'src/adapters/files_adapter.dart';

// Models and types
export 'src/models/auth_models.dart' hide UnifiedUser;
export 'src/models/system_models.dart' hide Size;
export 'src/models/storage_models.dart' hide UploadProgress, DownloadProgress;
export 'src/models/networking_models.dart';

// Legacy unified APIs - for backward compatibility
export 'src/unified/notifications.dart';
export 'src/unified/system.dart';
