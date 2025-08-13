import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:uuid/v4.dart';

import '../../../models/mapbox/mapbox_feature_model.dart';

part 'mapbox_api.g.dart';

@injectable
@RestApi(baseUrl: 'https://api.mapbox.com/')
abstract class MapboxApi {
  @factoryMethod
  factory MapboxApi(
    Dio dio,
  ) = _MapboxApi;

  @GET(
    "https://api.mapbox.com/search/searchbox/v1/suggest",
  )
  Future<MapboxGeoCodingResponse> getPlaces({
    @Query('q') required String query,
    @Query('language') String language = 'ru',
    @Query('session_token') required String sessionToken,
    @Query('country') String country = 'kz',
    // @Query('types') String types = 'address',
    @Query('access_token') String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  });

  @GET(
    "https://api.mapbox.com/search/searchbox/v1/retrieve/{mapbox_id}",
  )
  Future<MapboxFeatureDetailResponse> getPlaceDetail({
    @Path('mapbox_id') required String mapboxId,
    @Query('session_token') required String sessionToken,
    @Query('access_token') String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  });

  @GET(
    "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/{fromLng},{fromLat};{toLng},{toLat}",
  )
  Future<dynamic> getDirections({
    @Path('fromLat') required double fromLat,
    @Path('fromLng') required double fromLng,
    @Path('toLat') required double toLat,
    @Path('toLng') required double toLng,
    @Query('geometries') String geometries = 'geojson',
    @Query('overview') String overview = 'full',
    @Query('steps') bool steps = true,
    @Query('access_token') String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  });

  // @GET(
  //   "geocoding/v5/mapbox.places/{longitude},{latitude}.json",
  // )
  // Future<MapboxGeoCodingResponse> geoCoding({
  //   @Path('longitude') required double longitude,
  //   @Path('latitude') required double latitude,
  //   @Query('access_token')
  //   String accessToken = const String.fromEnvironment("ACCESS_TOKEN"),
  // });
  @GET(
    "geocoding/v5/mapbox.places/{longitude},{latitude}.json",
  )
  Future<MapboxFeatureDetailResponse> geoCoding({
    @Path('longitude') required double longitude,
    @Path('latitude') required double latitude,
    @Query('access_token') String accessToken =
        'sk.eyJ1Ijoic2FuanVuaXBlcm9kZWUiLCJhIjoiY21lOWxuNHgyMDUxMTJqczVha256NnZxaiJ9.cbs7Kyd1tFBMsTjK9B0Pfg',
  });
}
