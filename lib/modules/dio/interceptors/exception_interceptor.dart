import 'dart:io';

import 'package:dio/dio.dart';

import '../base/error/error.dart';
import '../status_mapper.dart';

const _timeoutErrorTypes = [
  DioErrorType.connectionTimeout,
  DioErrorType.receiveTimeout,
  DioErrorType.sendTimeout,
];

/// Интерцептор для обработки ошибки старой версии приложения
class ExceptionInterceptor extends Interceptor {
  final _statusMapper = StatusMapper();

  @override
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) {
    if (_timeoutErrorTypes.contains(err.type)) {
      handler.next(ConnectionTimeOutException(err.response));
    } else if (err.type == DioErrorType.unknown &&
        err.error is SocketException) {
      handler.next(NoInternetException(err.response));
    } else {
      _handleCustomServerError(err, handler);
    }
  }

  void _handleCustomServerError(DioError e, ErrorInterceptorHandler handler) {
    final exception = _statusMapper.getException(e.response);

    handler.next(exception);
  }
}
