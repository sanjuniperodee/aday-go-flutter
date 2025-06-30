import 'package:injectable/injectable.dart';

import './error/error.dart';
import './error/network_error_handler.dart';
import './material_message_controller.dart';
import '../../../utils/network_utils.dart';

/// Стандартная реализация ErrorHandler
@singleton
class StandardErrorHandler extends NetworkErrorHandler {
  final MaterialMessageController? _messageController;

  StandardErrorHandler(
    this._messageController,
  );

  @override
  void handleOtherException(Exception e) {
    if (e is BaseException) {
      _show(e.message);
    } else {
      /// Используем новую систему обработки ошибок
      NetworkUtils.handleNetworkError(e);
    }
  }

  @override
  void handleOther(String e) {
    _show(e);
  }

  void _show(String text) {
    _messageController?.showError(text);
  }

  @override
  void handleNoInternetError(e) {
    NetworkUtils.showNoInternetMessage();
  }

  @override
  void handleConnectionTimeOutException(e) {
    NetworkUtils.showConnectionTimeoutMessage();
  }
}
