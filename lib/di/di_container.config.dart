// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:aktau_go/interactors/authorization_interactor.dart' as _i154;
import 'package:aktau_go/interactors/common/map_tiler_cloud_api/map_tiler_cloud_api.dart'
    as _i84;
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart'
    as _i653;
import 'package:aktau_go/interactors/common/open_street_map_api/open_street_map_api.dart'
    as _i536;
import 'package:aktau_go/interactors/common/rest_client.dart' as _i867;
import 'package:aktau_go/interactors/food_interactor.dart' as _i580;
import 'package:aktau_go/interactors/location_interactor.dart' as _i302;
import 'package:aktau_go/interactors/main_navigation_interactor.dart' as _i401;
import 'package:aktau_go/interactors/notification_interactor.dart' as _i276;
import 'package:aktau_go/interactors/notification_service.dart' as _i525;
import 'package:aktau_go/interactors/order_requests_interactor.dart' as _i640;
import 'package:aktau_go/interactors/profile_interactor.dart' as _i199;
import 'package:aktau_go/interactors/session_interactor.dart' as _i36;
import 'package:aktau_go/modules/dio/base/material_message_controller.dart'
    as _i775;
import 'package:aktau_go/modules/dio/base/standard_error_handler.dart' as _i590;
import 'package:aktau_go/modules/dio/dio_module.dart' as _i137;
import 'package:aktau_go/modules/flavor/flavor.dart' as _i703;
import 'package:aktau_go/modules/flavor/flavor_interactor.dart' as _i298;
import 'package:aktau_go/modules/shared_preferences_module.dart' as _i556;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

const String _test = 'test';
const String _dev = 'dev';
const String _prod = 'prod';

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final sharedPreferencesModule = _$SharedPreferencesModule();
  final dioModule = _$DioModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => sharedPreferencesModule.prefs,
    preResolve: true,
  );
  gh.factory<_i775.MaterialMessageController>(
      () => _i775.MaterialMessageController());
  gh.singleton<_i276.NotificationInteractor>(
      () => _i276.NotificationInteractor());
  gh.factory<_i703.Flavor>(
    () => _i703.QAFlavor(),
    registerFor: {_test},
  );
  gh.factory<_i703.Flavor>(
    () => _i703.DevFlavor(),
    registerFor: {_dev},
  );
  gh.singleton<_i590.StandardErrorHandler>(
      () => _i590.StandardErrorHandler(gh<_i775.MaterialMessageController>()));
  gh.factory<_i703.Flavor>(
    () => _i703.ProdFlavor(),
    registerFor: {_prod},
  );
  gh.lazySingleton<_i361.Dio>(() => dioModule.getDio(gh<_i703.Flavor>()));
  gh.singleton<_i302.LocationInteractor>(
      () => _i302.LocationInteractor(gh<_i460.SharedPreferences>()));
  gh.singleton<_i525.NotificationService>(() => _i525.NotificationService(
      notificationInteractor: gh<_i276.NotificationInteractor>()));
  gh.singleton<_i298.FlavorInteractor>(
      () => _i298.FlavorInteractor(gh<_i703.Flavor>()));
  gh.singleton<_i867.RestClient>(() => _i867.RestClient(gh<_i361.Dio>()));
  gh.singleton<_i137.DioInteractor>(() => _i137.DioInteractor(gh<_i361.Dio>()));
  gh.factory<_i84.MapTilerCloudApi>(
      () => _i84.MapTilerCloudApi(gh<_i361.Dio>()));
  gh.factory<_i536.OpenStreetMapApi>(
      () => _i536.OpenStreetMapApi(gh<_i361.Dio>()));
  gh.factory<_i653.MapboxApi>(() => _i653.MapboxApi(gh<_i361.Dio>()));
  gh.singleton<_i580.FoodInteractor>(
      () => _i580.FoodInteractor(gh<_i867.RestClient>()));
  gh.singleton<_i199.ProfileInteractor>(
      () => _i199.ProfileInteractor(gh<_i867.RestClient>()));
  gh.singleton<_i640.OrderRequestsInteractor>(
      () => _i640.OrderRequestsInteractor(gh<_i867.RestClient>()));
  gh.lazySingleton<_i36.SessionInteractor>(() => _i36.SessionInteractor(
        gh<_i460.SharedPreferences>(),
        gh<_i867.RestClient>(),
      ));
  gh.singleton<_i401.MainNavigationInteractor>(
      () => _i401.MainNavigationInteractor(gh<_i36.SessionInteractor>()));
  gh.singleton<_i154.AuthorizationInteractor>(
      () => _i154.AuthorizationInteractor(
            gh<_i867.RestClient>(),
            gh<_i36.SessionInteractor>(),
          ));
  return getIt;
}

class _$SharedPreferencesModule extends _i556.SharedPreferencesModule {}

class _$DioModule extends _i137.DioModule {}
