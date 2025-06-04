// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:aktau_go/interactors/authorization_interactor.dart' as _i17;
import 'package:aktau_go/interactors/common/map_tiler_cloud_api/map_tiler_cloud_api.dart'
    as _i12;
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart' as _i13;
import 'package:aktau_go/interactors/common/open_street_map_api/open_street_map_api.dart'
    as _i14;
import 'package:aktau_go/interactors/common/rest_client.dart' as _i15;
import 'package:aktau_go/interactors/food_interactor.dart' as _i18;
import 'package:aktau_go/interactors/location_interactor.dart' as _i11;
import 'package:aktau_go/interactors/main_navigation_interactor.dart' as _i19;
import 'package:aktau_go/interactors/notification_interactor.dart' as _i6;
import 'package:aktau_go/interactors/order_requests_interactor.dart' as _i20;
import 'package:aktau_go/interactors/profile_interactor.dart' as _i21;
import 'package:aktau_go/interactors/session_interactor.dart' as _i16;
import 'package:aktau_go/modules/dio/base/material_message_controller.dart'
    as _i5;
import 'package:aktau_go/modules/dio/base/standard_error_handler.dart' as _i8;
import 'package:aktau_go/modules/dio/dio_module.dart' as _i10;
import 'package:aktau_go/modules/flavor/flavor.dart' as _i3;
import 'package:aktau_go/modules/flavor/flavor_interactor.dart' as _i4;
import 'package:aktau_go/modules/shared_preferences_module.dart' as _i22;
import 'package:dio/dio.dart' as _i9;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:shared_preferences/shared_preferences.dart' as _i7;

const String _prod = 'prod';
const String _test = 'test';
const String _dev = 'dev';

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i1.GetIt> init(
  _i1.GetIt getIt, {
  String? environment,
  _i2.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i2.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final sharedPreferencesModule = _$SharedPreferencesModule();
  final dioModule = _$DioModule();
  gh.factory<_i3.Flavor>(
    () => _i3.ProdFlavor(),
    registerFor: {_prod},
  );
  gh.factory<_i3.Flavor>(
    () => _i3.QAFlavor(),
    registerFor: {_test},
  );
  gh.factory<_i3.Flavor>(
    () => _i3.DevFlavor(),
    registerFor: {_dev},
  );
  gh.singleton<_i4.FlavorInteractor>(
      () => _i4.FlavorInteractor(gh<_i3.Flavor>()));
  gh.factory<_i5.MaterialMessageController>(
      () => _i5.MaterialMessageController());
  gh.singleton<_i6.NotificationInteractor>(() => _i6.NotificationInteractor());
  await gh.factoryAsync<_i7.SharedPreferences>(
    () => sharedPreferencesModule.prefs,
    preResolve: true,
  );
  gh.singleton<_i8.StandardErrorHandler>(
      () => _i8.StandardErrorHandler(gh<_i5.MaterialMessageController>()));
  gh.lazySingleton<_i9.Dio>(() => dioModule.getDio(gh<_i3.Flavor>()));
  gh.singleton<_i10.DioInteractor>(() => _i10.DioInteractor(gh<_i9.Dio>()));
  gh.singleton<_i11.LocationInteractor>(
      () => _i11.LocationInteractor(gh<_i7.SharedPreferences>()));
  gh.factory<_i12.MapTilerCloudApi>(() => _i12.MapTilerCloudApi(gh<_i9.Dio>()));
  gh.factory<_i13.MapboxApi>(() => _i13.MapboxApi(gh<_i9.Dio>()));
  gh.factory<_i14.OpenStreetMapApi>(() => _i14.OpenStreetMapApi(gh<_i9.Dio>()));
  gh.singleton<_i15.RestClient>(() => _i15.RestClient(gh<_i9.Dio>()));
  gh.lazySingleton<_i16.SessionInteractor>(() => _i16.SessionInteractor(
        gh<_i7.SharedPreferences>(),
        gh<_i15.RestClient>(),
      ));
  gh.singleton<_i17.AuthorizationInteractor>(() => _i17.AuthorizationInteractor(
        gh<_i15.RestClient>(),
        gh<_i16.SessionInteractor>(),
      ));
  gh.singleton<_i18.FoodInteractor>(
      () => _i18.FoodInteractor(gh<_i15.RestClient>()));
  gh.singleton<_i19.MainNavigationInteractor>(
      () => _i19.MainNavigationInteractor(gh<_i16.SessionInteractor>()));
  gh.singleton<_i20.OrderRequestsInteractor>(
      () => _i20.OrderRequestsInteractor(gh<_i15.RestClient>()));
  gh.singleton<_i21.ProfileInteractor>(
      () => _i21.ProfileInteractor(gh<_i15.RestClient>()));
  return getIt;
}

class _$SharedPreferencesModule extends _i22.SharedPreferencesModule {}

class _$DioModule extends _i10.DioModule {}
