# Bellflow

Bellflow is a lightweight Flutter helper for timezone-aware local notifications.

It wraps `flutter_local_notifications` and adds a small convenience layer for:

- initializing the device timezone
- configuring platform-specific notification plugins
- showing, scheduling, and cancelling notifications
- creating Android notification channels

## Requirements

- Flutter 3.38.1 or later
- Android, iOS, Linux, or Windows
- The host app must still handle the platform-specific notification permissions and setup required by `flutter_local_notifications`

This package currently does not provide macOS or web initialization.

## Installation

Add Bellflow to your app:

```yaml
dependencies:
  bellflow: ^0.1.0
```

Then run:

```sh
flutter pub get
```

## Public API overview

`NotificationService` exposes a small, platform-aware API for local notifications:

- `init(...)` initializes timezone handling and the notification tap callback.
- `initAndroid(...)` configures Android notification settings and handles Android permissions.
- `initIOS(...)` configures iOS notification settings and permission requests.
- `initLinux(...)` configures Linux notification defaults.
- `initWindows(...)` configures Windows notification registration.
- `createChannel(...)` creates an Android notification channel.
- `showNotification(...)` displays a notification immediately.
- `scheduleNotification(...)` schedules a future notification.
- `cancelNotification(...)` cancels one notification.
- `cancelAllNotifications()` cancels all notifications.

## Basic usage

`NotificationService` is a singleton, so calling `NotificationService()` always gives the same instance.

```dart
import 'package:bellflow/bellflow.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService();

  await notifications.init(
    onNotificationTap: (payload) {
      debugPrint('Tapped notification: $payload');
    },
  );

  if (defaultTargetPlatform == TargetPlatform.android) {
    final permissionGranted = await notifications.initAndroid(
      requestExactAlarmsPermission: true,
    );

    if (permissionGranted == true) {
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
      appName: 'My App',
      appUserModelId: 'Com.Example.MyApp',
      guid: '123e4567-e89b-12d3-a456-426614174000',
    );
  }
}
```

## Scheduling a notification

```dart
final scheduled = await notifications.scheduleNotification(
  id: 1,
  title: 'Reminder',
  body: 'Your reminder is ready.',
  scheduleDate: DateTime.now().add(const Duration(minutes: 15)),
  payload: 'reminder-1',
  notificationDetails: const NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Scheduled reminders',
      importance: Importance.max,
      priority: Priority.high,
    ),
  ),
);

if (scheduled == true) {
  debugPrint('Notification scheduled successfully.');
}
```

The scheduled time must be in the future. If it is in the past, Bellflow logs the event and returns `null`.

## Showing an immediate notification

```dart
await notifications.showNotification(
  title: 'Hello',
  body: 'This notification was shown immediately.',
  notificationDetails: const NotificationDetails(
    android: AndroidNotificationDetails(
      'general',
      'General',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  ),
);
```

## Cancelling notifications

```dart
await notifications.cancelNotification(1);
await notifications.cancelAllNotifications();
```

## Android notes

Android-specific setup still needs to be handled in the app, especially:

- `POST_NOTIFICATIONS` permission on Android 13+
- exact alarm permission when using precise scheduling
- the receiver and manifest configuration expected by `flutter_local_notifications`

See the plugin's Android setup guide before shipping to production.

## Development

Run the package checks from this directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter pub publish --dry-run
```

Bellflow is distributed under the MIT License. See [LICENSE](LICENSE).
