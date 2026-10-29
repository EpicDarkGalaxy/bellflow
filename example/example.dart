import 'package:bellflow/bellflow.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  final notifications = NotificationService();

  await notifications.init(
    onNotificationTap: (payload) {
      if (kDebugMode) {
        print('Notification tapped with payload: $payload');
      }
    },
  );

  if (defaultTargetPlatform == TargetPlatform.android) {
    final granted = await notifications.initAndroid(
      requestExactAlarmsPermission: true,
    );

    if (granted == true) {
      await notifications.createChannel(
        channelId: 'reminders',
        channelName: 'Reminders',
        channelDescription: 'Scheduled reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
    }
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    await notifications.initIOS();
  } else if (defaultTargetPlatform == TargetPlatform.linux) {
    await notifications.initLinux();
  } else if (defaultTargetPlatform == TargetPlatform.windows) {
    await notifications.initWindows(
      appName: 'Bellflow Example',
      appUserModelId: 'com.example.bellflow',
      guid: '123e4567-e89b-12d3-a456-426614174000',
    );
  }

  await notifications.scheduleNotification(
    id: 1,
    title: 'Bellflow reminder',
    body: 'This is a scheduled notification.',
    scheduleDate: DateTime.now().add(const Duration(minutes: 5)),
    payload: 'demo-reminder',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Scheduled reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}
