import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/common/platform_detector.dart';

void main() {
  group('Unify Core', () {
    test('should detect platform', () {
      // Platform detection should work
      expect(PlatformDetector.isWeb, isA<bool>());
      expect(PlatformDetector.isMobile, isA<bool>());
      expect(PlatformDetector.isDesktop, isA<bool>());
    });
  });
}

