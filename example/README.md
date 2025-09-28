# Flutter Unify - Best in Class Examples

This directory contains comprehensive examples demonstrating the unified APIs that make Flutter Unify "best in class" for cross-platform development.

## 🚀 Unified APIs Overview

### 📱 Unified Notifications
Cross-platform notification system with scheduling, actions, and rich content support.

```dart
import 'package:flutter_unify/flutter_unify.dart';

// Initialize notifications
await UnifiedNotifications.instance.initialize();

// Show simple notification
await UnifiedNotifications.instance.show(
  'Hello World',
  'This works on all platforms!',
);

// Schedule notification with actions
await UnifiedNotifications.instance.schedule(
  DateTime.now().add(Duration(minutes: 5)),
  'Reminder',
  'Time to take a break!',
  actions: [
    NotificationAction(id: 'snooze', title: 'Snooze 5 min'),
    NotificationAction(id: 'dismiss', title: 'Dismiss'),
  ],
);
```

### 💾 Unified Storage
Consistent storage API across all platforms with automatic encryption and JSON support.

```dart
// Initialize storage
await UnifiedStorage.instance.initialize();

// Simple key-value storage
await UnifiedStorage.instance.setString('user_name', 'John Doe');
final userName = await UnifiedStorage.instance.getString('user_name');

// JSON storage
await UnifiedStorage.instance.setJson('user_profile', {
  'name': 'John Doe',
  'email': 'john@example.com',
  'preferences': {'theme': 'dark', 'notifications': true},
});

// Secure storage
await UnifiedStorage.instance.setSecureString('api_token', 'secret_token');
```

### 🔐 Unified Authentication
Complete authentication system supporting OAuth, WebAuthn, biometrics, and more.

```dart
// Initialize auth
await UnifiedAuth.instance.initialize();

// Sign in methods
final result = await UnifiedAuth.instance.signInWithGoogle();
// await UnifiedAuth.instance.signInWithApple();
// await UnifiedAuth.instance.signInWithBiometrics();
// await UnifiedAuth.instance.signInWithWebAuthn(config);

if (result.success) {
  print('Welcome ${result.user?.displayName}!');
}

// Listen to auth state changes
UnifiedAuth.instance.authStateChanges.listen((user) {
  if (user != null) {
    print('User signed in: ${user.email}');
  } else {
    print('User signed out');
  }
});
```

### 📸 Unified Media & Device Access
Comprehensive media capture and device access with graceful platform-specific fallbacks.

```dart
// Initialize media system
await UnifiedMedia.instance.initialize();

// Take photo
final photoResult = await UnifiedMedia.instance.takePhoto(
  CameraConfig(facing: CameraFacing.back, quality: MediaQuality.high),
);

// Record video
final videoResult = await UnifiedMedia.instance.recordVideo();

// Pick files
final filesResult = await UnifiedMedia.instance.pickFiles(
  FilePickerOptions(
    allowedTypes: [MediaType.image, MediaType.video],
    allowMultiple: true,
  ),
);

// Screen capture (desktop/web)
final screenResult = await UnifiedMedia.instance.captureScreen(
  ScreenCaptureConfig(includeAudio: true, quality: MediaQuality.high),
);
```

### 🌐 Unified Networking
Advanced HTTP client with offline queueing, retry logic, WebSocket, and gRPC support.

```dart
// Initialize networking
await UnifiedNetworking.instance.initialize();

// HTTP requests with automatic retry and offline queueing
final response = await UnifiedNetworking.instance.get(
  'https://api.example.com/data',
  headers: {'Authorization': 'Bearer $token'},
);

// File upload with progress
final uploadResult = await UnifiedNetworking.instance.uploadFile(
  'https://api.example.com/upload',
  '/path/to/file.jpg',
  onProgress: (progress) {
    print('Upload progress: ${progress.percentage}%');
  },
);

// WebSocket connection
final websocket = UnifiedNetworking.instance.connectWebSocket(
  WebSocketConfig(url: 'wss://api.example.com/ws'),
);
websocket?.listen((message) {
  print('Received: ${message.data}');
});

// Monitor connectivity
UnifiedNetworking.instance.connectivityStream.listen((status) {
  print('Connection status: ${status.name}');
});
```

### ⚙️ Unified Background Services
Cross-platform background task scheduling with WorkManager, Service Workers, and native services.

```dart
// Initialize background services
await UnifiedBackgroundServices.instance.initialize();

// Register task handler
UnifiedBackgroundServices.instance.registerTaskHandler(
  'data_sync',
  (context) async {
    print('Running background sync...');
    
    // Perform background work
    await syncDataWithServer();
    
    return TaskExecutionResult.success();
  },
);

// Schedule periodic task
await UnifiedBackgroundServices.instance.scheduleTask(
  BackgroundTaskConfig(
    id: 'data_sync',
    name: 'Data Synchronization',
    type: BackgroundTaskType.periodic,
    interval: Duration(hours: 1),
    constraints: {TaskConstraint.requiresNetworkConnected},
    persistAcrossReboot: true,
  ),
);

// Start foreground service (mobile/desktop)
await UnifiedBackgroundServices.instance.startForegroundService(
  ForegroundServiceConfig(
    id: 'music_player',
    title: 'Music Player',
    description: 'Playing your favorite tunes',
    showProgress: true,
  ),
);
```

## 🎯 Complete App Example

Here's a complete example showing how all unified APIs work together:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

class UnifiedApp extends StatefulWidget {
  @override
  _UnifiedAppState createState() => _UnifiedAppState();
}

class _UnifiedAppState extends State<UnifiedApp> {
  bool _isInitialized = false;
  UnifiedUser? _currentUser;
  ConnectivityStatus _connectivity = ConnectivityStatus.none;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize all unified services
    await Future.wait([
      UnifiedNotifications.instance.initialize(),
      UnifiedStorage.instance.initialize(),
      UnifiedAuth.instance.initialize(),
      UnifiedMedia.instance.initialize(),
      UnifiedNetworking.instance.initialize(),
      UnifiedBackgroundServices.instance.initialize(),
    ]);

    // Set up listeners
    UnifiedAuth.instance.authStateChanges.listen((user) {
      setState(() => _currentUser = user);
    });

    UnifiedNetworking.instance.connectivityStream.listen((status) {
      setState(() => _connectivity = status);
    });

    // Schedule background tasks
    await _scheduleBackgroundTasks();

    setState(() => _isInitialized = true);
  }

  Future<void> _scheduleBackgroundTasks() async {
    // Register handlers
    UnifiedBackgroundServices.instance.registerTaskHandler(
      'notifications_check',
      (context) async {
        // Check for new notifications
        final hasNew = await checkForNewNotifications();
        
        if (hasNew) {
          await UnifiedNotifications.instance.show(
            'New Updates',
            'You have new content available!',
          );
        }
        
        return TaskExecutionResult.success();
      },
    );

    // Schedule periodic check
    await UnifiedBackgroundServices.instance.scheduleTask(
      BackgroundTaskConfig(
        id: 'notifications_check',
        name: 'Check Notifications',
        type: BackgroundTaskType.periodic,
        interval: Duration(minutes: 15),
        constraints: {TaskConstraint.requiresNetworkConnected},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Flutter Unify Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Unify - Best in Class'),
          actions: [
            IconButton(
              icon: Icon(_connectivity == ConnectivityStatus.none 
                ? Icons.wifi_off : Icons.wifi),
              onPressed: () => _showConnectivityInfo(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Auth section
            Card(
              child: ListTile(
                title: Text('Authentication'),
                subtitle: Text(_currentUser?.email ?? 'Not signed in'),
                trailing: ElevatedButton(
                  onPressed: _currentUser == null ? _signIn : _signOut,
                  child: Text(_currentUser == null ? 'Sign In' : 'Sign Out'),
                ),
              ),
            ),
            
            // Actions section
            Expanded(
              child: ListView(
                children: [
                  _buildActionCard(
                    'Send Notification',
                    'Test cross-platform notifications',
                    Icons.notifications,
                    _sendTestNotification,
                  ),
                  _buildActionCard(
                    'Take Photo',
                    'Capture using unified camera API',
                    Icons.camera,
                    _takePhoto,
                  ),
                  _buildActionCard(
                    'Upload File',
                    'Upload with progress tracking',
                    Icons.upload,
                    _uploadFile,
                  ),
                  _buildActionCard(
                    'Storage Test',
                    'Test unified storage API',
                    Icons.storage,
                    _testStorage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  Future<void> _signIn() async {
    final result = await UnifiedAuth.instance.signInWithGoogle();
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${result.user?.displayName}!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: ${result.error}')),
      );
    }
  }

  Future<void> _signOut() async {
    await UnifiedAuth.instance.signOut();
  }

  Future<void> _sendTestNotification() async {
    await UnifiedNotifications.instance.show(
      'Test Notification',
      'This notification works on all platforms! 🎉',
      payload: {'source': 'demo_app'},
    );
  }

  Future<void> _takePhoto() async {
    final result = await UnifiedMedia.instance.takePhoto();
    if (result.success && result.files?.isNotEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo captured: ${result.files!.first.name}')),
      );
    }
  }

  Future<void> _uploadFile() async {
    final fileResult = await UnifiedMedia.instance.pickFiles();
    if (fileResult.success && fileResult.files?.isNotEmpty == true) {
      final file = fileResult.files!.first;
      
      // Upload with progress
      final uploadResult = await UnifiedNetworking.instance.uploadFile(
        'https://httpbin.org/post',
        file.path!,
        onProgress: (progress) {
          print('Upload progress: ${progress.percentage}%');
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uploadResult.isSuccess 
            ? 'Upload successful!' 
            : 'Upload failed: ${uploadResult.error}'),
        ),
      );
    }
  }

  Future<void> _testStorage() async {
    // Store test data
    await UnifiedStorage.instance.setJson('test_data', {
      'timestamp': DateTime.now().toIso8601String(),
      'user': _currentUser?.email ?? 'anonymous',
      'platform': PlatformDetector.currentPlatform.name,
    });

    // Retrieve and show
    final data = await UnifiedStorage.instance.getJson('test_data');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Storage test completed: ${data?['timestamp']}')),
    );
  }

  void _showConnectivityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connectivity Status'),
        content: Text('Current status: ${_connectivity.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> checkForNewNotifications() async {
    // Simulate checking for new content
    await Future.delayed(Duration(seconds: 1));
    return DateTime.now().second % 10 == 0; // Random chance
  }
}
```

## 🎨 Best Practices

### 1. Initialize Early
Always initialize unified services in your app's main function or early in the widget tree:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core services
  await UnifiedAuth.instance.initialize();
  await UnifiedStorage.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. Handle Platform Differences
Use capability detection to provide the best experience on each platform:

```dart
if (UnifiedMedia.instance.isFeatureSupported('screen_capture')) {
  // Show screen capture option
} else {
  // Hide or provide alternative
}
```

### 3. Implement Proper Error Handling
Always handle errors gracefully:

```dart
try {
  final result = await UnifiedAuth.instance.signInWithGoogle();
  if (result.success) {
    // Handle success
  } else {
    // Handle failure
    showError(result.error);
  }
} catch (e) {
  // Handle exceptions
  showError('Unexpected error: $e');
}
```

### 4. Use Streams for Real-time Updates
Listen to streams for real-time updates:

```dart
StreamSubscription? _authSubscription;

void _setupListeners() {
  _authSubscription = UnifiedAuth.instance.authStateChanges.listen((user) {
    // Update UI based on auth state
  });
}

@override
void dispose() {
  _authSubscription?.cancel();
  super.dispose();
}
```

### 5. Optimize for Each Platform
Take advantage of platform-specific features:

```dart
// Web: Use WebAuthn for passwordless auth
if (kIsWeb) {
  await UnifiedAuth.instance.signInWithWebAuthn(webAuthnConfig);
}

// Mobile: Use biometric authentication
if (PlatformDetector.isMobile) {
  await UnifiedAuth.instance.signInWithBiometrics();
}

// Desktop: Use native system integration
if (PlatformDetector.isDesktop) {
  await UnifiedBackgroundServices.instance.startForegroundService(serviceConfig);
}
```

## 🔥 Why This Makes Flutter Unify "Best in Class"

1. **🎯 Single API Surface**: One API that works everywhere, no platform-specific code needed
2. **🚀 Native Performance**: Platform-optimized implementations under the hood
3. **🛡️ Automatic Fallbacks**: Graceful degradation when features aren't available
4. **📱 Complete Coverage**: Covers all major app functionality needs
5. **🔧 Developer Experience**: Simple, intuitive APIs with comprehensive error handling
6. **📚 Rich Documentation**: Extensive examples and best practices
7. **🎨 Flexible Architecture**: Use what you need, when you need it
8. **🔄 Future-Proof**: Easy to extend and adapt to new platforms

This unified approach eliminates the complexity of managing multiple platform-specific packages while providing the full power and performance of native implementations.
