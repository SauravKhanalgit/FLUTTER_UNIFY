import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Unify Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _systemInfo = 'Loading...';
  bool _isUnifyInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeUnify();
  }

  Future<void> _initializeUnify() async {
    try {
      // Initialize Flutter Unify
      await Unify.initialize();

      // Get system information
      final info = Unify.getRuntimeInfo();

      setState(() {
        _isUnifyInitialized = true;
        _systemInfo = '''
Platform: ${info['platform']}
Is Web: ${info['isWeb']}
Is Desktop: ${info['isDesktop']}  
Is Mobile: ${info['isMobile']}
Initialized: ${info['isInitialized']}
        ''';
      });
    } catch (e) {
      setState(() {
        _systemInfo = 'Error initializing Unify: $e';
      });
    }
  }

  Future<void> _testClipboard() async {
    if (!_isUnifyInitialized) return;

    try {
      // Test clipboard operations
      await Unify.system.clipboardWriteText('Hello from Flutter Unify!');

      final clipboardText = await Unify.system.clipboardReadText();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard: $clipboardText'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    if (!_isUnifyInitialized) return;

    try {
      // Test notification
      await Unify.system.showNotification(
        title: 'Flutter Unify Test',
        body: 'This is a test notification from Flutter Unify!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onFilesDropped(List<String> files) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Files dropped: ${files.join(', ')}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedScaffold(
      appBar: AppBar(
        title: const Text('Flutter Unify Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      enableDragAndDrop: true,
      onFilesDropped: _onFilesDropped,
      showDesktopWindowControls: true,
      windowTitle: 'Flutter Unify Demo',
      enableWebOptimizations: true,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return _buildCommonLayout(isMobile: true);
  }

  Widget _buildTabletLayout() {
    return _buildCommonLayout(isMobile: false);
  }

  Widget _buildDesktopLayout() {
    return _buildCommonLayout(isMobile: false);
  }

  Widget _buildCommonLayout({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SEOWidget(
            title: 'Flutter Unify Demo',
            description:
                'A demonstration of Flutter Unify - unified API for Mobile, Web, and Desktop',
            keywords: 'flutter, unify, cross-platform, mobile, web, desktop',
            child: const SizedBox.shrink(),
          ),
          const SEOHeading.h1('Flutter Unify Demo'),
          const SizedBox(height: 16),
          const SEOParagraph(
            text:
                'Flutter Unify provides one unified layer for Flutter apps across Mobile, Web, and Desktop platforms.',
          ),
          const SizedBox(height: 24),

          // System Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _systemInfo,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: _isUnifyInitialized ? _testClipboard : null,
                icon: const Icon(Icons.content_copy),
                label: const Text('Test Clipboard'),
              ),
              ElevatedButton.icon(
                onPressed: _isUnifyInitialized ? _testNotification : null,
                icon: const Icon(Icons.notifications),
                label: const Text('Test Notification'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Platform-Specific Features
          PlatformBuilder(
            builder: (context, platform) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform-Specific Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (platform.isDesktop) ...[
                        const Text('✓ System Tray Support'),
                        const Text('✓ Window Management'),
                        const Text('✓ Global Shortcuts'),
                        const Text('✓ Drag & Drop Files'),
                      ],
                      if (platform.isWeb) ...[
                        const Text('✓ SEO Optimization'),
                        const Text('✓ Progressive Loading'),
                        const Text('✓ Web Polyfills'),
                        const Text('✓ Smart Bundling'),
                      ],
                      if (platform.isMobile) ...[
                        const Text('✓ Native Bridge'),
                        const Text('✓ Device Information'),
                        const Text('✓ Mobile Services'),
                        const Text('✓ Biometric Authentication'),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Screen Size: ${platform.screenSize.width.toInt()} x ${platform.screenSize.height.toInt()}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Drop Zone
          if (PlatformDetector.isDesktop)
            DropTarget(
              onDropFiles: _onFilesDropped,
              highlightOnDragOver: true,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Drop files here (Desktop only)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Unify.dispose();
    super.dispose();
  }
}
