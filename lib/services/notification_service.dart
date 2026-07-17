import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  /// Request system permissions required to push heads-up alerts on Android 13+
  static Future<void> initNotificationPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}
