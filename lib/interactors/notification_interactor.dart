import 'dart:convert';

import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/models/notification/notification_model.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/common_strings.dart';
import '../utils/logger.dart';

abstract class INotificationInteractor {
  // Setup Firebase Cloud Messaging
  Future<void> setupFirebaseConfig();

  // Notifications from terminated state
  Future<void> setupInteractedMessage();
  
  // Get all notifications
  Future<List<NotificationModel>> getNotifications();
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId);
  
  // Mark all notifications as read
  Future<void> markAllAsRead();
  
  // Delete notification
  Future<void> deleteNotification(String notificationId);
  
  // Clear all notifications
  Future<void> clearAllNotifications();
  
  // Get unread notifications count
  Future<int> getUnreadCount();
  
  // Add test notification (for development purposes)
  Future<void> addTestNotification();
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
    List<String> prevLocalNotifications =
        preferences.getStringList(LOCAL_NOTIFICATIONS) ?? [];
        
    // Create a unique ID for the notification
    final notificationId = const Uuid().v4();
    
    // Extract notification type from data if available
    String? notificationType;
    if (notification.data.containsKey('type')) {
      notificationType = notification.data['type'];
    }
    
    // Create a map with all the notification data
    final notificationData = {
      ...notification.toMap(),
      'id': notificationId,
      'sentTime': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
      'type': notificationType ?? 'systemMessage',
    };
    
    prevLocalNotifications.add(jsonEncode(notificationData));
    preferences.setStringList(LOCAL_NOTIFICATIONS, prevLocalNotifications);
  }
  
  @override
  Future<List<NotificationModel>> getNotifications() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> notificationStrings = preferences.getStringList(LOCAL_NOTIFICATIONS) ?? [];
    
    List<NotificationModel> notifications = [];
    
    for (String notificationString in notificationStrings) {
      try {
        final Map<String, dynamic> notificationMap = jsonDecode(notificationString);
        
        // Extract notification data from the RemoteMessage format
        Map<String, dynamic> notificationData = {};
        
        if (notificationMap.containsKey('notification')) {
          final notification = notificationMap['notification'];
          if (notification != null && notification is Map) {
            notificationData['title'] = notification['title'];
            notificationData['body'] = notification['body'];
          }
        }
        
        // Add other required fields
        notificationData['id'] = notificationMap['id'] ?? const Uuid().v4();
        notificationData['sentTime'] = notificationMap['sentTime'] ?? DateTime.now().millisecondsSinceEpoch;
        notificationData['isRead'] = notificationMap['isRead'] ?? false;
        notificationData['type'] = notificationMap['type'] ?? 'systemMessage';
        notificationData['data'] = notificationMap['data'];
        
        notifications.add(NotificationModel.fromJson(notificationData));
      } catch (e) {
        logger.e('Error parsing notification: $e');
      }
    }
    
    // Sort by timestamp (newest first)
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return notifications;
  }
  
  @override
  Future<void> markAsRead(String notificationId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> notificationStrings = preferences.getStringList(LOCAL_NOTIFICATIONS) ?? [];
    
    List<String> updatedNotifications = [];
    
    for (String notificationString in notificationStrings) {
      try {
        Map<String, dynamic> notificationMap = jsonDecode(notificationString);
        
        if (notificationMap['id'] == notificationId) {
          notificationMap['isRead'] = true;
        }
        
        updatedNotifications.add(jsonEncode(notificationMap));
      } catch (e) {
        // Keep original if parsing fails
        updatedNotifications.add(notificationString);
        logger.e('Error updating notification: $e');
      }
    }
    
    await preferences.setStringList(LOCAL_NOTIFICATIONS, updatedNotifications);
  }
  
  @override
  Future<void> markAllAsRead() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> notificationStrings = preferences.getStringList(LOCAL_NOTIFICATIONS) ?? [];
    
    List<String> updatedNotifications = [];
    
    for (String notificationString in notificationStrings) {
      try {
        Map<String, dynamic> notificationMap = jsonDecode(notificationString);
        notificationMap['isRead'] = true;
        updatedNotifications.add(jsonEncode(notificationMap));
      } catch (e) {
        // Keep original if parsing fails
        updatedNotifications.add(notificationString);
        logger.e('Error updating notification: $e');
      }
    }
    
    await preferences.setStringList(LOCAL_NOTIFICATIONS, updatedNotifications);
  }
  
  @override
  Future<void> deleteNotification(String notificationId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> notificationStrings = preferences.getStringList(LOCAL_NOTIFICATIONS) ?? [];
    
    List<String> remainingNotifications = [];
    
    for (String notificationString in notificationStrings) {
      try {
        Map<String, dynamic> notificationMap = jsonDecode(notificationString);
        
        if (notificationMap['id'] != notificationId) {
          remainingNotifications.add(notificationString);
        }
      } catch (e) {
        // Keep original if parsing fails
        remainingNotifications.add(notificationString);
        logger.e('Error deleting notification: $e');
      }
    }
    
    await preferences.setStringList(LOCAL_NOTIFICATIONS, remainingNotifications);
  }
  
  @override
  Future<void> clearAllNotifications() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(LOCAL_NOTIFICATIONS, []);
  }
  
  @override
  Future<int> getUnreadCount() async {
    List<NotificationModel> notifications = await getNotifications();
    return notifications.where((notification) => !notification.isRead).length;
  }
  
  @override
  Future<void> addTestNotification() async {
    // Create test notification types
    final testNotificationTypes = [
      NotificationType.rideRequest,
      NotificationType.rideAccepted,
      NotificationType.rideStarted,
      NotificationType.rideCompleted,
      NotificationType.rideCancelled,
      NotificationType.paymentConfirmed,
      NotificationType.promotion,
      NotificationType.systemMessage,
    ];
    
    // Select random notification type
    final notificationType = testNotificationTypes[DateTime.now().second % testNotificationTypes.length];
    
    // Create notification content based on type
    String title = 'Test Notification';
    String body = 'This is a test notification';
    
    switch (notificationType) {
      case NotificationType.rideRequest:
        title = 'Новый запрос на поездку';
        body = 'Клиент запросил поездку в ваш район';
        break;
      case NotificationType.rideAccepted:
        title = 'Поездка подтверждена';
        body = 'Водитель принял ваш заказ и направляется к вам';
        break;
      case NotificationType.rideStarted:
        title = 'Поездка началась';
        body = 'Ваша поездка началась. Приятного пути!';
        break;
      case NotificationType.rideCompleted:
        title = 'Поездка завершена';
        body = 'Ваша поездка успешно завершена. Спасибо что воспользовались нашим сервисом!';
        break;
      case NotificationType.rideCancelled:
        title = 'Поездка отменена';
        body = 'К сожалению, ваша поездка была отменена';
        break;
      case NotificationType.paymentConfirmed:
        title = 'Оплата подтверждена';
        body = 'Ваш платеж успешно обработан';
        break;
      case NotificationType.promotion:
        title = 'Специальное предложение';
        body = 'Воспользуйтесь скидкой 20% на следующую поездку!';
        break;
      case NotificationType.systemMessage:
        title = 'Системное уведомление';
        body = 'Приложение обновлено до последней версии';
        break;
    }
    
    // Create notification model
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      message: body,
      type: notificationType,
      timestamp: DateTime.now(),
      isRead: false,
    );
    
    // Save to SharedPreferences
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> notificationStrings = preferences.getStringList(LOCAL_NOTIFICATIONS) ?? [];
    notificationStrings.add(jsonEncode(notification.toJson()));
    await preferences.setStringList(LOCAL_NOTIFICATIONS, notificationStrings);
    
    // Also show as actual notification
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.message,
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
  
  // Create a unique ID for the notification
  final notificationId = const Uuid().v4();
  
  // Extract notification type from data if available
  String? notificationType;
  if (message.data.containsKey('type')) {
    notificationType = message.data['type'];
  }
  
  // Create a map with all the notification data
  final notificationData = {
    ...message.toMap(),
    'id': notificationId,
    'sentTime': DateTime.now().millisecondsSinceEpoch,
    'isRead': false,
    'type': notificationType ?? 'systemMessage',
  };
  
  _prevLocalNotifications.add(jsonEncode(notificationData));
  preferences.setStringList('local_notifications', _prevLocalNotifications);
}

@pragma('vm:entry-point')
void localMessagingBackgroundHandler(NotificationResponse details) {
  logger.w(details);
}
