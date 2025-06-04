import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/common_strings.dart';
import '../../../di/di_container.dart';
import '../../../interactors/session_interactor.dart';

authInterceptors(Dio dio) {
  int retries = 0;

  Future<RequestOptions> getOptions(RequestOptions options) async {
    RequestOptions _options = options;
    // final authStore = serviceLocator<AuthStore>();
    String? appCheckToken;

    if ((_options.headers['Authorization'] ?? '') == '') {
      final storage = await SharedPreferences.getInstance();
      await getIt<SessionInteractor>().checkAccessTokenExpired();
      final String accessToken = storage.getString(ACCESS_TOKEN) ?? '';
      await storage.reload();

      if (accessToken.isNotEmpty) {
        _options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    if (_options.path.contains('api.aktau-go.kz')) {
      _options.headers['Authorization'] = 'c2F0ZmFybV9tZW51X2FwaTphOTU5MGYyMjNkM2Q4M2ExNDVjNmJiZWQyMGM1NTJjZmQyZTc1OWUwMWI0YmE4NTc0OWE2YmQwZWMxOGY0MmI2';
    }

    if (_options.headers['Content-Type'] == null) {
      _options.headers['Content-Type'] = 'application/json';
    }
    if (_options.headers['Accept'] != null) {
      _options.headers['Accept'] = 'application/json';
    }

    return _options;
  }

  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      return handler.next(await getOptions(options));
    },
    onResponse: (response, handler) async {
      retries = 0;
      return handler.next(response);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401 && retries <= 6) {
        retries += 1;
        try {
          debugPrint('TRY REFRESH TOKEN');
          await getIt<SessionInteractor>().checkAccessTokenExpired();
          final response =
              await retry(dio, await getOptions(error.requestOptions));
          retries = 0;
          return handler.resolve(response);
        } on DioError {
          return handler.next(error);
        }
      } else if (error.response?.statusCode == 401) {
        debugPrint('6 TRIES LOGOUT');
        retries = 0;
        // getIt<SessionInteractor>().removeAll();
        return handler.next(error);
      } else {
        retries = 0;
        return handler.next(error);
      }
    },
  );
}

extension _AsOptions on RequestOptions {
  Options asOptions() {
    return Options(
      method: method,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      extra: extra,
      headers: headers,
      responseType: responseType,
      contentType: contentType,
      validateStatus: validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      requestEncoder: requestEncoder,
      responseDecoder: responseDecoder,
      listFormat: listFormat,
    );
  }
}

Future<Response<dynamic>> retry(
  Dio dio,
  RequestOptions requestOptions,
) async {
  final options = new Options(
    method: requestOptions.method,
    headers: requestOptions.headers,
  );
  return dio.request<dynamic>(
    requestOptions.path,
    data: requestOptions.data,
    queryParameters: requestOptions.queryParameters,
    options: options,
  );
}
