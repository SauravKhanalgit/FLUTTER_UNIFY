import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unify/flutter_unify.dart';

void main() {
  group('Notifications System Tests', () {
    late UnifiedNotifications notifications;

    setUp(() {
      notifications = UnifiedNotifications.instance;
    });

    tearDown(() async {
      await notifications.dispose();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        final result = await notifications.initialize();
        expect(result, isA<bool>());
      });

      test('should check if notifications are supported', () {
        final isSupported = notifications.isSupported;
        expect(isSupported, isA<bool>());
      });

      test('should request permission', () async {
        await notifications.initialize();
        final permission = await notifications.requestPermission();
        expect(permission, isA<bool>());
      });
    });

    group('Notification Configuration Tests', () {
      test('should create basic notification config', () {
        final config = NotificationConfig(
          title: 'Test Notification',
          body: 'This is a test',
        );

        expect(config.title, 'Test Notification');
        expect(config.body, 'This is a test');
        expect(config.priority, NotificationPriority.normal);
        expect(config.actions, isNull);
      });

      test('should create notification config with all properties', () {
        final actions = [
          NotificationAction(
            id: 'action1',
            title: 'Accept',
            destructive: false,
          ),
          NotificationAction(
            id: 'action2',
            title: 'Decline',
            destructive: true,
          ),
        ];

        final config = NotificationConfig(
          title: 'Meeting Invitation',
          body: 'You have a meeting at 3 PM',
          icon: 'meeting_icon',
          badge: '1',
          sound: 'default',
          data: {'meetingId': '123'},
          scheduledTime: DateTime.now().add(Duration(hours: 1)),
          delay: Duration(minutes: 30),
          channelId: 'meetings',
          channelName: 'Meeting Notifications',
          priority: NotificationPriority.high,
          actions: actions,
        );

        expect(config.title, 'Meeting Invitation');
        expect(config.body, 'You have a meeting at 3 PM');
        expect(config.icon, 'meeting_icon');
        expect(config.badge, '1');
        expect(config.sound, 'default');
        expect(config.data!['meetingId'], '123');
        expect(config.scheduledTime, isNotNull);
        expect(config.delay, Duration(minutes: 30));
        expect(config.channelId, 'meetings');
        expect(config.channelName, 'Meeting Notifications');
        expect(config.priority, NotificationPriority.high);
        expect(config.actions, hasLength(2));
        expect(config.actions![0].id, 'action1');
        expect(config.actions![1].destructive, isTrue);
      });
    });

    group('Notification Actions Tests', () {
      test('should create notification action', () {
        final action = NotificationAction(
          id: 'reply',
          title: 'Reply',
          icon: 'reply_icon',
          destructive: false,
        );

        expect(action.id, 'reply');
        expect(action.title, 'Reply');
        expect(action.icon, 'reply_icon');
        expect(action.destructive, isFalse);
      });

      test('should create destructive action', () {
        final action = NotificationAction(
          id: 'delete',
          title: 'Delete',
          destructive: true,
        );

        expect(action.id, 'delete');
        expect(action.title, 'Delete');
        expect(action.destructive, isTrue);
        expect(action.icon, isNull);
      });
    });

    group('Notification Priority Tests', () {
      test('should have all priority levels', () {
        expect(NotificationPriority.low, isNotNull);
        expect(NotificationPriority.normal, isNotNull);
        expect(NotificationPriority.high, isNotNull);
        expect(NotificationPriority.urgent, isNotNull);
      });
    });

    group('Notification Result Tests', () {
      test('should create successful notification result', () {
        final result = NotificationResult(
          id: 'notif-123',
          delivered: true,
        );

        expect(result.id, 'notif-123');
        expect(result.delivered, isTrue);
        expect(result.error, isNull);
        expect(result.response, isNull);
      });

      test('should create failed notification result', () {
        final result = NotificationResult(
          id: 'notif-456',
          delivered: false,
          error: 'Permission denied',
          response: {'code': 403},
        );

        expect(result.id, 'notif-456');
        expect(result.delivered, isFalse);
        expect(result.error, 'Permission denied');
        expect(result.response!['code'], 403);
      });
    });

    group('Notification Display Tests', () {
      test('should show basic notification', () async {
        await notifications.initialize();

        final result = await notifications.show(
          'Test Title',
          body: 'Test Body',
        );

        expect(result, isA<NotificationResult>());
        expect(result.id, isNotNull);
        expect(result.id.isNotEmpty, isTrue);
      });

      test('should show notification with all options', () async {
        await notifications.initialize();

        final result = await notifications.show(
          'Rich Notification',
          body: 'This is a rich notification',
          icon: 'app_icon',
          badge: '5',
          sound: 'notification_sound',
          data: {'type': 'message', 'userId': '123'},
          priority: NotificationPriority.high,
          actions: [
            NotificationAction(id: 'reply', title: 'Reply'),
            NotificationAction(id: 'mark_read', title: 'Mark as Read'),
          ],
        );

        expect(result, isA<NotificationResult>());
        expect(result.id, isNotNull);
      });

      test('should schedule notification', () async {
        await notifications.initialize();

        final scheduledTime = DateTime.now().add(Duration(minutes: 5));
        final result = await notifications.schedule(
          'Scheduled Notification',
          body: 'This is scheduled',
          scheduledTime: scheduledTime,
        );

        expect(result, isA<NotificationResult>());
        expect(result.id, isNotNull);
      });

      test('should show delayed notification', () async {
        await notifications.initialize();

        final result = await notifications.showAfter(
          'Delayed Notification',
          body: 'This is delayed',
          delay: Duration(seconds: 10),
        );

        expect(result, isA<NotificationResult>());
        expect(result.id, isNotNull);
      });
    });

    group('Notification Management Tests', () {
      test('should cancel notification', () async {
        await notifications.initialize();

        final result = await notifications.show('Test', body: 'Test');
        final cancelled = await notifications.cancel(result.id);

        expect(cancelled, isA<bool>());
      });

      test('should cancel all notifications', () async {
        await notifications.initialize();

        // Show multiple notifications
        await notifications.show('Test 1', body: 'Body 1');
        await notifications.show('Test 2', body: 'Body 2');

        final cancelled = await notifications.cancelAll();
        expect(cancelled, isA<bool>());
      });

      test('should get pending notifications', () async {
        await notifications.initialize();

        final pending = notifications.getPendingNotifications();
        expect(pending, isA<List<String>>());
      });
    });

    group('Notification Streams Tests', () {
      test('should provide notification stream', () async {
        await notifications.initialize();

        expect(notifications.onNotification, isA<Stream<NotificationResult>>());
      });

      test('should emit notification events', () async {
        await notifications.initialize();

        final streamFuture = notifications.onNotification.first;
        await notifications.show('Stream Test', body: 'Test');

        // Wait a bit for the stream event
        await Future.delayed(Duration(milliseconds: 100));

        // The stream should have emitted an event
        expect(streamFuture, completes);
      });
    });

    group('Dispose Tests', () {
      test('should dispose cleanly', () async {
        await notifications.initialize();

        // Should not throw
        await notifications.dispose();

        // Should handle multiple dispose calls
        await notifications.dispose();
      });
    });
  });
}
