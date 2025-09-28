import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core unified services
  await _initializeUnifiedServices();

  runApp(UnifiedDemoApp());
}

Future<void> _initializeUnifiedServices() async {
  try {
    await Future.wait([
      UnifiedNotifications.instance.initialize(),
      UnifiedStorage.instance.initialize(),
      UnifiedAuth.instance.initialize(),
      UnifiedMedia.instance.initialize(),
      UnifiedNetworking.instance.initialize(),
      UnifiedBackgroundServices.instance.initialize(),
    ]);
    print('✅ All unified services initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize services: $e');
  }
}

class UnifiedDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Unify - Best in Class Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: UnifiedHomePage(),
    );
  }
}

class UnifiedHomePage extends StatefulWidget {
  @override
  _UnifiedHomePageState createState() => _UnifiedHomePageState();
}

class _UnifiedHomePageState extends State<UnifiedHomePage> {
  UnifiedUser? _currentUser;
  ConnectivityStatus _connectivity = ConnectivityStatus.none;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _scheduleBackgroundTasks();
  }

  void _setupListeners() {
    // Auth state changes
    UnifiedAuth.instance.authStateChanges.listen((user) {
      setState(() => _currentUser = user);
      _addLog('Auth: ${user?.email ?? 'Signed out'}');
    });

    // Connectivity changes
    UnifiedNetworking.instance.connectivityStream.listen((status) {
      setState(() => _connectivity = status);
      _addLog('Network: ${status.name}');
    });

    // Notification taps
    UnifiedNotifications.instance.on('notification-tapped', (data) {
      _addLog('Notification tapped: ${data['title']}');
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0,
          '${DateTime.now().toLocal().toString().substring(11, 19)}: $message');
      if (_logs.length > 10) _logs.removeLast();
    });
  }

  Future<void> _scheduleBackgroundTasks() async {
    try {
      // Register notification handler
      UnifiedBackgroundServices.instance.registerTaskHandler(
        'demo_notifications',
        (context) async {
          await UnifiedNotifications.instance.show(
            'Background Task',
            body: 'This notification was sent from a background task! 🚀',
            data: {
              'source': 'background',
              'timestamp': DateTime.now().toIso8601String()
            },
          );
          return TaskExecutionResult.success();
        },
      );

      // Schedule periodic notifications (every 2 minutes for demo)
      await UnifiedBackgroundServices.instance.scheduleTask(
        BackgroundTaskConfig(
          id: 'demo_notifications',
          name: 'Demo Notifications',
          type: BackgroundTaskType.periodic,
          interval: Duration(minutes: 2),
          constraints: {},
          persistAcrossReboot: false,
        ),
      );

      _addLog('Background tasks scheduled');
    } catch (e) {
      _addLog('Background task error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Unify - Best in Class'),
        backgroundColor: Colors.blue[600],
        elevation: 2,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                    _connectivity == ConnectivityStatus.none
                        ? Icons.wifi_off
                        : Icons.wifi,
                    color: Colors.white),
                SizedBox(width: 4),
                Text(_connectivity.name,
                    style: TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentUser != null
                        ? '👤 ${_currentUser!.displayName ?? _currentUser!.email}'
                        : '👤 Not signed in',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _connectivity != ConnectivityStatus.none
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _connectivity != ConnectivityStatus.none
                        ? 'Online'
                        : 'Offline',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 Best in Class Features',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap any card to test the unified APIs across all platforms',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),

                  // Feature cards
                  _buildFeatureGrid(),

                  SizedBox(height: 20),

                  // Logs section
                  _buildLogsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      FeatureCard(
        title: '🔐 Authentication',
        subtitle: 'OAuth, WebAuthn, Biometrics',
        color: Colors.purple,
        onTap: _testAuth,
      ),
      FeatureCard(
        title: '📱 Notifications',
        subtitle: 'Cross-platform notifications',
        color: Colors.orange,
        onTap: _testNotifications,
      ),
      FeatureCard(
        title: '💾 Storage',
        subtitle: 'Unified storage API',
        color: Colors.green,
        onTap: _testStorage,
      ),
      FeatureCard(
        title: '📸 Media',
        subtitle: 'Camera, files, device access',
        color: Colors.red,
        onTap: _testMedia,
      ),
      FeatureCard(
        title: '🌐 Networking',
        subtitle: 'HTTP, WebSocket, offline queue',
        color: Colors.blue,
        onTap: _testNetworking,
      ),
      FeatureCard(
        title: '⚙️ Background',
        subtitle: 'Cross-platform background tasks',
        color: Colors.teal,
        onTap: _testBackgroundServices,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: features.map((feature) => _buildFeatureCard(feature)).toList(),
    );
  }

  Widget _buildFeatureCard(FeatureCard feature) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                feature.color.withOpacity(0.1),
                feature.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: feature.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                feature.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: feature.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('📋 Activity Log',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                TextButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: Text('Clear'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              height: 120,
              child: _logs.isEmpty
                  ? Center(
                      child: Text('No activity yet',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: TextStyle(
                                fontSize: 12, fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Test methods
  Future<void> _testAuth() async {
    try {
      if (_currentUser == null) {
        _addLog('Testing authentication...');
        final result = await UnifiedAuth.instance.signInAnonymously();
        if (result.success) {
          _addLog('✅ Anonymous sign in successful');
        } else {
          _addLog('❌ Auth failed: ${result.error}');
        }
      } else {
        _addLog('Signing out...');
        await UnifiedAuth.instance.signOut();
        _addLog('✅ Signed out successfully');
      }
    } catch (e) {
      _addLog('❌ Auth error: $e');
    }
  }

  Future<void> _testNotifications() async {
    try {
      _addLog('Sending notification...');
      await UnifiedNotifications.instance.show(
        'Test Notification',
        body: 'This notification works on all platforms! 🎉',
        data: {'test': 'true', 'timestamp': DateTime.now().toIso8601String()},
        actions: [
          NotificationAction(id: 'reply', title: 'Reply'),
          NotificationAction(id: 'dismiss', title: 'Dismiss'),
        ],
      );
      _addLog('✅ Notification sent');
    } catch (e) {
      _addLog('❌ Notification error: $e');
    }
  }

  Future<void> _testStorage() async {
    try {
      _addLog('Testing storage...');

      final testData = {
        'timestamp': DateTime.now().toIso8601String(),
        'user': _currentUser?.email ?? 'anonymous',
        'platform': PlatformDetector.isWeb
            ? 'web'
            : PlatformDetector.isMobile
                ? 'mobile'
                : 'desktop',
        'test_number': DateTime.now().millisecondsSinceEpoch % 1000,
      };

      await UnifiedStorage.instance.setJson('test_data', testData);
      final retrieved = await UnifiedStorage.instance.getJson('test_data');

      _addLog('✅ Storage test completed: ${retrieved?['test_number']}');
    } catch (e) {
      _addLog('❌ Storage error: $e');
    }
  }

  Future<void> _testMedia() async {
    try {
      _addLog('Testing media access...');

      if (UnifiedMedia.instance.isFeatureSupported('file_picker')) {
        final result = await UnifiedMedia.instance.pickFiles(
          FilePickerOptions(
            allowedTypes: [MediaType.image],
            allowMultiple: false,
          ),
        );

        if (result.success && result.files?.isNotEmpty == true) {
          _addLog('✅ File picked: ${result.files!.first.name}');
        } else {
          _addLog('📁 No file selected');
        }
      } else {
        _addLog('📱 File picker not available on this platform');
      }
    } catch (e) {
      _addLog('❌ Media error: $e');
    }
  }

  Future<void> _testNetworking() async {
    try {
      _addLog('Testing network request...');

      final response = await UnifiedNetworking.instance.get(
        'https://jsonplaceholder.typicode.com/posts/1',
      );

      if (response.isSuccess) {
        final data = response.getData<Map<String, dynamic>>();
        _addLog(
            '✅ Network request successful: ${data?['title']?.toString().substring(0, 30)}...');
      } else {
        _addLog('❌ Network error: ${response.error}');
      }
    } catch (e) {
      _addLog('❌ Network exception: $e');
    }
  }

  Future<void> _testBackgroundServices() async {
    try {
      _addLog('Testing background services...');

      final activeTasks = UnifiedBackgroundServices.instance.getActiveTasks();
      _addLog('📋 Active background tasks: ${activeTasks.length}');

      // Execute demo task immediately for testing
      final result = await UnifiedBackgroundServices.instance
          .executeTaskImmediately('demo_notifications');

      if (result.result == TaskResult.success) {
        _addLog('✅ Background task executed successfully');
      } else {
        _addLog('❌ Background task failed: ${result.error}');
      }
    } catch (e) {
      _addLog('❌ Background services error: $e');
    }
  }
}

class FeatureCard {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  FeatureCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
