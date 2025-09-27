import 'package:flutter_unify/flutter_unify.dart';

void main() async {
  print('🧪 Testing Flutter Unify Package...\n');

  // Test 1: Platform Detection
  print('✅ Platform Detection:');
  print('  - Platform: ${PlatformDetector.platformName}');
  print('  - Is Web: ${PlatformDetector.isWeb}');
  print('  - Is Desktop: ${PlatformDetector.isDesktop}');
  print('  - Is Mobile: ${PlatformDetector.isMobile}');
  print('  - Is Android: ${PlatformDetector.isAndroid}');
  print('  - Is iOS: ${PlatformDetector.isIOS}');
  print('  - Is Linux: ${PlatformDetector.isLinux}');
  print('  - Is macOS: ${PlatformDetector.isMacOS}');
  print('  - Is Windows: ${PlatformDetector.isWindows}');

  // Test 2: Capability Detection
  print('\n✅ Capability Detection:');
  final capabilities = CapabilityDetector.instance;
  await capabilities.initialize();
  print('  - Supports Clipboard: ${capabilities.supportsClipboard}');
  print('  - Supports Notifications: ${capabilities.supportsNotifications}');
  print('  - Supports Drag & Drop: ${capabilities.supportsDragDrop}');
  print('  - Supports System Tray: ${capabilities.supportsSystemTray}');
  print(
      '  - Supports Window Management: ${capabilities.supportsWindowManagement}');

  // Test 3: Unify Initialization
  print('\n✅ Unify Core:');
  print('  - Before Init: ${Unify.isInitialized}');

  try {
    await Unify.initialize();
    print('  - After Init: ${Unify.isInitialized}');
    print('  - Initialization: SUCCESS');
  } catch (e) {
    print('  - Initialization: FAILED - $e');
  }

  // Test 4: Runtime Info
  print('\n✅ Runtime Information:');
  final runtimeInfo = Unify.getRuntimeInfo();
  runtimeInfo.forEach((key, value) => print('  - $key: $value'));

  // Test 5: Feature Availability
  print('\n✅ Feature Availability:');
  final features = Unify.getFeatureAvailability();
  features.forEach((key, value) =>
      print('  - $key: ${value ? "AVAILABLE" : "UNAVAILABLE"}'));

  // Test 6: Platform Managers (only test available ones)
  print('\n✅ Platform Managers:');

  try {
    Unify.system;
    print('  - System Manager: AVAILABLE');
  } catch (e) {
    print('  - System Manager: $e');
  }

  if (PlatformDetector.isWeb) {
    try {
      final web = Unify.web;
      print('  - Web Manager: AVAILABLE');
      print('    - SEO initialized: ${web.isInitialized}');
    } catch (e) {
      print('  - Web Manager: $e');
    }
  }

  if (PlatformDetector.isDesktop) {
    try {
      final desktop = Unify.desktop;
      print('  - Desktop Manager: AVAILABLE');
      print('    - Desktop initialized: ${desktop.isInitialized}');
    } catch (e) {
      print('  - Desktop Manager: $e');
    }
  }

  if (PlatformDetector.isMobile) {
    try {
      final mobile = Unify.mobile;
      print('  - Mobile Manager: AVAILABLE');
      print('    - Mobile initialized: ${mobile.isInitialized}');
    } catch (e) {
      print('  - Mobile Manager: $e');
    }
  }

  // Test 7: Cleanup
  print('\n✅ Cleanup:');
  try {
    await Unify.dispose();
    print('  - Dispose: SUCCESS');
    print('  - After Dispose: ${Unify.isInitialized}');
  } catch (e) {
    print('  - Dispose: FAILED - $e');
  }

  print('\n🎉 Flutter Unify Package Test Complete!');
}
