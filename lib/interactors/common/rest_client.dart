import 'package:aktau_go/models/active_request/active_request_model.dart';
import 'package:aktau_go/models/driver_registered_category/driver_registered_category_model.dart';
import 'package:aktau_go/models/food/foods_response_model.dart';
import 'package:aktau_go/models/user/user_model.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/active_client_request/active_client_request_model.dart';
import '../../models/open_street_map/open_street_map_place_model.dart';
import '../../models/order_request/order_request_response_model.dart';
import '../../models/sign_in/sign_in_by_phone_confirm_code_response_model.dart';
import '../../models/sign_in/sign_in_by_phone_response_model.dart';

part 'rest_client.g.dart';

@singleton
@RestApi()
abstract class RestClient {
  @factoryMethod
  factory RestClient(Dio dio) = _RestClient;

  /// запрос профиля пользователя
  @POST('v1/user/sing-in-by-phone')
  Future<SignInByPhoneResponseModel> signInByPhone({
    @Field('phone') required String phone,
  });

  /// запрос профиля пользователя
  @POST('v1/user/sing-in-by-phone-confirm-code')
  Future<SignInByPhoneConfirmCodeResponseModel> signInByPhoneConfirmCode({
    @Field('phone') required String phone,
    @Field('smscode') required String smsCode,
  });

  /// запрос профиля пользователя
  @POST('v1/user/sing-up-by-phone')
  Future<SignInByPhoneConfirmCodeResponseModel> signUpByPhone({
    @Field('phone') required String phone,
    @Field('firstName') required String firstName,
    @Field('lastName') required String lastName,
  });

  /// запрос профиля пользователя
  @GET('v1/order-requests/active-orders')
  Future<List<OrderRequestResponseModel>> getPendingOrderRequests();

  /// запрос профиля пользователя
  @GET('v1/order-requests/active/{type}')
  Future<List<OrderRequestResponseModel>> getPendingOrderRequestsByType({
    @Path('type') required String type,
  });

  /// запрос профиля пользователя
  @GET('v1/user/GetMe')
  Future<UserModel> getUserProfile();

  /// запрос профиля пользователя
  @POST('v1/order-requests/accept')
  Future<void> acceptOrderRequest({
    @Field('driverId') required String driverId,
    @Field('orderId') required String orderRequestId,
  });

  /// запрос профиля пользователя
  @POST('v1/order-requests/driver-arrived')
  Future<void> arrivedOrderRequest({
    @Field('driverId') required String driverId,
    @Field('orderId') required String orderRequestId,
  });

  /// запрос профиля пользователя
  @POST('v1/order-requests/reject/{orderId}')
  Future<void> rejectOrderRequest({
    @Path('orderId') required String orderRequestId,
  });

  /// запрос профиля пользователя
  @POST('v1/order-requests/cancel/{orderId}')
  Future<void> rejectOrderByClientRequest({
    @Path('orderId') required String orderRequestId,
  });

  /// запрос профиля пользователя
  @POST('v1/order-requests/start')
  Future<void> startOrderRequest({
    @Field('driverId') required String driverId,
    @Field('orderId') required String orderRequestId,
  });

  /// запрос профиля пользователя
  @POST('v1/order-requests/end')
  Future<void> endOrderRequest({
    @Field('driverId') required String driverId,
    @Field('orderId') required String orderRequestId,
  });

  /// запрос профиля пользователя
  @GET('v1/order-requests/my-active-order')
  Future<ActiveRequestModel> getMyActiveOrder();

  /// запрос профиля пользователя
  @GET('v1/order-requests/client-active-order')
  Future<ActiveClientRequestModel> getMyClientActiveOrder();

  /// запрос профиля пользователя
  @GET('v1/order-requests/history/{type}')
  Future<List<ActiveRequestModel>> getHistoryOrders({
    @Path('type') required String type,
  });

  /// запрос профиля пользователя
  @GET('v1/order-requests/client-history/{type}')
  Future<List<ActiveRequestModel>> getClientHistoryOrders({
    @Path('type') required String type,
  });

  /// запрос профиля пользователя
  @POST('v1/order-requests/category/register')
  Future<void> createDriverCategory({
    @Field('governmentNumber') required String governmentNumber,
    @Field('type') required String type,
    @Field('model') required String model,
    @Field('brand') required String brand,
    @Field('color') required String color,
    @Field('SSN') required String SSN,
  });

  /// запрос профиля пользователя
  @PUT('v1/order-requests/category/{id}')
  Future<void> editDriverCategory({
    @Path('id') required String id,
    @Field('governmentNumber') required String governmentNumber,
    @Field('type') required String type,
    @Field('model') required String model,
    @Field('brand') required String brand,
    @Field('color') required String color,
    @Field('SSN') required String SSN,
  });

  /// запрос профиля пользователя
  @GET('v1/order-requests/category/info')
  Future<List<DriverRegisteredCategoryModel>> driverRegisteredCategories();

  /// запрос профиля пользователя
  @POST('v1/user/device')
  Future<void> saveFirebaseDeviceToken({
    @Field('device') required String deviceToken,
  });

  /// запрос профиля пользователя
  @GET('v1/order-requests/menu/9')
  Future<FoodsResponseModel> fetchFoods();

  /// запрос профиля пользователя
  @POST('v1/order-requests/create-order')
  Future<void> createDriverOrder({
    @Body() required Map<String, dynamic> body,
  });

  /// запрос профиля пользователя
  @POST('v1/order-requests/make-review')
  Future<void> makeReview({
    @Body() required Map<String, dynamic> body,
  });

  @GET("v1/order-requests/address")
  Future<String> getPlaceDetail({
    @Query('lon') required double longitude,
    @Query('lat') required double latitude,
  });

  @GET("v1/order-requests/find-by-name")
  Future<List<OpenStreetMapPlaceModel>> getPlacesQuery({
    @Query('search') required String query,
    @Query('lon') required double longitude,
    @Query('lat') required double latitude,
  });
}
