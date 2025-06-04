import 'dart:io';
import 'dart:convert';

import 'package:aktau_go/core/images.dart';
import 'package:aktau_go/interactors/main_navigation_interactor.dart';
import 'package:aktau_go/ui/basket/forms/food_order_form.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:geolocator/geolocator.dart';
import 'package:geotypes/geotypes.dart' as geotypes;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/text_styles.dart';
import '../../interactors/order_requests_interactor.dart';
import '../../interactors/profile_interactor.dart';
import '../widgets/primary_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import '../../utils/text_editing_controller.dart';
import '../../core/colors.dart';
import '../../domains/food/food_category_domain.dart';
import '../../domains/food/food_domain.dart';
import '../../domains/user/user_domain.dart';
import '../../forms/driver_registration_form.dart';
import '../../interactors/common/rest_client.dart';
import '../../interactors/food_interactor.dart';
import '../../models/active_client_request/active_client_request_model.dart';
import '../../utils/logger.dart';
import '../../utils/utils.dart';
import '../widgets/rounded_text_field.dart';
import './forms/driver_order_form.dart';

import './tenant_home_model.dart';
import './tenant_home_screen.dart';
import '../../interactors/location_interactor.dart';
import 'package:shared_preferences/shared_preferences.dart';

defaultTenantHomeWMFactory(BuildContext context) => TenantHomeWM(
      TenantHomeModel(
        inject<FoodInteractor>(),
        inject<ProfileInteractor>(),
        inject<OrderRequestsInteractor>(),
        inject<MainNavigationInteractor>(),
      ),
    );

abstract class ITenantHomeWM implements IWidgetModel {
  // mapbox.MapboxMapController? get mapboxMapController;

  StateNotifier<geotypes.Position> get userLocation;

  StateNotifier<geotypes.Position> get driverLocation;

  StateNotifier<geoLocator.LocationPermission> get locationPermission;

  TabController get tabController;

  StateNotifier<int> get currentTab;

  StateNotifier<bool> get isOrderRejected;

  StateNotifier<List<FoodCategoryDomain>> get foodCategories;

  EntityStateNotifier<List<FoodDomain>> get foods;

  StateNotifier<ActiveClientRequestModel> get activeOrder;

  StateNotifier<UserDomain> get me;

  StateNotifier<double> get draggableMaxChildSize;

  StateNotifier<bool> get showFood;

  StateNotifier<bool> get rateOpened;

  StateNotifier<double> get draggableScrolledSize;

  DraggableScrollableController get draggableScrollableController;
  
  // Добавляем MapboxMapController для управления картой
  MapboxMap? get mapboxMapController;

  Future<void> determineLocationPermission({
    bool force = false,
  });

  void tabIndexChanged(int newTabIndex);

  Future<void> onSubmit(DriverOrderForm form, DriverType taxi);

  void cancelActiveClientOrder();

  void getMyLocation();

  void scrollDraggableSheetDown();

  void onMapTapped(geotypes.Position point);
  
  // Добавляем метод для установки контроллера карты
  void setMapboxController(MapboxMap controller);

  // Добавляем метод для отображения маршрута на карте
  Future<void> displayRouteOnMainMap(geotypes.Position fromPosition, geotypes.Position toPosition);
}

class TenantHomeWM extends WidgetModel<TenantHomeScreen, TenantHomeModel>
    with SingleTickerProviderWidgetModelMixin
    implements ITenantHomeWM {
  TenantHomeWM(
    TenantHomeModel model,
  ) : super(model);

  IO.Socket? newOrderSocket;
  
  // Добавляем MapboxMapController для управления картой
  MapboxMap? _mapboxMapController;

  @override
  final StateNotifier<geotypes.Position> userLocation = StateNotifier(
    initValue: geotypes.Position(
      51.260834,
      43.693695,
    ),
  );

  @override
  final StateNotifier<double> draggableMaxChildSize = StateNotifier(
    initValue: 1,
  );

  @override
  final StateNotifier<geotypes.Position> driverLocation = StateNotifier();
  @override
  final StateNotifier<bool> showFood = StateNotifier(
    initValue: false,
  );

  @override
  late final TabController tabController = TabController(
    length: 5,
    vsync: this,
  );

  @override
  final StateNotifier<int> currentTab = StateNotifier(
    initValue: 0,
  );

  @override
  final StateNotifier<double> rateTaxi = StateNotifier(
    initValue: 0,
  );

  @override
  final StateNotifier<double> draggableScrolledSize = StateNotifier(
    initValue: 0,
  );

  @override
  final StateNotifier<bool> isOrderRejected = StateNotifier(
    initValue: false,
  );
  @override
  final StateNotifier<bool> rateOpened = StateNotifier(
    initValue: false,
  );

  @override
  final StateNotifier<List<FoodCategoryDomain>> foodCategories = StateNotifier(
    initValue: const [],
  );

  @override
  final EntityStateNotifier<List<FoodDomain>> foods = EntityStateNotifier();
  @override
  final StateNotifier<ActiveClientRequestModel> activeOrder = StateNotifier();

  @override
  final StateNotifier<UserDomain> me = StateNotifier();

  @override
  final StateNotifier<geoLocator.LocationPermission> locationPermission = StateNotifier();

  late final TextEditingController commentTextController = createTextEditingController();

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    fetchUserProfile();
    fetchFoods();
    fetchActiveOrder();
    
    // ВАЖНО: Запрашиваем разрешения на геолокацию при инициализации
    determineLocationPermission();
    
    // Сначала получаем реальное местоположение
    _initializeUserLocation();
    
    draggableScrollableController.addListener(() {
      draggableScrolledSize.accept(draggableScrollableController.size);
    });
    
    Geolocator.getPositionStream().listen((geoLocator.Position position) {
      userLocation.accept(
        geotypes.Position(
          position.longitude,
          position.latitude,
        ),
      );
      
      // Автоматически обновляем камеру при получении нового местоположения
      // if (mapboxMapController != null) {
      //   mapboxMapController!.animateCamera(
      //     mapbox.CameraUpdate.newCameraPosition(
      //       mapbox.CameraPosition(
      //         target: mapbox.LatLng(
      //           data.latitude,
      //           data.longitude,
      //         ),
      //         zoom: 20, // Максимально близкий зум
      //       ),
      //     ),
      //   );
      // }

      _checkLocation();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      draggableScrolledSize.accept(0);
      draggableScrolledSize.accept(draggableScrollableController.size);
    });
  }
  
  Future<void> _initializeUserLocation() async {
    try {
      final geoLocator.Position? location = await Geolocator.getCurrentPosition();
      if (location != null) {
        userLocation.accept(
          geotypes.Position(
            location.longitude,
            location.latitude,
          ),
        );
      }
    } catch (e) {
      // Если не удалось получить местоположение, оставляем дефолтное
      print('Error getting location: $e');
    }
  }

  Future<int?> _checkLocation() async {
    try {
      // Получение текущего местоположения
      var position = userLocation.value!;
      var idshop = -1;

      // Вычисление расстояния до целевых координат
      double aktauDistanceInMeters = Geolocator.distanceBetween(
        position.lat.toDouble(),
        position.lng.toDouble(),
        43.39,
        51.09,
      );

      // Вычисление расстояния до целевых координат
      double zhanaOzenDistanceInMeters = Geolocator.distanceBetween(
        position.lat.toDouble(),
        position.lng.toDouble(),
        43.3412,
        52.8619,
      );

      if (aktauDistanceInMeters <= 40000) {
        idshop = 9;
      }

      if (zhanaOzenDistanceInMeters <= 40000) {
        idshop = 13;
      }
      
      if (idshop != -1) {
        showFood.accept(true);
        return idshop;
      }
    } catch (e) {
      logger.e(e);
    }
    showFood.accept(false);
    return null;
  }

  @override
  Future<void> determineLocationPermission({
    bool force = false,
  }) async {
    try {
      print('🔍 Начинаем determineLocationPermission...');
      
      // Сначала запрашиваем разрешения через LocationInteractor
      final permission = await inject<LocationInteractor>().requestLocation();
      print('📍 Получены разрешения: $permission');
      
      // ВАЖНО: Обновляем состояние locationPermission!
      if (permission != null) {
        locationPermission.accept(permission);
        print('✅ locationPermission обновлен: $permission');
      } else {
        // Если не удалось получить разрешения, устанавливаем denied
        locationPermission.accept(geoLocator.LocationPermission.denied);
        print('❌ Устанавливаем locationPermission как denied');
        return; // Выходим если нет разрешений
      }
      
      // Проверяем что разрешения действительно получены
      if (![geoLocator.LocationPermission.always, geoLocator.LocationPermission.whileInUse].contains(permission)) {
        print('❌ Недостаточные разрешения: $permission');
        return;
      }
      
      // Затем получаем текущее местоположение
      final geoLocator.Position? location = await inject<LocationInteractor>().getCurrentLocation();
      
      if (location != null) {
        userLocation.accept(
          geotypes.Position(
            location.longitude,
            location.latitude,
          ),
        );
        
        // Также обновляем в SharedPreferences для других частей приложения
        await inject<SharedPreferences>().setDouble('latitude', location.latitude);
        await inject<SharedPreferences>().setDouble('longitude', location.longitude);
        
        print('✅ Успешно получены и сохранены координаты: ${location.latitude}, ${location.longitude}');
        
        // ДОБАВЛЯЕМ: Обновляем камеру карты на новое местоположение
        await _updateMapCamera();
        
        // Показываем пользователю успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Местоположение определено успешно'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('⚠️ Не удалось получить координаты');
        // Попробуем использовать сохраненные координаты
        final savedLat = inject<SharedPreferences>().getDouble('latitude');
        final savedLng = inject<SharedPreferences>().getDouble('longitude');
        
        if (savedLat != null && savedLng != null && savedLat != 0 && savedLng != 0) {
          userLocation.accept(
            geotypes.Position(savedLng, savedLat),
          );
          print('📌 Используем сохраненные координаты: $savedLat, $savedLng');
        } else {
          print('🌍 Используем координаты Актау по умолчанию');
          // В случае если нет сохраненных координат, используем координаты Актау
          userLocation.accept(
            geotypes.Position(51.260834, 43.693695),
          );
        }
      }
    } catch (e) {
      print('❌ Ошибка при получении геопозиции: $e');
      // В случае ошибки устанавливаем denied и дефолтные координаты
      locationPermission.accept(geoLocator.LocationPermission.denied);
      userLocation.accept(
        geotypes.Position(51.260834, 43.693695),
      );
    }
  }

  @override
  void tabIndexChanged(int newTabIndex) {
    currentTab.accept(newTabIndex);
    if (newTabIndex == 1) {
      draggableMaxChildSize.accept(0.9);
      draggableScrollableController.jumpTo(0.9);
    } else {
      draggableMaxChildSize.accept(0.6);
      draggableScrollableController.jumpTo(0.6);
    }
    tabController.animateTo(newTabIndex);
  }

  Future<void> fetchFoods() async {
    foods.loading();

    try {
      final response = await model.fetchFoods();
      foodCategories.accept(response.folders);
      foods.content(response.items);
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  Future<void> fetchUserProfile() async {
    final response = await model.getUserProfile();

    me.accept(response);

    initializeSocket();
  }

  @override
  Future<void> onSubmit(DriverOrderForm form, DriverType taxi) async {
    await inject<RestClient>().createDriverOrder(body: {
      "from": form.fromAddress.value,
      "to": form.toAddress.value,
      "lng": userLocation.value?.lng,
      "lat": userLocation.value?.lat,
      "price": form.cost.value,
      "orderType": taxi.key,
      "comment": '${form.comment};${form.fromMapboxId.value};${form.toMapboxId.value}',
      "fromMapboxId": form.fromMapboxId.value,
      "toMapboxId": form.toMapboxId.value,
    });
    draggableScrollableController.jumpTo(0.3);
    fetchActiveOrder();
  }

  Future<void> initializeSocket() async {
    try {
      // Проверяем, есть ли уже активное подключение
      if (newOrderSocket != null) {
        if (newOrderSocket!.connected) {
          print('Сокет уже подключен, используем существующее соединение');
          return;
        } else {
          // Закрываем старое подключение перед созданием нового
          print('Закрываем старое неактивное соединение перед созданием нового');
          newOrderSocket!.dispose();
          newOrderSocket = null;
        }
      }

      // Запрашиваем разрешения на геолокацию и обновляем местоположение
      await determineLocationPermission();

      // Проверяем наличие необходимых данных для подключения
      if (me.value == null || me.value!.id == null) {
        print('Ошибка: нет данных пользователя для подключения сокета');
        return;
      }

      print('Создаем новое соединение сокета для пользователя ${me.value!.id}');
      newOrderSocket = IO.io(
        'https://taxi.aktau-go.kz',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'force new connection': true,
          'query': {
            'userId': me.value!.id,
          },
        },
      );

      // Настраиваем обработчики событий
      newOrderSocket?.on(
        'orderRejected',
        (data) async {
          print('Получено событие orderRejected: $data');
          isOrderRejected.accept(true);
          await showModalBottomSheet(
            context: context,
            isDismissible: true,
            isScrollControlled: true,
            builder: (context) => PrimaryBottomSheet(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: greyscale30,
                        borderRadius: BorderRadius.circular(1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SvgPicture.asset(icPlacemarkError),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Поездка отклонена',
                      style: text500Size20Greyscale90,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton.primary(
                      onPressed: () async {
                        isOrderRejected.accept(false);
                        Navigator.of(context).pop();
                      },
                      text: 'Закрыть',
                      textStyle: text400Size16White,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
          fetchActiveOrder();
        },
      );

      newOrderSocket?.on('orderStarted', (data) {
        print('Получено событие orderStarted: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('driverArrived', (data) {
        print('Получено событие driverArrived: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('rideStarted', (data) {
        print('Получено событие rideStarted: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('rideEnded', (data) {
        print('Получено событие rideEnded: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('orderAccepted', (data) {
        print('Получено событие orderAccepted: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('driverLocation', (data) {
        print('Получено событие driverLocation');
        geotypes.Position point;
        if (data['lat'] is String) {
          point = geotypes.Position(double.tryParse(data['lng']) ?? 0, double.tryParse(data['lat']) ?? 0);
        } else {
          point = geotypes.Position(data['lng'], data['lat']);
        }
        driverLocation.accept(point);
      });

      // Настраиваем обработчик отключения
      newOrderSocket?.onDisconnect((_) {
        print('Сокет отключен: $_, для tenant (клиента) переподключаемся автоматически');
        // Только для tenant (клиента) переподключаемся автоматически
        initializeSocket();
      });
      
      // Устанавливаем соединение
      newOrderSocket?.connect();
      print('Сокет подключен для пользователя (tenant)');
    } on Exception catch (e) {
      print('Ошибка при инициализации сокета: $e');
      logger.e(e);
    }
  }

  @override
  void dispose() {
    // Отключаем сокет при уничтожении виджета
    print('Отключаем сокет в dispose');
    disconnectWebsocket();
    super.dispose();
  }

  Future<void> disconnectWebsocket() async {
    if (newOrderSocket != null) {
      print('Отключаем сокет клиента');
      try {
        newOrderSocket!.disconnect();
        // Важно: не пытаемся автоматически переподключиться после явного отключения
        newOrderSocket!.clearListeners();
        newOrderSocket = null;
      } catch (e) {
        print('Ошибка при отключении сокета: $e');
      }
    }
  }

  Future<void> fetchActiveOrder() async {
    try {
      final response = await model.getMyClientActiveOrder();
      if (response.order?.orderStatus == 'COMPLETED' &&
          response.order?.rating == null &&
          rateOpened.value == false) {
        rateOpened.accept(true);
        await showModalBottomSheet(
          context: context,
          isDismissible: true,
          isScrollControlled: true,
          builder: (context) => PrimaryBottomSheet(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: greyscale30,
                      borderRadius: BorderRadius.circular(1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Заказ завершён, поставьте оценку',
                    style: text500Size20Greyscale90,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: StateNotifierBuilder(
                    listenableState: rateTaxi,
                    builder: (
                      context,
                      double? rateTaxi,
                    ) {
                      return Center(
                        child: RatingStars(
                          value: rateTaxi ?? 0,
                          onValueChanged: (value) {
                            this.rateTaxi.accept(value);
                          },
                          starBuilder: (
                            index,
                            color,
                          ) =>
                              index >= (rateTaxi ?? 0)
                                  ? SvgPicture.asset('assets/icons/star.svg')
                                  : SvgPicture.asset(
                                      'assets/icons/star.svg',
                                      color: color,
                                    ),
                          starCount: 5,
                          starSize: 48,
                          maxValue: 5,
                          starSpacing: 16,
                          maxValueVisibility: false,
                          valueLabelVisibility: false,
                          animationDuration: Duration(
                            milliseconds: 1000,
                          ),
                          starOffColor: greyscale50,
                          starColor: primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: RoundedTextField(
                    backgroundColor: Colors.white,
                    controller: commentTextController,
                    hintText: 'Ваш комментарий',
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton.primary(
                    onPressed: () async {
                      await inject<RestClient>().makeReview(body: {
                        "orderRequestId": response.order!.id,
                        "comment": commentTextController.text,
                        "rating": rateTaxi.value,
                      });
                      Navigator.of(context).pop();
                      fetchActiveOrder();
                    },
                    text: 'Отправить',
                    textStyle: text400Size16White,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
        rateOpened.accept(false);
      }
      if (response.order?.orderStatus != 'COMPLETED') {
        activeOrder.accept(response);
      }
    } on Exception catch (e) {
      activeOrder.accept(null);
      // TODO
    }
    // showModalBottomSheet(
    //   context: context,
    //   isDismissible: false,
    //   enableDrag: false,
    //   isScrollControlled: true,
    //   useSafeArea: true,
    //   builder: (context) => ActiveClientOrderBottomSheet(
    //     me: me.value!,
    //     activeOrder: activeOrder.value!,
    //     activeOrderListener: activeOrder,
    //     onCancel: () {
    //       model.rejectOrderByClientRequest(
    //         orderRequestId: activeOrder.value!.order!.id!,
    //       );
    //     },
    //   ),
    // );
  }

  @override
  Future<void> cancelActiveClientOrder() async {
    await showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Вы уверены что хотите отменить заказ?',
                  style: text400Size16Greyscale90,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton.secondary(
                      text: 'Назад',
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton.primary(
                      text: 'Отменить',
                      textStyle: text400Size16White,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await model.rejectOrderByClientRequest(
                          orderRequestId: activeOrder.value!.order!.id!,
                        );
                        fetchActiveOrder();
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  final DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();

  @override
  void getMyLocation() {
    _updateMapCamera();
  }

  @override
  void scrollDraggableSheetDown() {
    draggableScrollableController.jumpTo(1);
  }

  @override
  void onMapTapped(geotypes.Position point) {
    model.onMapTapped(point);
  }

  @override
  MapboxMap? get mapboxMapController => _mapboxMapController;

  @override
  void setMapboxController(MapboxMap controller) {
    _mapboxMapController = controller;
    print('Контроллер карты установлен успешно');
    
    // Обновляем камеру при установке контроллера, если есть местоположение
    if (userLocation.value != null) {
      _updateMapCamera();
    }
  }
  
  // Метод для обновления камеры карты
  Future<void> _updateMapCamera() async {
    if (_mapboxMapController != null && userLocation.value != null) {
      try {
        await _mapboxMapController!.flyTo(
          CameraOptions(
            center: Point(coordinates: userLocation.value!),
            zoom: 16.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
        print('Камера карты обновлена на текущее местоположение');
      } catch (e) {
        print('Ошибка при обновлении камеры: $e');
      }
    }
  }
  
  // Метод для отображения маршрута, вызывает соответствующий метод в TenantHomeScreen
  @override
  Future<void> displayRouteOnMainMap(geotypes.Position fromPosition, geotypes.Position toPosition) async {
    if (_mapboxMapController == null) {
      print('Ошибка: контроллер карты не инициализирован');
      return;
    }
    
    // Используем метод из TenantHomeScreen
    await context.findAncestorWidgetOfExactType<TenantHomeScreen>()?.displayRouteOnMainMap(
      _mapboxMapController!,
      fromPosition,
      toPosition
    );
  }
}
