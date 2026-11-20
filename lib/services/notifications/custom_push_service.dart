import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CustomPushService {
  static const topic = 'placement_v2_alerts';
  static const _notifications = MethodChannel('placement_v2/notifications');

  static Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional) {
      await messaging.subscribeToTopic(topic);
    }
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;
      try {
        await _notifications.invokeMethod('show', {
          'title': notification.title,
          'body': notification.body,
        });
      } on PlatformException catch (error) {
        debugPrint('Unable to show push notification: ${error.code}');
      }
    });
  }
}
