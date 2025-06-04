import 'dart:convert';

import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/common_strings.dart';
import '../utils/logger.dart';

abstract class INotificationInteractor {
  // Setup Firebase Cloud Messaging
  Future<void> setupFirebaseConfig();

  // Notifications from terminated state
  Future<void> setupInteractedMessage();
}

@singleton
class NotificationInteractor extends INotificationInteractor {
  /// Local notification Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    // description
    importance: Importance.max,
  );

  NotificationInteractor();

  @override
  Future<void> setupInteractedMessage() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleNotificationMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationMessage);
  }

  @override
  Future<void> setupFirebaseConfig() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.requestPermission(
      provisional: true,
    );
    FirebaseMessaging.instance.getToken().then((value) {
      inject<RestClient>().saveFirebaseDeviceToken(
        deviceToken: value ?? '',
      );
    });

    /// Initialize local Notifications
    _initializeLocalNotification();

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              color: Colors.white,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
      if (message.notification != null) {
        saveNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      _handleNotificationMessage(message);
    });
  }

  /// Initialize Local Notification
  void _initializeLocalNotification() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (notificationMessage) async {
        _handleNotificationMessage(jsonDecode(notificationMessage.payload!));
      },
      onDidReceiveBackgroundNotificationResponse:
          localMessagingBackgroundHandler,
    );
  }

  Future<void> _handleNotificationMessage(RemoteMessage message) async {
    /// TODO notification handler
    logger.w(message.data);

    // if (message.data.containsKey('id') &&
    //     ((message.data['id'] as String?) ?? '').isNotEmpty) {
    //   switch (message.data['type']) {
    //     case 'chat':
    //       String chatId = message.data['id'];
    //       ChatDomain chat =
    //           await inject<ChatInteractor>().getChatById(chatId: chatId);
    //       Routes.router.navigate(
    //         Routes.chatScreen,
    //         args: ChatScreenArgs(chat: chat),
    //       );
    //       break;
    //   }
    // }
  }

  Future<void> saveNotification(RemoteMessage notification) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> _prevLocalNotifications =
        preferences.getStringList(LOCAL_NOTIFICATIONS) ?? [];
    _prevLocalNotifications.add(jsonEncode({
      ...notification.toMap(),
      'sentTime': DateTime.now().millisecondsSinceEpoch,
    }));
    preferences.setStringList(LOCAL_NOTIFICATIONS, _prevLocalNotifications);
  }

  void debug() {
    flutterLocalNotificationsPlugin.show(
      1,
      'qweqwe',
      'qweqwe',
      NotificationDetails(),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  if (message.notification == null) {
    return;
  }
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  List<String> _prevLocalNotifications =
      preferences.getStringList('local_notifications') ?? [];
  _prevLocalNotifications.add(jsonEncode({
    ...message.toMap(),
    'sentTime': DateTime.now().millisecondsSinceEpoch,
  }));
  preferences.setStringList('local_notifications', _prevLocalNotifications);
}

@pragma('vm:entry-point')
void localMessagingBackgroundHandler(NotificationResponse details) {
  logger.w(details);
}
