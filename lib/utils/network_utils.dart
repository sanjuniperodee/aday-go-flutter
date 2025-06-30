import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modules/dio/base/material_message_controller.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  
  /// Проверяет наличие интернет соединения
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Дополнительная проверка реального подключения к интернету
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Показывает сообщение об отсутствии интернета
  static void showNoInternetMessage() {
    final messageController = MaterialMessageController();
    messageController.showError('Нет подключения к интернету. Проверьте соединение и попробуйте снова.');
  }
  
  /// Показывает сообщение о таймауте соединения
  static void showConnectionTimeoutMessage() {
    final messageController = MaterialMessageController();
    messageController.showError('Превышено время ожидания. Проверьте соединение и попробуйте снова.');
  }
  
  /// Показывает сообщение о серверной ошибке
  static void showServerErrorMessage() {
    final messageController = MaterialMessageController();
    messageController.showError('Ошибка сервера. Попробуйте позже.');
  }
  
  /// Показывает сообщение о блокировке пользователя
  static void showUserBlockedMessage(String reason, DateTime? blockedUntil) {
    final messageController = MaterialMessageController();
    String message = 'Ваш аккаунт заблокирован.';
    if (reason.isNotEmpty) {
      message += '\nПричина: $reason';
    }
    if (blockedUntil != null) {
      final formatter = DateFormat('dd.MM.yyyy HH:mm');
      message += '\nРазблокировка до: ${formatter.format(blockedUntil)}';
    }
    messageController.showError(message);
  }
  
  /// Универсальная обработка сетевых ошибок
  static void handleNetworkError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          showConnectionTimeoutMessage();
          break;
        case DioExceptionType.connectionError:
          if (error.error is SocketException) {
            showNoInternetMessage();
          } else {
            showServerErrorMessage();
          }
          break;
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 500) {
            showServerErrorMessage();
          } else if (error.response?.statusCode == 403 &&
                     error.response?.data != null &&
                     error.response?.data['message'] == 'Ваш аккаунт заблокирован. Создание заказов недоступно.') {
            // Handle UserBlockedException
            final String reason = error.response?.data['reason'] ?? 'Причина не указана';
            final String? blockedUntilStr = error.response?.data['blockedUntil'];
            DateTime? blockedUntil;
            if (blockedUntilStr != null) {
              try {
                blockedUntil = DateTime.parse(blockedUntilStr);
              } catch (e) {
                print('Error parsing blockedUntil date: $e');
              }
            }
            showUserBlockedMessage(reason, blockedUntil);
          } else {
            final messageController = MaterialMessageController();
            messageController.showError('Ошибка: ${error.response?.statusCode ?? 'Неизвестная ошибка'}');
          }
          break;
        default:
          showServerErrorMessage();
      }
    } else if (error is SocketException) {
      showNoInternetMessage();
    } else {
      showServerErrorMessage();
    }
  }
  
  /// Выполняет сетевой запрос с автоматической обработкой ошибок
  static Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() networkCall, {
    bool showErrorMessages = true,
    String? customErrorMessage,
  }) async {
    try {
      // Проверяем интернет соединение перед запросом
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        if (showErrorMessages) {
          showNoInternetMessage();
        }
        return null;
      }
      
      return await networkCall();
    } catch (error) {
      if (showErrorMessages) {
        if (customErrorMessage != null) {
          final messageController = MaterialMessageController();
          messageController.showError(customErrorMessage);
        } else {
          handleNetworkError(error);
        }
      }
      return null;
    }
  }
  
  /// Показывает диалог с предложением повторить запрос
  static Future<bool> showRetryDialog(BuildContext context, {
    String? title,
    String? message,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Ошибка подключения'),
        content: Text(message ?? 'Не удалось подключиться к серверу. Попробовать снова?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Повторить'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Создает SnackBar с кнопкой повтора
  static SnackBar createRetrySnackBar({
    required String message,
    required VoidCallback onRetry,
  }) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Повторить',
        textColor: Colors.white,
        onPressed: onRetry,
      ),
    );
  }
} 