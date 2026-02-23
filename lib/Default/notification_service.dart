import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    _notificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification!.title!, message.notification!.body!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked: ${message.data}");
    });
  }

  static Future<void> sendMulticastNotification(List<String> fcmTokens, Map<String, dynamic> taskData) async {
    const String firebaseServerKey = 'YOUR_SERVER_KEY_HERE';

    final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final Map<String, dynamic> notificationData = {
      'registration_ids': fcmTokens,
      'notification': {
        'title': "New Task Assigned",
        'body': "New task for ${taskData['department']}: ${taskData['taskDescription']}",
      },
      'data': {
        'taskId': taskData['taskId'],
        'department': taskData['department'],
      },
    };

    final response = await http.post(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'key=$firebaseServerKey',
    }, body: jsonEncode(notificationData));

    if (response.statusCode != 200) {
      print("❌ Failed to send notifications: ${response.body}");
    }
  }

  static void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, notificationDetails);
  }
}
