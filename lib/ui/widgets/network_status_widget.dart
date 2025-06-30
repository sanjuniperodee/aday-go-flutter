import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/colors.dart';
import '../../utils/network_utils.dart';

class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final bool showBanner;

  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool _isConnected = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _listenToConnectivityChanges();
  }

  void _checkInitialConnection() async {
    setState(() => _isChecking = true);
    final hasConnection = await NetworkUtils.hasInternetConnection();
    if (mounted) {
      setState(() {
        _isConnected = hasConnection;
        _isChecking = false;
      });
    }
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        if (mounted) {
          setState(() => _isConnected = false);
        }
      } else {
        // Дополнительная проверка реального подключения к интернету
        _checkRealConnection();
      }
    });
  }

  void _checkRealConnection() async {
    final hasConnection = await NetworkUtils.hasInternetConnection();
    if (mounted) {
      setState(() => _isConnected = hasConnection);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showBanner) {
      return widget.child;
    }

    return Column(
      children: [
        if (!_isConnected && !_isChecking)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red[700],
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Нет подключения к интернету',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _checkRealConnection,
                  child: Text(
                    'Повторить',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_isChecking)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange[700],
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Проверка подключения...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Статический метод для показа диалога с проверкой интернета
class NetworkStatusDialog {
  static Future<bool> showNoInternetDialog(BuildContext context) async {
    if (!context.mounted) return false;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Нет интернета'),
          ],
        ),
        content: Text(
          'Для работы приложения необходимо подключение к интернету. Проверьте соединение и попробуйте снова.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final hasConnection = await NetworkUtils.hasInternetConnection();
              if (hasConnection) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Интернет соединение по-прежнему недоступно'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Проверить снова'),
          ),
        ],
      ),
    ) ?? false;
  }
}

/// Миксин для автоматической проверки интернета в виджетах
mixin NetworkAwareMixin<T extends StatefulWidget> on State<T> {
  bool _hasInternet = true;

  bool get hasInternet => _hasInternet;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _listenToConnectivity();
  }

  void _checkConnection() async {
    final hasConnection = await NetworkUtils.hasInternetConnection();
    if (mounted) {
      setState(() => _hasInternet = hasConnection);
      if (!hasConnection) {
        onNoInternet();
      }
    }
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        if (mounted) {
          setState(() => _hasInternet = false);
          onNoInternet();
        }
      } else {
        _checkConnection();
      }
    });
  }

  /// Переопределите этот метод для обработки отсутствия интернета
  void onNoInternet() {
    NetworkUtils.showNoInternetMessage();
  }

  /// Выполняет действие только при наличии интернета
  Future<T?> executeWithInternet<T>(Future<T> Function() action) async {
    if (!_hasInternet) {
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        NetworkUtils.showNoInternetMessage();
        return null;
      }
      setState(() => _hasInternet = true);
    }
    
    try {
      return await action();
    } catch (e) {
      NetworkUtils.handleNetworkError(e);
      return null;
    }
  }
} 