import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

part 'notification_service_platform.dart';
part 'log_service.dart';

/// A singleton service that manages notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Function(String? payload)? _onNotificationTap;

  /// Initializes the local time zone and the notification service.
  ///
  /// This master initialization method should typically be called inside your
  /// `main()` function (after `WidgetsFlutterBinding.ensureInitialized()`) before
  /// scheduling any time-sensitive or recurring notifications.
  ///
  /// ### Parameters:
  /// - [onNotificationTap]: A callback function triggered whenever the user taps
  ///   a notification.
  /// - [initTimeZone]: If `true`, the local time zone is initialized. Set to
  ///   `false` if you are handling time zone setup elsewhere.
  Future<void> init({
    Function(String? payload)? onNotificationTap,
    bool initTimeZone = true,
  }) async {
    try {
      if (initTimeZone) {
        tz.initializeTimeZones();

        final String timeZoneName = await FlutterTimezone.getLocalTimezone()
            .then((value) => value.identifier);

        tz.setLocalLocation(tz.getLocation(timeZoneName));

        Log.i('Timezone initialized successfully to: $timeZoneName');
      }
    } catch (e) {
      Log.e('Failed to initialize timezones: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _onNotificationTap = onNotificationTap;
  }

  /// Creates a notification channel on Android.
  ///
  /// Notification channels allow apps to group their notifications into
  /// manageable categories. Users can customize settings such as sound,
  /// vibration, or importance for each channel in Android system settings.
  ///
  /// Note: This method is a no-op on non-Android platforms.
  ///
  /// ### Parameters:
  /// - [channelId]: A unique identifier for the channel.
  /// - [channelName]: The display name shown to users.
  /// - [channelDescription]: A short summary describing the channel.
  /// - [importance]: The notification importance level on Android.
  /// - [priority]: The priority level for older Android versions.
  /// - [channelGroupId]: Optional group identifier for the channel.
  /// - [channelGroupName]: Optional display name for the channel group.
  /// - [channelGroupDescription]: Optional description for the channel group.
  Future<void> createChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required Importance importance,
    required Priority priority,
    String? channelGroupId,
    String? channelGroupName,
    String? channelGroupDescription,
  }) async {
    await runIfInitialized(() async {
      if (TargetPlatform.android != defaultTargetPlatform) return;

      final groupParams = [channelGroupId, channelGroupName];
      final givenCount = groupParams.where((p) => p != null).length;

      if (givenCount > 0 && givenCount < 2) {
        throw ArgumentError(
          'If any channel group parameter is provided, both (id, name) must be provided.',
        );
      }

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        if (givenCount == 2) {
          await androidPlugin.createNotificationChannelGroup(
            AndroidNotificationChannelGroup(
              channelGroupId!,
              channelGroupName!,
              description: channelDescription,
            ),
          );
        }

        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: importance,
            groupId: channelGroupId,
          ),
        );
      }
    });
  }

  /// Cancels all scheduled and displayed notifications.
  Future<void> cancelAllNotifications() async {
    await runIfInitialized(() async {
      Log.i('All notifications cancelled');
      await flutterLocalNotificationsPlugin.cancelAll();
    });
  }

  /// Cancels a specific notification.
  ///
  /// ### Parameters:
  /// - [id]: The ID of the notification to cancel.
  Future<void> cancelNotification(int id) async {
    await runIfInitialized(() async {
      await flutterLocalNotificationsPlugin.cancel(id: id);
      Log.i('Cancelled notifications for id: $id');
    });
  }

  /// Shows a notification immediately.
  ///
  /// Displays a notification right away using the specified platform details.
  ///
  /// ### Parameters:
  /// - [title]: The title displayed at the top of the notification.
  /// - [body]: The main text content of the notification.
  /// - [notificationDetails]: Platform-specific configuration.
  /// - [payload]: Optional data passed when the user interacts with the notification.
  Future<void> showNotification({
    required String title,
    required String body,
    required NotificationDetails notificationDetails,
    String? payload,
  }) async {
    await runIfInitialized(() async {
      await flutterLocalNotificationsPlugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    });
  }

  /// Schedules a notification to be shown at a specific time.
  ///
  /// ### Parameters:
  /// - [id]: Unique notification identifier.
  /// - [title]: Title displayed in the notification.
  /// - [body]: Content displayed in the notification.
  /// - [scheduleDate]: Date and time when the notification should be displayed.
  /// - [notificationDetails]: Platform-specific notification configuration.
  /// - [payload]: Optional data passed when the user opens the notification.
  Future<bool?> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleDate,
    required NotificationDetails notificationDetails,
    String? payload,
  }) => runIfInitialized<bool?>(() async {
    if (scheduleDate.isAfter(DateTime.now())) {
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduleDate, tz.local),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (e) {
        Log.e(
          "Could not Schedule notification on ${defaultTargetPlatform.name}",
          error: e,
        );
        return null;
      }
    } else {
      Log.i("Schedule time was before current time, so skipped.");
      return null;
    }
    Log.i('Scheduled notifications with id: $id');
    return true;
  });
}
