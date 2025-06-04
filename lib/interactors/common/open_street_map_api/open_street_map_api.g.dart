// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_street_map_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _OpenStreetMapApi implements OpenStreetMapApi {
  _OpenStreetMapApi(
    this._dio, {
    this.baseUrl,
  }) {
    baseUrl ??= 'https://nominatim.openstreetmap.org/';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<List<OpenStreetMapPlaceModel>> getPlacesQuery({
    required String query,
    String language = 'ru',
    String countrycodes = 'kz',
    String format = 'jsonv2',
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'q': query,
      r'accept-language': language,
      r'countrycodes': countrycodes,
      r'format': format,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<List<dynamic>>(
        _setStreamType<List<OpenStreetMapPlaceModel>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              'https://nominatim.openstreetmap.org/search.php',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    var value = _result.data!
        .map((dynamic i) =>
            OpenStreetMapPlaceModel.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
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
        'pk.eyJ1IjoidmFuZGVydmFpeiIsImEiOiJjbGRpbTJvcHEwOHR4M25td203cDA0aXdrIn0.mP_I0HQ84N1-SLmgnU6XUQ',
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
    final _result = await _dio.fetch(_setStreamType<dynamic>(Options(
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
        ))));
    final value = _result.data;
    return value;
  }

  @override
  Future<OpenStreetMapPlaceModel> getPlaceDetail({
    required double longitude,
    required double latitude,
    int zoom = 18,
    String format = 'jsonv2',
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'lon': longitude,
      r'lat': latitude,
      r'zoom': zoom,
      r'format': format,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<OpenStreetMapPlaceModel>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              'reverse.php',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = OpenStreetMapPlaceModel.fromJson(_result.data!);
    return value;
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
