import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  List<String> _availableModules = [];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final initialized = Unify.availableModules.isNotEmpty;
    final modules = Unify.availableModules;

    setState(() {
      _isInitialized = initialized;
      _availableModules = modules;
      _statusMessage = initialized
          ? 'Flutter Unify Ready! 🎉'
          : 'Not initialized';
    });
  }

  Future<void> _testNetworking() async {
    try {
      // Test networking with performance monitoring
      final result = await Unify.performance.trackOperation(
        'api_test',
        () async {
          // Simulate API call
          await Future.delayed(const Duration(seconds: 2));
          return {'status': 'success', 'data': 'Hello from Flutter Unify!'};
        },
      );

      // Record event in dev dashboard
      Unify.dev.recordEvent(DashboardEvent(
        type: EventType.network,
        title: 'API Test Call',
        timestamp: DateTime.now(),
        description: 'Test API call completed successfully',
        data: result,
        success: true,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API call successful: ${result['data']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API call failed: $e')),
      );
    }
  }

  Future<void> _testSystemInfo() async {
    try {
      final info = await Unify.system.getSystemInfo();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('System Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform: ${info.platform}'),
                Text('Version: ${info.version}'),
                Text('Device Model: ${info.deviceModel}'),
                Text('Battery Level: ${info.batteryLevel}%'),
                Text('Memory: ${info.memoryUsage}MB'),
                Text('Storage: ${info.storageUsage}GB'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get system info: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isInitialized ? Icons.check_circle : Icons.error,
                        color: _isInitialized ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Flutter Unify is the ultimate cross-platform development framework for Flutter. '
                    'It provides unified APIs across all platforms with pluggable adapters, '
                    'AI-powered development tools, and comprehensive monitoring.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Available Modules
          if (_availableModules.isNotEmpty) ...[
            Text(
              'Available Modules',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableModules.map((module) => Chip(
                label: Text(module.toUpperCase()),
                backgroundColor: Colors.blue.withOpacity(0.1),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Feature Cards
          Text(
            'Features',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildFeatureCard(
                context,
                'Networking',
                Icons.cloud,
                'Unified HTTP, WebSocket, GraphQL',
                () => _testNetworking(),
              ),
              _buildFeatureCard(
                context,
                'Authentication',
                Icons.security,
                'Firebase, Supabase, OAuth',
                () => Navigator.of(context).pushNamed('/auth'),
              ),
              _buildFeatureCard(
                context,
                'AI Integration',
                Icons.smart_toy,
                'OpenAI, Claude, Vision',
                () => Navigator.of(context).pushNamed('/ai'),
              ),
              _buildFeatureCard(
                context,
                'File System',
                Icons.folder,
                'Cross-platform file operations',
                () => _showComingSoon('File System'),
              ),
              _buildFeatureCard(
                context,
                'System Info',
                Icons.info,
                'Device and system information',
                () => _testSystemInfo(),
              ),
              _buildFeatureCard(
                context,
                'Dev Tools',
                Icons.developer_mode,
                'Dashboard, Performance, Logs',
                () => Navigator.of(context).pushNamed('/dev'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Performance Stats
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final stats = Unify.performance.getStats();
                      return Column(
                        children: [
                          _buildStatRow('Total Operations', stats.totalOperations.toString()),
                          _buildStatRow('Success Rate', '${(stats.successRate * 100).round()}%'),
                          _buildStatRow('Avg Duration', '${stats.averageDuration.inMilliseconds}ms'),
                          if (stats.totalMemoryUsage != null)
                            _buildStatRow('Memory Usage', '${(stats.totalMemoryUsage! / 1024 / 1024).round()}MB'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}

