import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
    'duoshield_messages',
    'Messages',
    importance: Importance.high,
    playSound: true,
  );

  static Future<void> init() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_messageChannel);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _uploadToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_uploadToken);
  }

  static Future<void> _uploadToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    if (type == 'message' || type == 'group_message') {
      _showLocalNotification(
        title: data['senderName'] ?? 'DuoShield',
        body: data['preview'] ?? 'New message',
        payload: '${data['chatId'] ?? ''}|${data['senderUid'] ?? ''}',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {}

  static void _onNotificationTap(NotificationResponse response) {}

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _messageChannel.id,
          _messageChannel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}
