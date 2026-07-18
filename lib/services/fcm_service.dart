import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

/// Service managing Firebase Cloud Messaging (FCM) and Local Notifications.
/// Handles token generation, foreground notification popups, custom sound, and routing on click.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Global key to trigger tab navigation on click
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize FCM and request permissions
  Future<void> init() async {
    // 1. Request Notification Permissions (Android 13+ & iOS)
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationClick(response.payload);
        },
      );
    }

    // 3. Configure FCM background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kIsWeb) {
        // Natively log / alert or handle in web
        print('Foreground Web Message: ${message.notification?.title}');
      } else {
        _showLocalNotification(message);
      }
    });

    // 5. Handle notification click when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(jsonEncode(message.data));
    });

    // 6. Handle notification click when app was completely terminated
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(jsonEncode(message.data));
      }
    });
  }

  Future<void> updateToken(String userId) async {
    try {
      String? vapidKey;
      if (kIsWeb) {
        final configDoc = await _firestore.collection('config').doc('fcm').get();
        if (configDoc.exists) {
          vapidKey = configDoc.data()?['vapidKey'] as String?;
        }
      }

      final token = await _fcm.getToken(vapidKey: vapidKey);
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }

      // Automatically listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('FCM Token Update Error: $e');
    }
  }

  /// Show a beautiful foreground notification with custom sound
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'طلب جديد';
    final body = message.notification?.body ?? 'وصلك طلب جديد';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'com.example.fantex.orders.v3', // Channel ID
      'طلبيات tussi', // Channel Name
      channelDescription: 'قناة إشعارات الطلبيات الواردة',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'notification_sound.wav',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  /// Routing on notification click
  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload);
      if (data['type'] == 'order' && navigatorKey != null) {
        // Find home state if exists and switch tab to Orders (index 0)
        // Since home screen uses bottom navigation, we can push navigation pop or redirect
        navigatorKey!.currentState?.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('FCM Routing click error: $e');
    }
  }

  Future<void> sendNotification({
    required String receiverToken,
    required String senderName,
    required String orderId,
  }) async {
    if (receiverToken.isEmpty) return;

    try {
      // 1. Fetch FCM Service Account JSON from Firestore Config
      final configDoc = await _firestore.collection('config').doc('fcm').get();
      if (!configDoc.exists) {
        print('FCM config document is missing in Firestore config/fcm');
        return;
      }

      final serviceAccountJson = configDoc.data()?['serviceAccountJson'] as String?;
      if (serviceAccountJson == null || serviceAccountJson.isEmpty) {
        print('FCM serviceAccountJson string is empty in Firestore config/fcm');
        return;
      }

      // 2. Generate Google OAuth 2.0 Access Token from Service Account credentials
      final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      final projectId = credentials.projectId;
      client.close(); // Close the auth client, we will use our own http request

      // 3. Prepare FCM V1 HTTP API payload
      final body = {
        'message': {
          'token': receiverToken,
          'notification': {
            'title': 'طلبية جديدة 📥',
            'body': 'وصلتك طلبية جديدة من: $senderName',
          },
          'data': {
            'type': 'order',
            'orderId': orderId,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'notification_sound',
              'channel_id': 'com.example.fantex.orders.v3',
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'notification_sound.wav',
                'content-available': 1,
              }
            }
          }
        }
      };

      // 4. Post to FCM V1 API
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      print('FCM V1 Notification sent response: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('FCM V1 Error response body: ${response.body}');
      }
    } catch (e) {
      print('FCM V1 sending notification error: $e');
    }
  }
}

/// FCM Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Let Firebase initialize natively first
  print("FCM Background Message Received: ${message.messageId}");
}
