import 'package:dio/dio.dart';

import 'base/error/error.dart';

///Стандартный для проекта обработчик статус кода
class StatusMapper {
  BaseException getException(Response? response) {
    switch (response?.statusCode) {
      case 401:
        return UserNotAuthorizedException(response);

      case 404:
        return NotFoundException(response);

      case 500:
        return ServerException(response);
    }

    return OtherException(response);
  }
}
