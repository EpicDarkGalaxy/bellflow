import 'package:flutter_test/flutter_test.dart';
import 'package:bellflow/bellflow.dart';

void main() {
  late NotificationService notifications;

  setUp(() {
    notifications = NotificationService();
  });

  test('NotificationService exposes a singleton instance', () {
    expect(identical(notifications, NotificationService()), isTrue);
  });

  test(
    'init completes without throwing when timezone initialization is skipped',
    () async {
      await expectLater(notifications.init(initTimeZone: false), completes);
    },
  );

  test('scheduleNotification throws before initialization', () {
    expect(
      () => notifications.scheduleNotification(
        id: 42,
        title: 'Past reminder',
        body: 'This reminder should not be scheduled before initialization.',
        scheduleDate: DateTime.now().add(const Duration(minutes: 1)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'test-channel',
            'Test Channel',
            channelDescription: 'Test notifications',
          ),
        ),
      ),
      throwsAssertionError,
    );
  });
}
