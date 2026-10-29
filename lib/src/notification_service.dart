import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

extension on NotificationService {
  Future<T?> runIfInitialized<T>(Future<T> Function() action) async {
    assert(
      _initialized,
      'NotificationService is not initialized. Call init() and respective platform initialization methods first.',
    );
    if (!_initialized) {
      _Log.w('Attempted to run notification action before initialization.');
      return null;
    }

    return action();
  }
}

extension on NotificationService {
  Future<T?> runIfPlatformSupports<T>(
    Future<T> Function() action, {
    required TargetPlatform platform,
  }) async {
    if (platform == defaultTargetPlatform) {
      return action();
    }

    _Log.w('Skipped platform initialization for $platform');
    return null;
  }
}

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
  /// This master initialization method should typically be called inside your `main()`
  /// function (after `WidgetsFlutterBinding.ensureInitialized()`) before scheduling
  /// any time-sensitive or recurring notifications.
  ///
  /// ### Parameters:
  /// - [onNotificationTap]: A callback function triggered whenever the user taps
  ///   on a notification banner or notification center item.
  /// - [initTimeZone]: If `true`, the local time zone will be initialized. Set to
  ///   `false` if you're handling time zone initialization elsewhere.
  Future<void> init({
    Function(String? payload)? onNotificationTap,
    bool initTimeZone = true,
  }) async {
    try {
      if (initTimeZone) {
        tz.initializeTimeZones();

        // Retrieve the device's local timezone name
        final String timeZoneName = await FlutterTimezone.getLocalTimezone()
            .then((value) => value.identifier);

        // Set the local location using the exact timezone name
        tz.setLocalLocation(tz.getLocation(timeZoneName));

        _Log.i('Timezone initialized successfully to: $timeZoneName');
      }
    } catch (e) {
      _Log.e('Failed to initialize timezones: $e');
      // Fallback safely to UTC if retrieving the device timezone fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _onNotificationTap = onNotificationTap;
  }

  /// Initializes local notifications for Android.
  ///
  /// Configures default platform settings, such as the default small icon
  /// used in the status bar and notification shade.
  ///
  /// ### Parameters:
  /// - [iconPath]: The name or path of the Android drawable resource used as the
  ///   default small icon for notifications (e.g., `'@mipmap/ic_launcher'` or `'app_icon'`).
  /// - [requestExactAlarmsPermission]: If `true`, requests the `SCHEDULE_EXACT_ALARM`
  ///   permission on Android 12 and above. This is required for scheduling notifications
  ///   at precise times. Defaults to `false`.
  Future<bool?> initAndroid({
    String? iconPath,
    bool requestExactAlarmsPermission = false,
  }) => runIfPlatformSupports<bool?>(() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(iconPath ?? '@mipmap/ic_launcher');
    await _initializeSettings(
      androidInitializationSettings: initializationSettingsAndroid,
    );
    final bool? permissionGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (requestExactAlarmsPermission) {
      final bool? exactAlarmsPermissionGranted =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestExactAlarmsPermission();
      if (exactAlarmsPermissionGranted != null &&
          !exactAlarmsPermissionGranted) {
        _Log.e('Exact alarms permission denied');
        return false;
      }
    }
    if (permissionGranted != null && !permissionGranted) {
      _Log.e('Notification permission denied');
    }
    return permissionGranted;
  }, platform: TargetPlatform.android);

  /// Initializes local notifications for iOS.
  ///
  /// Requests user authorization for notification delivery and establishes default
  /// presentation options for notifications received while the app is in the foreground.
  ///
  /// ### Parameters:
  /// - [requestAlertPermission]: Whether to request permission to display alert banners.
  /// - [requestSoundPermission]: Whether to request permission to play notification sounds.
  /// - [requestBadgePermission]: Whether to request permission to update app icon badge counts.
  /// - [requestProvisionalPermission]: Whether to request provisional authorization to post
  ///   non-interrupting notifications quietly to the Notification Center.
  /// - [requestCriticalPermission]: Whether to request permission to bypass the device mute switch
  ///   (requires a special entitlement from Apple).
  /// - [requestProvidesAppNotificationSettings]: Whether to display a button in system settings
  ///   allowing users to configure notifications from within your app.
  /// - [requestCarPlayPermission]: Whether to request permission to display notifications in CarPlay.
  /// - [defaultPresentAlert]: Default foreground presentation option to show alert banners.
  /// - [defaultPresentSound]: Default foreground presentation option to play audio.
  /// - [defaultPresentBadge]: Default foreground presentation option to update badges.
  /// - [defaultPresentBanner]: Default foreground presentation option for modern banners (iOS 14+).
  /// - [defaultPresentList]: Default foreground presentation option to add items to the notification list (iOS 14+).
  /// - [notificationCategories]: Custom interactive notification categories containing action buttons.
  Future<bool?> initIOS({
    bool requestAlertPermission = true,
    bool requestSoundPermission = true,
    bool requestBadgePermission = true,
    bool requestProvisionalPermission = false,
    bool requestCriticalPermission = false,
    bool requestProvidesAppNotificationSettings = false,
    bool requestCarPlayPermission = false,
    bool defaultPresentAlert = true,
    bool defaultPresentSound = true,
    bool defaultPresentBadge = true,
    bool defaultPresentBanner = true,
    bool defaultPresentList = true,
    List<DarwinNotificationCategory> notificationCategories =
        const <DarwinNotificationCategory>[],
  }) => runIfPlatformSupports<bool?>(() async {
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
          requestAlertPermission: requestAlertPermission,
          requestSoundPermission: requestSoundPermission,
          requestBadgePermission: requestBadgePermission,
          requestProvisionalPermission: requestProvisionalPermission,
          requestCriticalPermission: requestCriticalPermission,
          requestProvidesAppNotificationSettings:
              requestProvidesAppNotificationSettings,
          requestCarPlayPermission: requestCarPlayPermission,
          defaultPresentAlert: defaultPresentAlert,
          defaultPresentSound: defaultPresentSound,
          defaultPresentBadge: defaultPresentBadge,
          defaultPresentBanner: defaultPresentBanner,
          defaultPresentList: defaultPresentList,
          notificationCategories: notificationCategories,
        );
    final result = await _initializeSettings(
      iosInitializationSettings: initializationSettingsIOS,
    );
    if (result == null) {
      throw Exception("Failed to initialized notification for IOS");
    }
    final alertPermissionGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(
          alert: requestAlertPermission,
          badge: requestBadgePermission,
          sound: requestSoundPermission,
          provisional: requestProvisionalPermission,
          critical: requestCriticalPermission,
          carPlay: requestCarPlayPermission,
          providesAppNotificationSettings:
              requestProvidesAppNotificationSettings,
        );
    if (alertPermissionGranted == null) {
      throw Exception('Failed to request permissions for iOS');
    } else {
      _Log.i('iOS notification permissions were granted');
      return alertPermissionGranted;
    }
  }, platform: TargetPlatform.iOS);

  /// Initializes local notifications for Linux desktop environments.
  ///
  /// Sets up default parameters used across notifications on Linux systems
  /// (such as GNOME, KDE, or XFCE) when specific properties are omitted.
  ///
  /// ### Parameters:
  /// - [defaultActionName]: The default action label triggered when a user clicks
  ///   the notification body (defaults to `'Open notification'`).
  /// - [defaultIcon]: The default icon used for notifications if none is specified.
  /// - [defaultSound]: The default system sound or file to play when a notification arrives.
  /// - [defaultSuppressSound]: Whether to mute notification sounds by default.
  Future<bool?> initLinux({
    String defaultActionName = 'Open notification',
    AssetsLinuxIcon? defaultIcon,
    LinuxNotificationSound? defaultSound,
    bool defaultSuppressSound = false,
  }) => runIfPlatformSupports<bool?>(() async {
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
          defaultActionName: defaultActionName,
          defaultIcon: defaultIcon,
          defaultSound: defaultSound,
          defaultSuppressSound: defaultSuppressSound,
        );
    final result = await _initializeSettings(
      linuxInitializationSettings: initializationSettingsLinux,
    );
    return result;
  }, platform: TargetPlatform.linux);

  /// Initializes local notifications for Windows.
  ///
  /// This must be called before displaying notifications on Windows to register
  /// the app with the Windows Action Center.
  ///
  /// ### Parameters:
  /// - [appName]: The display name of the application.
  /// - [appUserModelId]: The Application User Model ID (AUMID) used by Windows
  ///   to tie notifications and shortcuts to your app.
  /// - [guid]: The unique Globally Unique Identifier (GUID) for the app.
  /// - [iconPath]: The absolute or relative file path to the app's notification icon.
  Future<bool?> initWindows({
    required String appName,
    required String appUserModelId,
    required String guid,
    String? iconPath,
  }) => runIfPlatformSupports<bool?>(() async {
    final WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: appName,
          appUserModelId: appUserModelId,
          guid: guid,
          iconPath: iconPath,
        );
    final result = await _initializeSettings(
      windowsInitializationSettings: initializationSettingsWindows,
    );
    return result;
  }, platform: TargetPlatform.windows);

  Future<bool?> _initializeSettings({
    AndroidInitializationSettings? androidInitializationSettings,
    IOSInitializationSettings? iosInitializationSettings,
    LinuxInitializationSettings? linuxInitializationSettings,
    WindowsInitializationSettings? windowsInitializationSettings,
  }) async {
    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
      linux: linuxInitializationSettings,
      windows: windowsInitializationSettings,
    );
    final result = await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (_onNotificationTap == null) return;
        _onNotificationTap!(details.payload);
      },
    );
    if (result == null) {
      throw Exception('Failed to initialize notifications');
    } else if (!result) {
      _initialized = false;
      _Log.e("Could not initialize");
      return result;
    }
    _initialized = true;
    _Log.i("Notification Initialized!");
    return result;
  }

  /// Creates a notification channel on Android.
  ///
  /// Notification channels allow apps to group notifications into manageable
  /// categories. Users can then customize settings (such as sound, vibration,
  /// or importance) for each channel individually in Android system settings.
  ///
  /// Note: This method is a **no-op** on non-Android platforms (e.g., iOS, Linux).
  ///
  /// ### Parameters:
  /// - [channelId]: A unique string identifier for this notification channel.
  /// - [channelName]: The display name shown to users in system settings.
  /// - [channelDescription]: A short summary explaining what notifications from
  ///   this channel are about (visible in system settings).
  /// - [importance]: The notification importance level on Android (controls sound,
  ///   vibration, and heads-up banners).
  /// - [priority]: The priority level for older Android versions (pre-Android 8.0).
  /// - [channelGroupId]: An optional unique identifier to group multiple channels
  ///   together under a single section in settings.
  /// - [channelGroupName]: The display name of the channel group.
  /// - [channelGroupDescription]: A short explanation of what the channel group contains.
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

      // Validate group parameters (if any)
      // Ensure all 3 channel group parameters are provided together, or none at all
      final groupParams = [channelGroupId, channelGroupName];
      final givenCount = groupParams.where((p) => p != null).length;

      if (givenCount > 0 && givenCount < 2) {
        throw ArgumentError(
          'If any channel group parameter is provided, both (id, name) must be provided.',
        );
      }
      // Target only Android platforms (iOS doesn't use notification channels)
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

  /// Cancels all notifications.
  Future<void> cancelAllNotifications() async {
    await runIfInitialized(() async {
      _Log.i('All notifications cancelled');
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
      _Log.i('Cancelled notifications for id: $id');
    });
  }

  /// Shows a notification immediately.
  ///
  /// Displays a notification right away using the specified platform details.
  ///
  /// ### Parameters:
  /// - [title]: The title displayed at the top of the notification.
  /// - [body]: The main text content of the notification.
  /// - [notificationDetails]: Platform-specific configuration (channels, sounds, icons, etc.).
  /// - [payload]: Optional data string passed along when the user interacts with the notification.
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
        _Log.e(
          "Could not Schedule notification on ${defaultTargetPlatform.name}",
          error: e,
        );
        return null;
      }
    } else {
      _Log.i("Schedule time was before current time, so skipped.");
      return null;
    }
    _Log.i('Scheduled notifications with id: $id');
    return true;
  });
}

class _Log {
  static const int _defaultWidth = 120;

  static void i(
    String message, {
    String symbol = '💡',
    int width = _defaultWidth,
  }) {
    _print(message, symbol: symbol, width: width);
  }

  static void w(
    String message, {
    String symbol = '⚠️',
    int width = _defaultWidth,
  }) {
    _print(message, symbol: symbol, width: width);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String symbol = '❌',
    int width = _defaultWidth,
  }) {
    final fullMessage = StringBuffer(message);
    if (error != null) fullMessage.write('\nError: $error');
    if (stackTrace != null) fullMessage.write('\nStackTrace:\n$stackTrace');

    _print(fullMessage.toString(), symbol: symbol, width: width);
  }

  static void _print(
    String message, {
    required String symbol,
    required int width,
  }) {
    if (!kDebugMode) return;

    final topBorder = '┌${'─' * (width - 1)}';
    final bottomBorder = '└${'─' * (width - 1)}';

    debugPrint(topBorder);
    for (final line in message.split('\n')) {
      debugPrint('│ $symbol $line [Notification Service]');
    }
    debugPrint(bottomBorder);
  }
}
