import 'package:flutter/material.dart';

enum NotificationType {
  rideRequest,
  rideAccepted,
  rideStarted,
  rideCompleted,
  rideCancelled,
  paymentConfirmed,
  systemMessage,
  promotion
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });
  
  // Constructor from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['body'] ?? '',
      type: _parseNotificationType(json['type']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['sentTime'] ?? DateTime.now().millisecondsSinceEpoch),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': message,
      'type': type.toString().split('.').last,
      'sentTime': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'data': data,
    };
  }
  
  // Create a copy of this notification with some field changes
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
  
  // Parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.systemMessage;
    
    switch (typeString) {
      case 'rideRequest': return NotificationType.rideRequest;
      case 'rideAccepted': return NotificationType.rideAccepted;
      case 'rideStarted': return NotificationType.rideStarted;
      case 'rideCompleted': return NotificationType.rideCompleted;
      case 'rideCancelled': return NotificationType.rideCancelled;
      case 'paymentConfirmed': return NotificationType.paymentConfirmed;
      case 'promotion': return NotificationType.promotion;
      default: return NotificationType.systemMessage;
    }
  }
  
  // Get icon for notification type
  IconData getIcon() {
    switch (type) {
      case NotificationType.rideRequest: return Icons.directions_car;
      case NotificationType.rideAccepted: return Icons.check_circle;
      case NotificationType.rideStarted: return Icons.directions;
      case NotificationType.rideCompleted: return Icons.flag;
      case NotificationType.rideCancelled: return Icons.cancel;
      case NotificationType.paymentConfirmed: return Icons.payment;
      case NotificationType.promotion: return Icons.local_offer;
      case NotificationType.systemMessage: return Icons.notifications;
    }
  }
  
  // Get color for notification type
  Color getColor() {
    switch (type) {
      case NotificationType.rideRequest: return Colors.blue;
      case NotificationType.rideAccepted: return Colors.green;
      case NotificationType.rideStarted: return Colors.amber;
      case NotificationType.rideCompleted: return Colors.purple;
      case NotificationType.rideCancelled: return Colors.red;
      case NotificationType.paymentConfirmed: return Colors.green;
      case NotificationType.promotion: return Colors.orange;
      case NotificationType.systemMessage: return Colors.grey;
    }
  }
} 