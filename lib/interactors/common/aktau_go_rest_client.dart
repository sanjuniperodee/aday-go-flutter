import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'aktau_go_rest_client.g.dart';

/// команда для генерации dart pub run build_runner build
/// апи для выполнения запросов, связанных с профилем
@RestApi()
abstract class AktauGoRestClient {
  @factoryMethod
  factory AktauGoRestClient(Dio dio) = _AktauGoRestClient;

  /// запрос профиля пользователя
  @POST('https://api.aktau-go.kz/neword')
  Future<dynamic> createNewFoodOrder({
    @Body() required Map<String, dynamic> body,
  });

  /// запрос профиля пользователя
  @POST('https://api.aktau-go.kz/getaddress/{phone}')
  Future<dynamic> fetchUserAddresses({
    @Path('phone') required String phone,
  });
}
