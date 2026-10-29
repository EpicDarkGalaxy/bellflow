part of 'notification_service.dart';

extension NotificationServicePlatformHelpers on NotificationService {
  Future<T?> runIfInitialized<T>(Future<T> Function() action) async {
    assert(
      _initialized,
      'NotificationService is not initialized. Call init() and respective platform initialization methods first.',
    );
    if (!_initialized) {
      Log.w('Attempted to run notification action before initialization.');
      return null;
    }

    return action();
  }

  Future<T?> runIfPlatformSupports<T>(
    Future<T> Function() action, {
    required TargetPlatform platform,
  }) async {
    if (platform == defaultTargetPlatform) {
      return action();
    }

    Log.w('Skipped platform initialization for $platform');
    return null;
  }
}

extension NotificationServicePlatformInit on NotificationService {
  /// Initializes local notifications for Android.
  ///
  /// Configures default platform settings and requests the required notification
  /// permissions for Android devices.
  ///
  /// ### Parameters:
  /// - [iconPath]: The name or path of the Android drawable used as the default
  ///   small icon for notifications.
  /// - [requestExactAlarmsPermission]: If `true`, requests the exact alarm
  ///   permission required for precise scheduled delivery.
  Future<bool?> initAndroid({
    String? iconPath,
    bool requestExactAlarmsPermission = false,
  }) => runIfPlatformSupports<bool?>(() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(iconPath ?? '@mipmap/ic_launcher');
    final result = await _initializeSettings(
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
        Log.e('Exact alarms permission denied');
        return false;
      }
    }

    if (permissionGranted != null && !permissionGranted) {
      Log.e('Notification permission denied');
    }

    return result ?? permissionGranted;
  }, platform: TargetPlatform.android);

  /// Initializes local notifications for iOS.
  ///
  /// Requests user authorization and establishes default presentation options for
  /// notifications delivered while the app is in the foreground.
  ///
  /// ### Parameters:
  /// - [requestAlertPermission]: Whether to request alert permission.
  /// - [requestSoundPermission]: Whether to request sound permission.
  /// - [requestBadgePermission]: Whether to request badge permission.
  /// - [requestProvisionalPermission]: Whether to request provisional authorization.
  /// - [requestCriticalPermission]: Whether to request critical alert permission.
  /// - [requestProvidesAppNotificationSettings]: Whether to request settings access.
  /// - [requestCarPlayPermission]: Whether to request CarPlay permission.
  /// - [defaultPresentAlert]: Whether alert banners are displayed by default.
  /// - [defaultPresentSound]: Whether notification sounds play by default.
  /// - [defaultPresentBadge]: Whether badges update by default.
  /// - [defaultPresentBanner]: Whether banners appear by default.
  /// - [defaultPresentList]: Whether items are added to the notification list.
  /// - [notificationCategories]: Custom interactive notification categories.
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
      throw Exception('Failed to initialize notification for IOS');
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
    }

    Log.i('iOS notification permissions were granted');
    return alertPermissionGranted;
  }, platform: TargetPlatform.iOS);

  /// Initializes local notifications for Linux desktop environments.
  ///
  /// Sets up default parameters used across notifications on Linux systems.
  ///
  /// ### Parameters:
  /// - [defaultActionName]: The default action label shown when a notification is clicked.
  /// - [defaultIcon]: The default icon used for notifications if none is specified.
  /// - [defaultSound]: The default system sound or file to play.
  /// - [defaultSuppressSound]: Whether notification sounds are muted by default.
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
    return _initializeSettings(
      linuxInitializationSettings: initializationSettingsLinux,
    );
  }, platform: TargetPlatform.linux);

  /// Initializes local notifications for Windows.
  ///
  /// This must be called before displaying notifications on Windows to register
  /// the app with the Windows Action Center.
  ///
  /// ### Parameters:
  /// - [appName]: The display name of the application.
  /// - [appUserModelId]: The Application User Model ID for the app.
  /// - [guid]: The unique identifier for the app's notification registration.
  /// - [iconPath]: The file path to the app's notification icon.
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
    return _initializeSettings(
      windowsInitializationSettings: initializationSettingsWindows,
    );
  }, platform: TargetPlatform.windows);

  Future<bool?> _initializeSettings({
    AndroidInitializationSettings? androidInitializationSettings,
    IOSInitializationSettings? iosInitializationSettings,
    LinuxInitializationSettings? linuxInitializationSettings,
    WindowsInitializationSettings? windowsInitializationSettings,
  }) async {
    final initializationSettings = InitializationSettings(
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
    }

    if (!result) {
      _initialized = false;
      Log.e('Could not initialize');
      return result;
    }

    _initialized = true;
    Log.i('Notification Initialized!');
    return result;
  }
}
