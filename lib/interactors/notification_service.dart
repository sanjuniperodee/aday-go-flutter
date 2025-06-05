import 'dart:async';

import 'package:aktau_go/interactors/notification_interactor.dart';
import 'package:aktau_go/models/notification/notification_model.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

// A service to handle notifications throughout the app
@singleton
class NotificationService {
  final NotificationInteractor _notificationInteractor;
  
  // Stream controller for unread count updates
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCount => _unreadCountController.stream;
  
  // Stream controller for new notifications
  final _newNotificationController = StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get newNotifications => _newNotificationController.stream;
  
  Timer? _refreshTimer;
  
  NotificationService({NotificationInteractor? notificationInteractor}) 
      : _notificationInteractor = notificationInteractor ?? inject<NotificationInteractor>() {
    // Start a periodic refresh
    _startPeriodicRefresh();
  }
  
  // Start a timer to periodically refresh notification count
  void _startPeriodicRefresh() {
    // Cancel any existing timer
    _refreshTimer?.cancel();
    
    // Check immediately
    _refreshUnreadCount();
    
    // Then check every 30 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _refreshUnreadCount();
    });
  }
  
  // Refresh the unread count and broadcast it
  Future<void> _refreshUnreadCount() async {
    try {
      final count = await _notificationInteractor.getUnreadCount();
      _unreadCountController.add(count);
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }
  
  // Get the current unread count
  Future<int> getUnreadCount() async {
    return _notificationInteractor.getUnreadCount();
  }
  
  // Get all notifications
  Future<List<NotificationModel>> getNotifications() async {
    return _notificationInteractor.getNotifications();
  }
  
  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationInteractor.markAsRead(notificationId);
    _refreshUnreadCount();
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _notificationInteractor.markAllAsRead();
    _refreshUnreadCount();
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationInteractor.deleteNotification(notificationId);
    _refreshUnreadCount();
  }
  
  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationInteractor.clearAllNotifications();
    _refreshUnreadCount();
  }
  
  // Handle a new notification from Firebase
  void handleNewNotification(NotificationModel notification) {
    // Broadcast the new notification
    _newNotificationController.add(notification);
    
    // Refresh the unread count
    _refreshUnreadCount();
  }
  
  // Show a notification in-app
  void showInAppNotification(BuildContext context, NotificationModel notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(notification.getIcon(), color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: notification.getColor(),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Показать',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to notification details
            // Navigator.of(context).pushNamed(...);
          },
        ),
      ),
    );
  }
  
  // Add a test notification
  Future<void> addTestNotification() async {
    await _notificationInteractor.addTestNotification();
    _refreshUnreadCount();
  }
  
  // Dispose of resources
  void dispose() {
    _refreshTimer?.cancel();
    _unreadCountController.close();
    _newNotificationController.close();
  }
} 