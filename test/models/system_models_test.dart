import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('System Models Tests', () {
    test('ConnectivityState should have basic properties', () {
      final state = ConnectivityState(
        connectionType: ConnectionType.wifi,
        isConnected: true,
      );

      expect(state.connectionType, ConnectionType.wifi);
      expect(state.isConnected, isTrue);
      expect(state.isOffline, isFalse);
    });

    test('BatteryState should have basic properties', () {
      final battery = BatteryState(
        level: 0.8,
        isCharging: false,
      );

      expect(battery.level, 0.8);
      expect(battery.isCharging, isFalse);
    });

    test('MemoryInfo should have basic properties', () {
      final memory = MemoryInfo(
        totalPhysical: 8589934592, // 8 GB
        usedPhysical: 4294967296, // 4 GB
        availablePhysical: 4294967296, // 4 GB
      );

      expect(memory.totalPhysical, 8589934592);
      expect(memory.usedPhysical, 4294967296);
      expect(memory.availablePhysical, 4294967296);
    });

    test('CPUInfo should have basic properties', () {
      final cpu = CPUInfo(
        usage: 0.5,
      );

      expect(cpu.usage, 0.5);
    });

    test('StorageInfo should have basic properties', () {
      final storage = StorageInfo(
        totalSpace: 1099511627776, // 1 TB
        freeSpace: 549755813888, // 512 GB
        usedSpace: 549755813888, // 512 GB used
      );

      expect(storage.totalSpace, 1099511627776);
      expect(storage.freeSpace, 549755813888);
      expect(storage.usedSpace, 549755813888);
    });

    test('DeviceInfo should have basic properties', () {
      final device = DeviceInfo(
        deviceId: 'test-device-id',
        deviceName: 'Test Device',
        platform: 'Android',
      );

      expect(device.deviceId, 'test-device-id');
      expect(device.deviceName, 'Test Device');
      expect(device.platform, 'Android');
    });
  });

  group('ConnectionType enum tests', () {
    test('should have all connection types', () {
      expect(ConnectionType.wifi, isNotNull);
      expect(ConnectionType.cellular, isNotNull);
      expect(ConnectionType.ethernet, isNotNull);
      expect(ConnectionType.bluetooth, isNotNull);
      expect(ConnectionType.none, isNotNull);
    });
  });
}
