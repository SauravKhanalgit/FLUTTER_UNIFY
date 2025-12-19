import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/dev_tools_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Flutter Unify with auto-initialization
  final result = await Unify.autoInitialize(
    aiApiKey: 'your-openai-api-key-here', // Replace with actual key
    aiProvider: AIProvider.openai,
  );

  if (result.success) {
    debugPrint('Flutter Unify initialized: ${result.initializedModules}');
  } else {
    debugPrint('Initialization errors: ${result.errors}');
  }

  // Enable dev tools in debug mode
  if (kDebugMode) {
    Unify.dev.enable();
    Unify.performance.enable();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    AuthScreen(),
    AIScreen(),
    DevToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Unify Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Unify Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                // Open dev dashboard
                await Unify.dev.show();
              },
              tooltip: 'Open Dev Dashboard',
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () {
                // Show performance stats
                final stats = Unify.performance.getStats();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Performance Stats'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Operations: ${stats.totalOperations}'),
                        Text('Average Duration: ${stats.averageDuration.inSeconds}s'),
                        Text('Success Rate: ${(stats.successRate * 100).round()}%'),
                        if (stats.totalMemoryUsage != null)
                          Text('Memory Usage: ${(stats.totalMemoryUsage! / 1024 / 1024).round()}MB'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Performance Stats',
            ),
          ],
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Auth',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy),
              label: 'AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.developer_mode),
              label: 'Dev Tools',
            ),
          ],
        ),
      ),
    );
  }
}
