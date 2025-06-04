import 'package:aktau_go/models/open_street_map/open_street_map_place_model.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:uuid/v4.dart';

import '../../../models/mapbox/mapbox_feature_model.dart';

part 'open_street_map_api.g.dart';

@injectable
@RestApi(baseUrl: 'https://nominatim.openstreetmap.org/')
abstract class OpenStreetMapApi {
  @factoryMethod
  factory OpenStreetMapApi(
    Dio dio,
  ) = _OpenStreetMapApi;

  @GET("https://nominatim.openstreetmap.org/search.php")
  Future<List<OpenStreetMapPlaceModel>> getPlacesQuery({
    @Query('q') required String query,
    @Query('accept-language') String language = 'ru',
    @Query('countrycodes') String countrycodes = 'kz',
    @Query('format') String format = 'jsonv2',
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
        'pk.eyJ1IjoidmFuZGVydmFpeiIsImEiOiJjbGRpbTJvcHEwOHR4M25td203cDA0aXdrIn0.mP_I0HQ84N1-SLmgnU6XUQ',
  });

  @GET("reverse.php")
  Future<OpenStreetMapPlaceModel> getPlaceDetail({
    @Query('lon') required double longitude,
    @Query('lat') required double latitude,
    @Query('zoom') int zoom = 18,
    @Query('format') String format = 'jsonv2',
  });
}
