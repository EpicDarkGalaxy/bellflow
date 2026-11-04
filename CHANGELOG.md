## 1.1.0

- Added optional `loggerInfo`, `loggerWarning`, and `loggerError` callbacks to `NotificationService.init(...)` for custom log handling.
- Improved initialization flow by allowing application-defined logging without changing the existing initialization behavior.
- Bellflow now contributes the scheduled notification receivers to the Android manifest via manifest merging, enabling Android scheduled notification setup with `ENABLE_SCHEDULED_NOTIFICATIONS` support.
- Improved notification tap handling by passing the full NotificationResponse to onNotificationTap, including payload, id, actionId, and other response metadata for richer app navigation and action handling.

## 1.0.0

- **Breaking:** `initAndroid` and `initIOS` now return named records with `initResult` and `notificationGranted` fields.
- Fixed an issue with repeated calls to the platform initialization methods.

## 0.1.0

- Initial release of the reusable local notification service.
