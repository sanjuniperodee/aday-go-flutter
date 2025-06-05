import 'dart:async';

import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/interactors/notification_interactor.dart';
import 'package:aktau_go/interactors/notification_service.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:flutter/material.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final double size;
  final Color color;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.size = 18,
    this.color = Colors.red,
    this.showZero = false,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  bool _isLoading = true;
  final NotificationService _notificationService = inject<NotificationService>();
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    
    // Subscribe to notification count updates
    _subscription = _notificationService.unreadCount.listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (!_isLoading && (_unreadCount > 0 || widget.showZero))
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: widget.size,
                minHeight: widget.size,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 