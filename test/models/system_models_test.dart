import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('System Models Tests', () {
    group('ConnectivityState Tests', () {
      test('should create connectivity state', () {
        const state = ConnectivityState(
          isConnected: true,
          connectionType: ConnectionType.wifi,
          connectionQuality: ConnectionQuality.good,
          ssid: 'MyWiFi',
          bssid: '00:11:22:33:44:55',
          ipAddress: '192.168.1.100',
          isMetered: false,
        );

        expect(state.isConnected, isTrue);
        expect(state.connectionType, ConnectionType.wifi);
        expect(state.connectionQuality, ConnectionQuality.good);
        expect(state.ssid, 'MyWiFi');
        expect(state.bssid, '00:11:22:33:44:55');
        expect(state.ipAddress, '192.168.1.100');
        expect(state.isMetered, isFalse);
      });

      test('should create disconnected state', () {
        const state = ConnectivityState(
          isConnected: false,
          connectionType: ConnectionType.none,
        );

        expect(state.isConnected, isFalse);
        expect(state.connectionType, ConnectionType.none);
        expect(state.connectionQuality, isNull);
        expect(state.ssid, isNull);
      });

      test('should support copyWith functionality', () {
        const original = ConnectivityState(
          isConnected: true,
          connectionType: ConnectionType.wifi,
          connectionQuality: ConnectionQuality.good,
        );

        final updated = original.copyWith(
          connectionQuality: ConnectionQuality.excellent,
          isMetered: true,
        );

        expect(updated.isConnected, isTrue);
        expect(updated.connectionType, ConnectionType.wifi);
        expect(updated.connectionQuality, ConnectionQuality.excellent);
        expect(updated.isMetered, isTrue);
      });
    });

    group('ConnectionType Tests', () {
      test('should have all connection types', () {
        expect(ConnectionType.none, isNotNull);
        expect(ConnectionType.wifi, isNotNull);
        expect(ConnectionType.cellular, isNotNull);
        expect(ConnectionType.ethernet, isNotNull);
        expect(ConnectionType.bluetooth, isNotNull);
        expect(ConnectionType.vpn, isNotNull);
        expect(ConnectionType.other, isNotNull);
      });

      test('should convert to string meaningfully', () {
        expect(ConnectionType.wifi.toString(), contains('wifi'));
        expect(ConnectionType.cellular.toString(), contains('cellular'));
        expect(ConnectionType.none.toString(), contains('none'));
      });
    });

    group('ConnectionQuality Tests', () {
      test('should have all quality levels', () {
        expect(ConnectionQuality.poor, isNotNull);
        expect(ConnectionQuality.fair, isNotNull);
        expect(ConnectionQuality.good, isNotNull);
        expect(ConnectionQuality.excellent, isNotNull);
      });
    });

    group('BatteryState Tests', () {
      test('should create battery state', () {
        const state = BatteryState(
          level: 85,
          isCharging: true,
          chargingStatus: ChargingStatus.charging,
          batteryHealth: BatteryHealth.good,
          powerSaveMode: false,
          temperature: 25.5,
          voltage: 4.2,
          technology: 'Li-ion',
        );

        expect(state.level, 85);
        expect(state.isCharging, isTrue);
        expect(state.chargingStatus, ChargingStatus.charging);
        expect(state.batteryHealth, BatteryHealth.good);
        expect(state.powerSaveMode, isFalse);
        expect(state.temperature, 25.5);
        expect(state.voltage, 4.2);
        expect(state.technology, 'Li-ion');
      });

      test('should handle low battery state', () {
        const state = BatteryState(
          level: 15,
          isCharging: false,
          chargingStatus: ChargingStatus.discharging,
          powerSaveMode: true,
        );

        expect(state.level, 15);
        expect(state.isCharging, isFalse);
        expect(state.chargingStatus, ChargingStatus.discharging);
        expect(state.powerSaveMode, isTrue);
      });

      test('should support copyWith functionality', () {
        const original = BatteryState(
          level: 50,
          isCharging: false,
          chargingStatus: ChargingStatus.discharging,
        );

        final updated = original.copyWith(
          level: 75,
          isCharging: true,
          chargingStatus: ChargingStatus.charging,
        );

        expect(updated.level, 75);
        expect(updated.isCharging, isTrue);
        expect(updated.chargingStatus, ChargingStatus.charging);
      });
    });

    group('ChargingStatus Tests', () {
      test('should have all charging statuses', () {
        expect(ChargingStatus.unknown, isNotNull);
        expect(ChargingStatus.charging, isNotNull);
        expect(ChargingStatus.discharging, isNotNull);
        expect(ChargingStatus.notCharging, isNotNull);
        expect(ChargingStatus.full, isNotNull);
      });
    });

    group('BatteryHealth Tests', () {
      test('should have all health levels', () {
        expect(BatteryHealth.unknown, isNotNull);
        expect(BatteryHealth.good, isNotNull);
        expect(BatteryHealth.overheat, isNotNull);
        expect(BatteryHealth.dead, isNotNull);
        expect(BatteryHealth.overvoltage, isNotNull);
        expect(BatteryHealth.cold, isNotNull);
      });
    });

    group('MemoryInfo Tests', () {
      test('should create memory info', () {
        const info = MemoryInfo(
          totalPhysicalMemory: 8589934592, // 8GB
          availablePhysicalMemory: 4294967296, // 4GB
          totalVirtualMemory: 17179869184, // 16GB
          availableVirtualMemory: 8589934592, // 8GB
          appMemoryUsage: 536870912, // 512MB
          appMemoryLimit: 2147483648, // 2GB
        );

        expect(info.totalPhysicalMemory, 8589934592);
        expect(info.availablePhysicalMemory, 4294967296);
        expect(info.totalVirtualMemory, 17179869184);
        expect(info.availableVirtualMemory, 8589934592);
        expect(info.appMemoryUsage, 536870912);
        expect(info.appMemoryLimit, 2147483648);
      });

      test('should calculate memory usage percentage', () {
        const info = MemoryInfo(
          totalPhysicalMemory: 1000,
          availablePhysicalMemory: 600,
          appMemoryUsage: 200,
          appMemoryLimit: 400,
        );

        expect(info.physicalMemoryUsagePercentage, 40.0); // (1000-600)/1000
        expect(info.appMemoryUsagePercentage, 50.0); // 200/400
      });

      test('should support copyWith functionality', () {
        const original = MemoryInfo(
          totalPhysicalMemory: 1000,
          availablePhysicalMemory: 500,
        );

        final updated = original.copyWith(
          availablePhysicalMemory: 400,
          appMemoryUsage: 100,
        );

        expect(updated.totalPhysicalMemory, 1000);
        expect(updated.availablePhysicalMemory, 400);
        expect(updated.appMemoryUsage, 100);
      });
    });

    group('CPUInfo Tests', () {
      test('should create CPU info', () {
        const info = CPUInfo(
          architecture: 'arm64',
          coreCount: 8,
          clockSpeed: 3200000000, // 3.2 GHz
          currentUsage: 45.5,
          temperature: 65.0,
          processorName: 'Apple M1',
          vendor: 'Apple',
        );

        expect(info.architecture, 'arm64');
        expect(info.coreCount, 8);
        expect(info.clockSpeed, 3200000000);
        expect(info.currentUsage, 45.5);
        expect(info.temperature, 65.0);
        expect(info.processorName, 'Apple M1');
        expect(info.vendor, 'Apple');
      });

      test('should support copyWith functionality', () {
        const original = CPUInfo(
          architecture: 'x64',
          coreCount: 4,
          currentUsage: 30.0,
        );

        final updated = original.copyWith(
          currentUsage: 60.0,
          temperature: 70.0,
        );

        expect(updated.architecture, 'x64');
        expect(updated.coreCount, 4);
        expect(updated.currentUsage, 60.0);
        expect(updated.temperature, 70.0);
      });
    });

    group('StorageInfo Tests', () {
      test('should create storage info', () {
        const info = StorageInfo(
          totalSpace: 1000000000000, // 1TB
          availableSpace: 500000000000, // 500GB
          usedSpace: 500000000000, // 500GB
          isExternal: false,
          isRemovable: false,
          fileSystem: 'APFS',
          path: '/System/Volumes/Data',
        );

        expect(info.totalSpace, 1000000000000);
        expect(info.availableSpace, 500000000000);
        expect(info.usedSpace, 500000000000);
        expect(info.isExternal, isFalse);
        expect(info.isRemovable, isFalse);
        expect(info.fileSystem, 'APFS');
        expect(info.path, '/System/Volumes/Data');
      });

      test('should calculate usage percentage', () {
        const info = StorageInfo(
          totalSpace: 1000,
          availableSpace: 300,
          usedSpace: 700,
        );

        expect(info.usagePercentage, 70.0); // 700/1000
      });

      test('should support copyWith functionality', () {
        const original = StorageInfo(
          totalSpace: 1000,
          availableSpace: 500,
          usedSpace: 500,
        );

        final updated = original.copyWith(
          availableSpace: 300,
          usedSpace: 700,
        );

        expect(updated.totalSpace, 1000);
        expect(updated.availableSpace, 300);
        expect(updated.usedSpace, 700);
      });
    });

    group('DeviceInfo Tests', () {
      test('should create device info', () {
        const info = DeviceInfo(
          deviceId: 'device-123',
          deviceName: 'iPhone 14 Pro',
          deviceModel: 'iPhone15,2',
          manufacturer: 'Apple',
          brand: 'Apple',
          osName: 'iOS',
          osVersion: '17.0',
          kernelVersion: '23.0.0',
          isPhysicalDevice: true,
          isEmulator: false,
          supportedAbis: ['arm64-v8a'],
          systemFeatures: ['camera', 'bluetooth'],
        );

        expect(info.deviceId, 'device-123');
        expect(info.deviceName, 'iPhone 14 Pro');
        expect(info.deviceModel, 'iPhone15,2');
        expect(info.manufacturer, 'Apple');
        expect(info.brand, 'Apple');
        expect(info.osName, 'iOS');
        expect(info.osVersion, '17.0');
        expect(info.kernelVersion, '23.0.0');
        expect(info.isPhysicalDevice, isTrue);
        expect(info.isEmulator, isFalse);
        expect(info.supportedAbis, contains('arm64-v8a'));
        expect(info.systemFeatures, contains('camera'));
      });

      test('should support copyWith functionality', () {
        const original = DeviceInfo(
          deviceId: 'test-device',
          deviceName: 'Test Device',
          osVersion: '1.0',
        );

        final updated = original.copyWith(
          osVersion: '2.0',
          isEmulator: true,
        );

        expect(updated.deviceId, 'test-device');
        expect(updated.deviceName, 'Test Device');
        expect(updated.osVersion, '2.0');
        expect(updated.isEmulator, isTrue);
      });
    });
  });
}
