import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../models/map_tiler/map_tiler_geo_coding_response.dart';

part 'map_tiler_cloud_api.g.dart';

@injectable
@RestApi(baseUrl: 'https://api.maptiler.com/')
abstract class MapTilerCloudApi {
  @factoryMethod
  factory MapTilerCloudApi(
    Dio dio,
  ) = _MapTilerCloudApi;

  @GET('geocoding/{query}.json')
  Future<MapTilerGeoCodingResponse> geoCodingByQuery({
    @Path('query') required String query,
    @Query('key') required String accessToken,
    @Query('country') String country = 'kz',
    @Query('types') List<String> types = const ['address'],
  });

  @GET(
    "geocoding/{longitude},{latitude}.json",
  )
  Future<MapTilerGeoCodingResponse> geoCoding({
    @Path('longitude') required double longitude,
    @Path('latitude') required double latitude,
    @Query('key') required String accessToken,
  });
}
