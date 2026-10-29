# Bellflow

A Flutter service for initializing local notifications, retrieving the device timezone, and scheduling notifications with `flutter_local_notifications`.

Bellflow provides timezone-aware local notification scheduling for Flutter.

Source: [minimal_expiry_tracker](https://github.com/EpicDarkGalaxy/minimal_expiry_tracker/tree/main/packages/bellflow).

## Requirements

- Flutter 3.38.1 or later
- Android, iOS, Linux, or Windows

The host app must provide the platform-specific notification permissions and setup required by `flutter_local_notifications`. This package currently has no macOS or web initializer.

## Usage

Initialize the timezone service and the platform notification plugin before scheduling notifications:

```dart
import 'package:bellflow/bellflow.dart';

final notifications = NotificationService();
await notifications.init();
final permissionGranted = await notifications.initAndroid(
  requestExactAlarmsPermission: true,
);

if (permissionGranted == true) {
  await notifications.scheduleNotification(
    id: 1,
    title: 'Reminder',
    body: 'Your reminder is ready.',
    scheduleDate: DateTime.now().add(const Duration(hours: 1)),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Scheduled reminders',
      ),
    ),
  );
}
```

Call `initIOS`, `initLinux`, or `initWindows` instead of `initAndroid` on those platforms. Android notification channels can be created with `createChannel` after `initAndroid`.

## Android setup

Configure the host application's `AndroidManifest.xml` for its target Android versions. In particular, account for the `POST_NOTIFICATIONS` runtime permission on Android 13+, exact alarm access when using exact scheduling, and the scheduled-notification receivers required by `flutter_local_notifications`. Review that plugin's Android setup guide before release because Android permission and receiver requirements vary by plugin and Android version.

## Development

Run the package checks from this directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter pub publish --dry-run
```

Bellflow is distributed under the MIT License. See [LICENSE](LICENSE).
