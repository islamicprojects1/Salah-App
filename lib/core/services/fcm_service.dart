import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:salah/core/services/notification_service.dart';

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // The system will automatically show the notification if the payload contains a 'notification' object.
}

class FcmService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // NOTE: In a real production app, the Server Key should NEVER be stored in the app.
  // However, for this specific family-only project without cloud functions/credit card,
  // this is the only way to achieve real-time background notifications.
  static const String _legacyServerKey = 'YOUR_LEGACY_SERVER_KEY_HERE';

  Future<FcmService> init() async {
    await _requestPermissions();
    _setupForegroundHandler();
    _setupInteractionHandler();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    return this;
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().showNotification(
          id: message.hashCode,
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
          channelId: 'family_channel',
        );
      }
    });
  }

  void _setupInteractionHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((_) => Get.toNamed('/notifications'));
  }

  /// Subscribe to a specific family topic
  Future<void> subscribeToFamily(String familyId) async {
    final topic = 'family_$familyId';
    await _fcm.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a specific family topic
  Future<void> unsubscribeFromFamily(String familyId) async {
    final topic = 'family_$familyId';
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Sends a notification directly to a family topic.
  /// This bypasses the need for a server/Cloud Functions.
  Future<void> sendNotificationToFamily({
    required String familyId,
    required String title,
    required String body,
  }) async {
    if (_legacyServerKey == 'YOUR_LEGACY_SERVER_KEY_HERE') {
      debugPrint('WARNING: FCM Server Key not set. Notification not sent.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_legacyServerKey',
        },
        body: jsonEncode({
          'to': '/topics/family_$familyId',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'family_activity',
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Direct FCM notification sent successfully');
      } else {
        debugPrint('Failed to send direct FCM: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending direct FCM: $e');
    }
  }

  Future<String?> getToken() => _fcm.getToken();
}
