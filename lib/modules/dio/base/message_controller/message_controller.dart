import 'package:flutter/material.dart';

abstract class MessageController {
  void show(SnackBar snackBar);

  void showError(String text);

  void showInfo(String text);

  void showSuccessful(String text);

  void showConfirmationInfo(String text);

  void showConfirmationSuccessful(String text);

  void showTopNotification(String text);
}
