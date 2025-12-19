import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/models/system_models.dart';

void main() {
  group('BatteryState', () {
    test('should create battery state', () {
      final state = BatteryState(
        level: 0.75,
        isCharging: true,
      );

      expect(state.percentage, equals(75));
      expect(state.level, equals(0.75));
      expect(state.isCharging, isTrue);
    });

    test('should handle edge cases', () {
      final empty = BatteryState(level: 0.0, isCharging: false);
      final full = BatteryState(level: 1.0, isCharging: false);

      expect(empty.percentage, equals(0));
      expect(full.percentage, equals(100));
    });
  });
}
