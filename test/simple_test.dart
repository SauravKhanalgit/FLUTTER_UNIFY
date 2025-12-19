import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Tests', () {
    test('should pass basic assertion', () {
      expect(1 + 1, equals(2));
    });

    test('should handle string operations', () {
      expect('hello'.toUpperCase(), equals('HELLO'));
    });
  });
}
