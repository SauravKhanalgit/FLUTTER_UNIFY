import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the unified framework
  await _initializeUnifiedServices();
  
  runApp(UnifiedDemoApp());
}

Future<void> _initializeUnifiedServices() async {
  try {
    final initialized = await Unify.initialize();
    if (initialized) {
      print('✅ Unify framework initialized successfully');
    } else {
      print('❌ Failed to initialize Unify framework');
    }
  } catch (e) {
    print('❌ Failed to initialize Unify: $e');
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
  String _currentUser = 'Not signed in';
  String _connectivity = 'Unknown';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Auth state changes - using the correct API
    try {
      Unify.auth.onAuthStateChanged.listen((user) {
        setState(() => _currentUser = user?.email ?? 'Not signed in');
        _addLog('Auth: ${user?.email ?? 'Signed out'}');
      });
    } catch (e) {
      _addLog('Auth listener error: $e');
    }

    // Connectivity changes - using the correct API
    try {
      Unify.networking.onConnectivityChanged.listen((status) {
        setState(() => _connectivity = status.isConnected ? 'Online' : 'Offline');
        _addLog('Network: ${status.isConnected ? 'Connected' : 'Disconnected'}');
      });
    } catch (e) {
      _addLog('Network listener error: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toLocal().toString().substring(11, 19)}: $message');
      if (_logs.length > 10) _logs.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Unify - Best in Class Demo'),
        backgroundColor: Colors.blue[600],
        elevation: 2,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  _connectivity == 'Offline' ? Icons.wifi_off : Icons.wifi,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  _connectivity,
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
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
                    '👤 $_currentUser',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _connectivity == 'Online' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _connectivity,
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
        title: '📋 System',
        subtitle: 'System clipboard & info',
        color: Colors.red,
        onTap: _testSystem,
      ),
      FeatureCard(
        title: '🌐 Networking',
        subtitle: 'HTTP, WebSocket, offline queue',
        color: Colors.blue,
        onTap: _testNetworking,
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
                Text(
                  '📋 Activity Log',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                      child: Text(
                        'No activity yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
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
      if (_currentUser == 'Not signed in') {
        _addLog('Testing authentication...');
        final result = await Unify.auth.signInAnonymously();
        if (result.success) {
          _addLog('✅ Anonymous sign in successful');
        } else {
          _addLog('❌ Auth failed: ${result.error}');
        }
      } else {
        _addLog('Signing out...');
        await Unify.auth.signOut();
        _addLog('✅ Signed out successfully');
      }
    } catch (e) {
      _addLog('❌ Auth error: $e');
    }
  }

  Future<void> _testNotifications() async {
    try {
      _addLog('Sending notification...');
      await Unify.notifications.show(
        'Test Notification',
        body: 'This notification works on all platforms! 🎉',
        data: {
          'test': 'true',
          'timestamp': DateTime.now().toIso8601String(),
        },
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
      _addLog('Testing files/storage...');
      final testData = 'Test data at ${DateTime.now().toIso8601String()}';
      
      // Use the files module for basic storage operations
      final success = await Unify.files.setString('test_key', testData);
      if (success) {
        final retrievedData = await Unify.files.getString('test_key');
        if (retrievedData != null) {
          _addLog('✅ File storage test completed successfully');
        } else {
          _addLog('❌ File read returned null');
        }
      } else {
        _addLog('❌ File write failed');
      }
    } catch (e) {
      _addLog('❌ Storage error: $e');
    }
  }

  Future<void> _testSystem() async {
    try {
      _addLog('Testing system clipboard...');
      // Test clipboard functionality
      final testText = 'Unify clipboard test ${DateTime.now().millisecondsSinceEpoch}';
      final success = await Unify.system.clipboardWriteText(testText);
      
      if (success) {
        final clipboardText = await Unify.system.clipboardReadText();
        if (clipboardText == testText) {
          _addLog('✅ Clipboard test successful');
        } else {
          _addLog('❌ Clipboard read mismatch');
        }
      } else {
        _addLog('❌ Clipboard write failed');
      }
    } catch (e) {
      _addLog('❌ System test error: $e');
    }
  }

  Future<void> _testNetworking() async {
    try {
      _addLog('Testing network request...');
      final response = await Unify.networking.get(
        'https://jsonplaceholder.typicode.com/posts/1',
      );
      if (response.isSuccess) {
        final data = response.asJson;
        _addLog('✅ Network request successful: ${data?['title']?.toString().substring(0, 30)}...');
      } else {
        _addLog('❌ Network error: ${response.error}');
      }
    } catch (e) {
      _addLog('❌ Network exception: $e');
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