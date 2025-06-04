import 'package:dio/dio.dart';

import '../../../../core/common_strings.dart';

class DioException extends DioError {
  DioException({
    required RequestOptions requestOptions,
    Response? response,
    DioErrorType type = DioErrorType.unknown,
    dynamic error,
  }) : super(
          requestOptions: requestOptions,
          response: response,
          type: type,
          error: error,
        );
}

abstract class BaseException extends DioException {
  final String _message;

  /// TODO пеализовать сообщение ошибки
  @override
  String get message => '';

  BaseException(
    Response? response, [
    this._message = emptyString,
  ]) : super(
          requestOptions: RequestOptions(
            path: emptyString,
          ),
          response: response,
        );
}


/// 401 - Пользователь не авторизован
class UserNotAuthorizedException extends BaseException {
  UserNotAuthorizedException(Response? response) : super(response);
}

/// 404 - неверный endpoint
class NotFoundException extends BaseException {
  NotFoundException(Response? response) : super(response);
}

/// 500 - Критическая ошибка на стороне сервера
class ServerException extends BaseException {
  ServerException(Response? response) : super(response);
}

/// Ошибка, у которой нет специфической обработки
class OtherException extends BaseException {
  OtherException(Response? response) : super(response);
}

/// Ошибка: пустое исключение
class EmptyException extends BaseException {
  EmptyException() : super(null);
}

class MessageException extends BaseException {
  @override
  String get message => _message;

  MessageException(String message)
      : super(
          null,
          message,
        );
}

/// Интернет недоступен
class NoInternetException extends BaseException {
  NoInternetException(Response? response) : super(response);
}

/// Ошибка таймаута соединения
class ConnectionTimeOutException extends BaseException {
  ConnectionTimeOutException(Response? response) : super(response);
}
