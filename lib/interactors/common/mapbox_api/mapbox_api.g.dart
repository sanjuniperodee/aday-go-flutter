// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapbox_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations

class _MapboxApi implements MapboxApi {
  _MapboxApi(
    this._dio, {
    this.baseUrl,
    this.errorLogger,
  }) {
    baseUrl ??= 'https://api.mapbox.com/';
  }

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<MapboxGeoCodingResponse> getPlaces({
    required String query,
    String language = 'ru',
    required String sessionToken,
    String country = 'kz',
    String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'q': query,
      r'language': language,
      r'session_token': sessionToken,
      r'country': country,
      r'access_token': accessToken,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<MapboxGeoCodingResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          'https://api.mapbox.com/search/searchbox/v1/suggest',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late MapboxGeoCodingResponse _value;
    try {
      _value = MapboxGeoCodingResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  @override
  Future<MapboxFeatureDetailResponse> getPlaceDetail({
    required String mapboxId,
    required String sessionToken,
    String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'session_token': sessionToken,
      r'access_token': accessToken,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<MapboxFeatureDetailResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          'https://api.mapbox.com/search/searchbox/v1/retrieve/${mapboxId}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late MapboxFeatureDetailResponse _value;
    try {
      _value = MapboxFeatureDetailResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  @override
  Future<dynamic> getDirections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String geometries = 'geojson',
    String overview = 'full',
    bool steps = true,
    String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'geometries': geometries,
      r'overview': overview,
      r'steps': steps,
      r'access_token': accessToken,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<dynamic>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${fromLng},${fromLat};${toLng},${toLat}',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch(_options);
    final _value = _result.data;
    return _value;
  }

  @override
  Future<MapboxFeatureDetailResponse> geoCoding({
    required double longitude,
    required double latitude,
    String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'access_token': accessToken};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<MapboxFeatureDetailResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          'geocoding/v5/mapbox.places/${longitude},${latitude}.json',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late MapboxFeatureDetailResponse _value;
    try {
      _value = MapboxFeatureDetailResponse.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(
    String dioBaseUrl,
    String? baseUrl,
  ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
