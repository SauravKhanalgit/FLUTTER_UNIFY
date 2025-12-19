import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/src/models/networking_models.dart';
import 'package:flutter_unify/src/networking/offline_queue_store.dart';

void main() {
  group('MemoryQueueStore', () {
    late MemoryQueueStore store;

    setUp(() {
      store = MemoryQueueStore();
    });

    test('should initialize', () async {
      await store.initialize();
      expect(store, isNotNull);
    });

    test('should save and load requests', () async {
      await store.initialize();
      
      final request = NetworkRequest(
        method: HttpMethod.get,
        url: 'https://example.com',
      );
      
      await store.save([request]);
      final loaded = await store.load();
      
      expect(loaded.length, equals(1));
      expect(loaded.first.url, equals('https://example.com'));
    });

    test('should clear queue', () async {
      await store.initialize();
      
      final request = NetworkRequest(
        method: HttpMethod.post,
        url: 'https://example.com',
      );
      
      await store.save([request]);
      await store.clear();
      final loaded = await store.load();
      
      expect(loaded.length, equals(0));
    });

    test('should handle multiple requests', () async {
      await store.initialize();
      
      final requests = [
        NetworkRequest(method: HttpMethod.get, url: 'https://example.com/1'),
        NetworkRequest(method: HttpMethod.post, url: 'https://example.com/2'),
      ];
      
      await store.save(requests);
      final loaded = await store.load();
      
      expect(loaded.length, equals(2));
    });
  });

  group('NetworkRequestSerialization', () {
    test('should serialize and deserialize request', () {
      final original = NetworkRequest(
        method: HttpMethod.post,
        url: 'https://example.com/api',
        data: {'key': 'value'},
        headers: {'Content-Type': 'application/json'},
        queryParameters: {'param': 'value'},
        retryOnFailure: true,
        maxRetries: 5,
        priority: 10,
      );

      final serialized = original.toPersistedMap();
      final deserialized = NetworkRequestSerialization.fromPersistedMap(serialized);

      expect(deserialized.method, equals(original.method));
      expect(deserialized.url, equals(original.url));
      expect(deserialized.retryOnFailure, equals(original.retryOnFailure));
      expect(deserialized.maxRetries, equals(original.maxRetries));
      expect(deserialized.priority, equals(original.priority));
    });

    test('should handle all HTTP methods', () {
      for (final method in HttpMethod.values) {
        final request = NetworkRequest(method: method, url: 'https://example.com');
        final serialized = request.toPersistedMap();
        final deserialized = NetworkRequestSerialization.fromPersistedMap(serialized);
        expect(deserialized.method, equals(method));
      }
    });
  });
}

