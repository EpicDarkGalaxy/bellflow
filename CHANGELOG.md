## 0.1.0

- Initial release of the reusable local notification service.

## 1.0.0

- **Breaking:** `initAndroid` and `initIOS` now return named records with `initResult` and `notificationGranted` fields.
- Fixed an issue with repeated calls to the platform initialization methods.