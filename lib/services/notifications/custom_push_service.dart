import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CustomPushService {
  static const topics = {
    'placement_v2_alerts': 'Result updates',
    'placement_v2_deadlines': 'Deadline changes',
  };

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<Box<bool>> _box() => Hive.openBox<bool>('push_preferences');
  static Future<bool> enabled(String topic) async =>
      (await _box()).get(topic) ?? true;
  static Future<void> _save(String topic, bool value) async =>
      (await _box()).put(topic, value);

  static Future<void> setEnabled(String topic, bool value) async {
    await _save(topic, value);
    await _sync(topic, value);
  }

  static Future<void> _sync(String topic, bool value) async {
    if (!supported) return;
    final messaging = FirebaseMessaging.instance;
    if (!value) {
      await messaging.unsubscribeFromTopic(topic);
      return;
    }
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional) {
      await messaging.subscribeToTopic(topic);
    }
  }

  static Future<void> initialize() async {
    if (!supported) return;
    await Firebase.initializeApp();
    const notifications = MethodChannel('placement_v2/notifications');
    FirebaseMessaging.onMessage.listen((message) async {
      final topic = message.data['type'] == 'placement_deadline_change'
          ? 'placement_v2_deadlines'
          : 'placement_v2_alerts';
      try {
        final notification = message.notification;
        if (notification == null || !await enabled(topic)) return;
        await notifications.invokeMethod('show', {
          'title': notification.title,
          'body': notification.body,
        });
      } catch (error) {
        debugPrint('Unable to show Placement push: $error');
      }
    });
    for (final topic in topics.keys) {
      try {
        await _sync(topic, await enabled(topic));
      } catch (error) {
        debugPrint('Unable to sync notification preference for $topic: $error');
      }
    }
  }
}
