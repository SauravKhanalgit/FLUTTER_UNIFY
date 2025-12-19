import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  final List<DashboardEvent> _events = [];
  bool _isDashboardEnabled = false;
  bool _isPerformanceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _loadEvents();
  }

  void _checkStatus() {
    setState(() {
      _isDashboardEnabled = Unify.dev.isEnabled;
      _isPerformanceEnabled = Unify.performance.isEnabled;
    });
  }

  void _loadEvents() {
    setState(() {
      _events.clear();
      _events.addAll(Unify.dev.getEvents());
    });
  }

  Future<void> _openDashboard() async {
    try {
      await Unify.dev.show();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard opened in browser')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open dashboard: $e')),
      );
    }
  }

  void _toggleDashboard(bool enabled) {
    if (enabled) {
      Unify.dev.enable();
    } else {
      Unify.dev.disable();
    }
    _checkStatus();
  }

  void _togglePerformance(bool enabled) {
    if (enabled) {
      Unify.performance.enable();
    } else {
      Unify.performance.disable();
    }
    _checkStatus();
  }

  void _clearEvents() {
    Unify.dev.clearEvents();
    _loadEvents();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Events cleared')),
    );
  }

  void _clearPerformanceMetrics() {
    Unify.performance.clearMetrics();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance metrics cleared')),
    );
  }

  void _recordTestEvent() {
    Unify.dev.recordEvent(DashboardEvent(
      type: EventType.other,
      title: 'Test Event',
      timestamp: DateTime.now(),
      description: 'Manually recorded test event',
      data: {'test': true, 'timestamp': DateTime.now().toIso8601String()},
      success: true,
    ));
    _loadEvents();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test event recorded')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dev Tools Status
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Tools Status',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dev Dashboard'),
                    subtitle: const Text('Real-time event monitoring'),
                    value: _isDashboardEnabled,
                    onChanged: _toggleDashboard,
                  ),
                  SwitchListTile(
                    title: const Text('Performance Monitoring'),
                    subtitle: const Text('Track operation performance'),
                    value: _isPerformanceEnabled,
                    onChanged: _togglePerformance,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isDashboardEnabled ? _openDashboard : null,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open Dashboard'),
                  ),
                ],
              ),
            ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Performance Statistics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: _clearPerformanceMetrics,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear metrics',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final stats = Unify.performance.getStats();
                      return Column(
                        children: [
                          _buildStatRow('Total Operations', stats.totalOperations.toString()),
                          _buildStatRow('Success Rate', '${(stats.successRate * 100).round()}%'),
                          _buildStatRow('Average Duration',
                              '${stats.averageDuration.inMilliseconds}ms'),
                          _buildStatRow('Min Duration',
                              '${stats.minDuration.inMilliseconds}ms'),
                          _buildStatRow('Max Duration',
                              '${stats.maxDuration.inMilliseconds}ms'),
                          if (stats.totalMemoryUsage != null)
                            _buildStatRow('Memory Usage',
                                '${(stats.totalMemoryUsage! / 1024 / 1024).round()}MB'),
                          if (stats.totalNetworkBytes != null)
                            _buildStatRow('Network Usage',
                                '${(stats.totalNetworkBytes! / 1024).round()}KB'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Events
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Events (${_events.length})',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _recordTestEvent,
                            icon: const Icon(Icons.add),
                            tooltip: 'Record test event',
                          ),
                          IconButton(
                            onPressed: _clearEvents,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear events',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_events.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No events recorded yet.\nTry using the app to generate events.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _events.length.clamp(0, 20), // Show last 20
                      itemBuilder: (context, index) {
                        final event = _events[_events.length - 1 - index]; // Reverse order
                        return ListTile(
                          leading: _getEventIcon(event.type),
                          title: Text(event.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.description != null)
                                Text(event.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text(
                                '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            event.success ? Icons.check_circle : Icons.error,
                            color: event.success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // System Information
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: Unify.system.getSystemInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      final info = snapshot.data!;
                      return Column(
                        children: [
                          _buildStatRow('Platform', info.platform),
                          _buildStatRow('Device Model', info.deviceModel),
                          _buildStatRow('Battery Level', '${info.batteryLevel}%'),
                          _buildStatRow('Memory Usage', '${info.memoryUsage}MB'),
                          _buildStatRow('Storage Usage', '${info.storageUsage}GB'),
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

  Widget _getEventIcon(EventType type) {
    switch (type) {
      case EventType.network:
        return const Icon(Icons.cloud, color: Colors.blue);
      case EventType.auth:
        return const Icon(Icons.security, color: Colors.green);
      case EventType.storage:
        return const Icon(Icons.storage, color: Colors.orange);
      case EventType.ai:
        return const Icon(Icons.smart_toy, color: Colors.purple);
      case EventType.error:
        return const Icon(Icons.error, color: Colors.red);
      case EventType.performance:
        return const Icon(Icons.speed, color: Colors.amber);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
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
}

