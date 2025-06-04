import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import './message_controller/message_controller.dart';

///Стандартная реализация [MessageController]
@injectable
class MaterialMessageController implements MessageController {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void show(SnackBar snackBar) {
    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  @override
  void showError(String text) {
    if (text.isEmpty) {
      return;
    }
    final pattern = RegExp(r'[А-я]+');
    if (!pattern.hasMatch(text)) {
      if (text == "Too Many Attempts") {
        text = 'Ошибка получения гостевой сессии. Пожалуйста, попробуйте позже';
      } else {
        text = 'Ошибка. Попробуйте позже';
      }
    }
    SnackBar snackBar = SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(text),
      backgroundColor: Colors.redAccent,
    );
    show(snackBar);
  }

  @override
  void showInfo(String text) {
    // show(SnackBarBuilder.buildInfo(text));
  }

  @override
  void showSuccessful(String text) {
    if (text.isEmpty) {
      return;
    }
    SnackBar snackBar = SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(
        text,
      ),
      backgroundColor: Colors.green,
    );
    show(snackBar);
  }

  @override
  void showTopNotification(String text) {
    SnackBar snackBar = SnackBar(
      duration: const Duration(seconds: 2),
      content: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            text,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      // dismissDirection: DismissDirection.up,
      behavior: SnackBarBehavior.floating,
      // margin: EdgeInsets.only(
      //   bottom: 1.sh - 150,
      //   left: 16.w,
      //   right: 16.w,
      // ),
    );
    show(snackBar);
  }

  @override
  void showConfirmationInfo(String text) {
    // show(SnackBarBuilder.buildConfirmationInfo(text));
  }

  @override
  void showConfirmationSuccessful(String text) {
    // show(SnackBarBuilder.buildConfirmationSuccessful(text));
  }
}
