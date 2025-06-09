import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:aktau_go/core/images.dart';
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart';
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
  
  // Route display state management
  StateNotifier<bool> get isRouteDisplayed;
  
  // Map fixed state management
  StateNotifier<bool> get isMapFixed;
  
  // Сохраненные адреса для заказа
  StateNotifier<String> get savedFromAddress;
  StateNotifier<String> get savedToAddress;
  StateNotifier<String> get savedFromMapboxId;
  StateNotifier<String> get savedToMapboxId;

  DraggableScrollableController get draggableScrollableController;
  
  // Добавляем MapboxMapController для управления картой
  MapboxMap? get mapboxMapController;

  Future<void> determineLocationPermission({
    bool force = false,
  });

  void tabIndexChanged(int newTabIndex);

  Future<void> onSubmit(DriverOrderForm form, DriverType taxi);
  
  // Создать заказ такси
  Future<void> createDriverOrder(DriverOrderForm form);

  void cancelActiveClientOrder();

  void getMyLocation();

  void scrollDraggableSheetDown();

  void onMapTapped(geotypes.Position point);
  
  // Добавляем метод для установки контроллера карты
  void setMapboxController(MapboxMap controller);

  // Добавляем метод для отображения маршрута на карте
  Future<void> displayRouteOnMainMap(geotypes.Position fromPosition, geotypes.Position toPosition);
  
  // Toggle map fixed state
  void toggleMapFixed();
  
  // Set map fixed state directly
  void setMapFixed(bool fixed);
  
  // Set route displayed state
  void setRouteDisplayed(bool displayed);
  
  // Clear displayed route
  Future<void> clearRoute();
  
  // Сохранить адреса заказа
  void saveOrderAddresses({
    required String fromAddress,
    required String toAddress,
    required String fromMapboxId,
    required String toMapboxId,
  });

  // Принудительно обновить адреса в UI
  void forceUpdateAddresses();
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
    length: 2,
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
  final StateNotifier<bool> isRouteDisplayed = StateNotifier(
    initValue: false,
  );

  @override
  final StateNotifier<bool> isMapFixed = StateNotifier(
    initValue: false,
  );

  @override
  final StateNotifier<String> savedFromAddress = StateNotifier();
  @override
  final StateNotifier<String> savedToAddress = StateNotifier();
  @override
  final StateNotifier<String> savedFromMapboxId = StateNotifier();
  @override
  final StateNotifier<String> savedToMapboxId = StateNotifier();

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    
    print('Инициализация TenantHomeWM...');
    
    // Важно: сначала получаем профиль пользователя
    fetchUserProfile().then((_) {
      // После получения профиля - инициализируем сокет
      initializeSocket();
      
      // Проверяем наличие активного заказа
      fetchActiveOrder();
    });
    
    // Загружаем категории и еду в параллели
    fetchFoods();
    
    // ВАЖНО: Запрашиваем разрешения на геолокацию и ЖДЕМ местоположение
    _initializeLocationAndAddress();
    
    // Настраиваем слушатель для draggableScrollableController
    draggableScrollableController.addListener(() {
      draggableScrolledSize.accept(draggableScrollableController.size);
    });
    
    // Настраиваем слушатель для обновления местоположения пользователя
    Geolocator.getPositionStream().listen((geoLocator.Position position) {
      // Отключаем лишние сообщения
      // print('Получено обновление местоположения: ${position.latitude}, ${position.longitude}');
      userLocation.accept(
        geotypes.Position(
          position.longitude,
          position.latitude,
        ),
      );

      _checkLocation();
    });

    // Делаем отложенную инициализацию UI с увеличенным размером draggableMaxChildSize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      draggableMaxChildSize.accept(1.0); // Увеличиваем до полного размера экрана
      draggableScrolledSize.accept(draggableScrollableController.size);
    });
  }
  
  // Новый метод: последовательная инициализация местоположения и адреса
  Future<void> _initializeLocationAndAddress() async {
    try {
      print('Начинаем последовательную инициализацию местоположения и адреса...');
      
      // 1. Сначала запрашиваем разрешения с timeout
      await determineLocationPermission().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Timeout при запросе разрешений на геолокацию');
        },
      );
      
      // 2. Получаем местоположение с timeout
      await _initializeUserLocation().timeout(
        Duration(seconds: 8),
        onTimeout: () {
          print('Timeout при получении местоположения');
        },
      );
      
      // 3. ТОЛЬКО ПОСЛЕ получения местоположения определяем адрес с timeout
      await _initializeCurrentLocationAddress().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Timeout при определении адреса, используем базовый адрес');
          // В случае timeout устанавливаем базовый адрес
          savedFromAddress.accept('Текущее местоположение');
          if (userLocation.value != null) {
            savedFromMapboxId.accept('${userLocation.value!.lat};${userLocation.value!.lng}');
          } else {
            savedFromMapboxId.accept('43.693695;51.260834'); // Координаты Актау
          }
          _forceUIUpdate();
        },
      );
      
      print('Инициализация местоположения и адреса завершена');
    } catch (e) {
      print('Ошибка при инициализации местоположения и адреса: $e');
      // В случае любой ошибки устанавливаем базовый адрес
      savedFromAddress.accept('Текущее местоположение');
      savedFromMapboxId.accept('43.693695;51.260834'); // Координаты Актау
      _forceUIUpdate();
    }
  }

  // Улучшенная инициализация местоположения пользователя
  Future<void> _initializeUserLocation() async {
    try {
      print('Инициализация местоположения пользователя...');
      final geoLocator.Position? location = await Geolocator.getCurrentPosition(
        desiredAccuracy: geoLocator.LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      ).catchError((e) {
        print('Ошибка при получении точного местоположения: $e');
        // Fallback to last known position if high accuracy takes too long
        return Geolocator.getLastKnownPosition();
      });
      
      if (location != null) {
        print('Получено местоположение: ${location.latitude}, ${location.longitude}');
        userLocation.accept(
          geotypes.Position(
            location.longitude,
            location.latitude,
          ),
        );
        
        // Сохраняем координаты в SharedPreferences
        await inject<SharedPreferences>().setDouble('latitude', location.latitude);
        await inject<SharedPreferences>().setDouble('longitude', location.longitude);
        
        // Обновляем камеру если контроллер уже создан
        if (_mapboxMapController != null) {
          _updateMapCamera();
        }
      } else {
        print('Не удалось получить текущее местоположение, используем последние сохраненные координаты');
        
        // Пробуем загрузить координаты из SharedPreferences
        final prefs = inject<SharedPreferences>();
        final latitude = prefs.getDouble('latitude');
        final longitude = prefs.getDouble('longitude');
        
        if (latitude != null && longitude != null) {
          userLocation.accept(
            geotypes.Position(
              longitude,
              latitude,
            ),
          );
          print('Загружены координаты из SharedPreferences: $latitude, $longitude');
        } else {
          print('Сохраненных координат нет, используем координаты Актау по умолчанию');
        }
      }
    } catch (e) {
      print('Ошибка при инициализации местоположения: $e');
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
      // print('🔍 Начинаем determineLocationPermission...');
      
      // Сначала запрашиваем разрешения через LocationInteractor
      final permission = await inject<LocationInteractor>().requestLocation();
      // print('📍 Получены разрешения: $permission');
      
      // ВАЖНО: Обновляем состояние locationPermission!
      if (permission != null) {
        locationPermission.accept(permission);
        // print('✅ locationPermission обновлен: $permission');
      } else {
        // Если не удалось получить разрешения, устанавливаем denied
        locationPermission.accept(geoLocator.LocationPermission.denied);
        // print('❌ Устанавливаем locationPermission как denied');
        return; // Выходим если нет разрешений
      }
      
      // Проверяем что разрешения действительно получены
      if (![geoLocator.LocationPermission.always, geoLocator.LocationPermission.whileInUse].contains(permission)) {
        // print('❌ Недостаточные разрешения: $permission');
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
        
        // print('✅ Успешно получены и сохранены координаты: ${location.latitude}, ${location.longitude}');
        
        // ДОБАВЛЯЕМ: Обновляем камеру карты на новое местоположение
        await _updateMapCamera();
        
        // Убираем сообщение об успешном определении местоположения
        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Местоположение определено успешно'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        */
      } else {
        // print('⚠️ Не удалось получить координаты');
        // Попробуем использовать сохраненные координаты
        final savedLat = inject<SharedPreferences>().getDouble('latitude');
        final savedLng = inject<SharedPreferences>().getDouble('longitude');
        
        if (savedLat != null && savedLng != null && savedLat != 0 && savedLng != 0) {
          userLocation.accept(
            geotypes.Position(savedLng, savedLat),
          );
          // print('📌 Используем сохраненные координаты: $savedLat, $savedLng');
        } else {
          // print('🌍 Используем координаты Актау по умолчанию');
          // В случае если нет сохраненных координат, используем координаты Актау
          userLocation.accept(
            geotypes.Position(51.260834, 43.693695),
          );
        }
      }
    } catch (e) {
      // print('❌ Ошибка при получении геопозиции: $e');
      // В случае ошибки устанавливаем denied и дефолтные координаты
      locationPermission.accept(geoLocator.LocationPermission.denied);
      userLocation.accept(
        geotypes.Position(51.260834, 43.693695),
      );
    }
  }

  @override
  void tabIndexChanged(int newTabIndex) {
    // Keep this method for backward compatibility, but simplify its behavior
    // Since we no longer have tabs, just ensure the panel is visible
    ensurePanelVisible();
  }
  
  // New method: Ensure panel is at least at its minimum state
  void ensurePanelVisible() {
    // Make sure the panel is at least at minimum height
    if (draggableScrollableController.size < 0.35) {
      draggableScrollableController.animateTo(
        0.35,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // Add a method to expand the panel fully
  void expandPanel() {
    draggableScrollableController.animateTo(
      0.92,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    }
  
  // Add a method to collapse the panel
  void collapsePanel() {
    draggableScrollableController.animateTo(
      0.35,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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
    
    // Check if controller is attached before using it
    try {
      if (draggableScrollableController.isAttached) {
        draggableScrollableController.jumpTo(0.3);
      }
    } catch (e) {
      print('Error with draggableScrollableController: $e');
    }
    
    fetchActiveOrder();
  }

  Future<void> initializeSocket() async {
    try {
      // Проверяем, есть ли уже активное подключение
      if (newOrderSocket != null) {
        if (newOrderSocket!.connected) {
          // print('Сокет уже подключен, используем существующее соединение');
          return;
        } else {
          // Закрываем старое подключение перед созданием нового
          // print('Закрываем старое неактивное соединение перед созданием нового');
          newOrderSocket!.dispose();
          newOrderSocket = null;
        }
      }

      // Запрашиваем разрешения на геолокацию и обновляем местоположение
      await determineLocationPermission();

      // Проверяем наличие необходимых данных для подключения
      if (me.value == null || me.value!.id == null) {
        // print('Ошибка: нет данных пользователя для подключения сокета');
        return;
      }

      // print('Создаем новое соединение сокета для пользователя ${me.value!.id}');
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
          // print('Получено событие orderRejected: $data');
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
        // print('Получено событие orderStarted: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('driverArrived', (data) {
        // print('Получено событие driverArrived: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('rideStarted', (data) {
        // print('Получено событие rideStarted: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('rideEnded', (data) {
        // print('Получено событие rideEnded: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('orderAccepted', (data) {
        // print('Получено событие orderAccepted: $data');
        fetchActiveOrder();
      });

      newOrderSocket?.on('driverLocation', (data) {
        // print('Получено событие driverLocation');
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
        // print('Сокет отключен: $_, для tenant (клиента) переподключаемся автоматически');
        // Только для tenant (клиента) переподключаемся автоматически
        initializeSocket();
      });
      
      // Устанавливаем соединение
      newOrderSocket?.connect();
      // print('Сокет подключен для пользователя (tenant)');
    } on Exception catch (e) {
      // print('Ошибка при инициализации сокета: $e');
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

  @override
  Future<void> fetchActiveOrder() async {
    // print('Проверка наличия активного заказа...');
    try {
      final response = await model.getMyClientActiveOrder();
      
      // Проверяем наличие заказа
      if (response.order != null) {
        // print('Найден активный заказ: ${response.order!.id}');
        
        // Проверяем, завершен ли заказ и нужно ли его оценить
      if (response.order?.orderStatus == 'COMPLETED' &&
          response.order?.rating == null &&
          rateOpened.value == false) {
          // print('Заказ завершен, но не оценен. Показываем окно оценки.');
          
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
        
        // Если заказ не завершен - показываем его как активный
      if (response.order?.orderStatus != 'COMPLETED') {
        activeOrder.accept(response);
        } else {
          activeOrder.accept(null);
      }
      } else {
        // print('Активных заказов не найдено');
      activeOrder.accept(null);
      }
    } catch (e) {
      // print('Ошибка при проверке активного заказа: $e');
      activeOrder.accept(null);
    }
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
  
  @override
  void setRouteDisplayed(bool displayed) {
    isRouteDisplayed.accept(displayed);
  }
  
  @override
  void toggleMapFixed() async {
    isMapFixed.accept(!(isMapFixed.value ?? false));
    await _applyMapGestureSettings();
  }
  
  @override
  void setMapFixed(bool fixed) async {
    isMapFixed.accept(fixed);
    await _applyMapGestureSettings();
  }
  
  // Apply map gesture settings based on fixed state
  Future<void> _applyMapGestureSettings() async {
    if (_mapboxMapController == null) {
      print('Cannot apply map gesture settings: mapboxMapController is null');
      return;
    }
    
    try {
      final bool fixed = isMapFixed.value ?? false;
      
      // Configure gestures based on fixed state
      await _mapboxMapController!.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: !fixed,
          scrollEnabled: !fixed,
          pitchEnabled: !fixed,
          doubleTapToZoomInEnabled: !fixed,
          doubleTouchToZoomOutEnabled: !fixed,
          quickZoomEnabled: !fixed,
          pinchToZoomEnabled: !fixed,
        ),
      );
      
      print('Map gestures ${fixed ? 'disabled' : 'enabled'}');
    } catch (e) {
      print('Error applying map gesture settings: $e');
    }
  }

  @override
  Future<void> displayRouteOnMainMap(geotypes.Position fromPosition, geotypes.Position toPosition) async {
    try {
      print('Отображение маршрута на главной карте...');
      print('Координаты from: ${fromPosition.lat}, ${fromPosition.lng}');
      print('Координаты to: ${toPosition.lat}, ${toPosition.lng}');
      
      // Получаем маршрут из API Mapbox
      final mapboxApi = inject<MapboxApi>();
      final directions = await mapboxApi.getDirections(
        fromLat: fromPosition.lat.toDouble(),
        fromLng: fromPosition.lng.toDouble(),
        toLat: toPosition.lat.toDouble(),
        toLng: toPosition.lng.toDouble(),
      );
      
      if (directions == null) {
        print('Не удалось получить маршрут от API: directions is null');
        return;
      }
      
      // Удаляем существующие слои и источники маршрута
      await clearRoute();
      
      // Создаем GeoJSON LineString из геометрии маршрута
      if (!directions.containsKey('routes') || directions['routes'] == null || directions['routes'].isEmpty) {
        print('В ответе API нет маршрутов');
        return;
      }
      
      final routeGeometry = directions['routes'][0]['geometry'];
      print('Геометрия маршрута: ${routeGeometry.toString().substring(0, min(routeGeometry.toString().length, 100))}...');
      
      final lineString = {
        "type": "Feature",
        "geometry": routeGeometry,
        "properties": {}
      };
      
      // Конвертируем в JSON
      final jsonData = json.encode({
        "type": "FeatureCollection",
        "features": [lineString]
      });
      
      // Добавляем источник данных для маршрута
      await _mapboxMapController!.style.addSource(GeoJsonSource(
        id: 'main-route-source',
        data: jsonData,
      ));
      
      // Добавляем слой контура (белая граница для лучшей видимости)
      await _mapboxMapController!.style.addLayer(LineLayer(
        id: 'main-route-outline-layer',
        sourceId: 'main-route-source',
        lineColor: Colors.white.value,
        lineWidth: 8.0,
        lineOpacity: 0.9,
      ));
      
      // Добавляем основной слой линии маршрута
      await _mapboxMapController!.style.addLayer(LineLayer(
        id: 'main-route-layer',
        sourceId: 'main-route-source',
        lineColor: primaryColor.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
      
      // Добавляем маркеры для начальной и конечной точек
      try {
        // Создаем отдельные GeoJSON для маркеров A и B
        final markersJsonA = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [fromPosition.lng, fromPosition.lat]
              },
              "properties": {
                "icon": "point_a"
              }
            }
          ]
        };

        final markersJsonB = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [toPosition.lng, toPosition.lat]
              },
              "properties": {
                "icon": "point_b"
              }
            }
          ]
        };
        
        // Добавляем отдельные источники данных для маркеров
        await _mapboxMapController!.style.addSource(GeoJsonSource(
          id: 'main-markers-source-a',
          data: json.encode(markersJsonA),
        ));
        
        await _mapboxMapController!.style.addSource(GeoJsonSource(
          id: 'main-markers-source-b',
          data: json.encode(markersJsonB),
        ));
        
        // Добавляем слой для маркера A (меньший размер)
        await _mapboxMapController!.style.addLayer(SymbolLayer(
          id: 'main-markers-layer-a',
          sourceId: 'main-markers-source-a',
          iconImage: "point_a",
          iconSize: 0.3, // Уменьшаем размер маркера A
          iconAnchor: IconAnchor.BOTTOM,
          minZoom: 0, // Видно на любом масштабе
          maxZoom: 22, // Максимальный зум
          iconAllowOverlap: true, // Разрешаем перекрытие иконок
          symbolSortKey: 10, // Приоритет отображения
        ));
        
        // Добавляем слой для маркера B (стандартный размер)
        await _mapboxMapController!.style.addLayer(SymbolLayer(
          id: 'main-markers-layer-b',
          sourceId: 'main-markers-source-b',
          iconImage: "point_b",
          iconSize: 0.3, // Уменьшаем размер маркера B
          iconAnchor: IconAnchor.BOTTOM,
          minZoom: 0, // Видно на любом масштабе
          maxZoom: 22, // Максимальный зум
          iconAllowOverlap: true, // Разрешаем перекрытие иконок
          symbolSortKey: 11, // Приоритет отображения
        ));
      } catch (e) {
        print('Ошибка при добавлении маркеров: $e');
      }
      
      // Подстраиваем камеру для отображения всего маршрута
      final bounds = directions['routes'][0]['bounds'];
      if (bounds != null) {
        final southwest = bounds[0];
        final northeast = bounds[1];
        
        final camera = await _mapboxMapController!.cameraForCoordinateBounds(
          CoordinateBounds(
            southwest: Point(coordinates: geotypes.Position(southwest[0], southwest[1])),
            northeast: Point(coordinates: geotypes.Position(northeast[0], northeast[1])),
            infiniteBounds: false
          ),
          MbxEdgeInsets(top: 150, left: 50, bottom: 350, right: 50),
          null, // bearing
          null, // pitch
          null, // maxZoom
          null, // minZoom
        );
        
        await _mapboxMapController!.flyTo(
          camera,
          MapAnimationOptions(duration: 1000),
        );
      }
      
      // Блокируем взаимодействие с картой, если включен режим фиксации
      if (isMapFixed.value == true) {
        await _applyMapGestureSettings();
      }
      
      // Обновляем состояние отображения маршрута
      setRouteDisplayed(true);
      
    } catch (e) {
      print('Ошибка при отображении маршрута: $e');
    }
  }

  @override
  Future<void> clearRoute() async {
    if (_mapboxMapController == null) {
      print('Cannot clear route: mapboxMapController is null');
      return;
    }
    
    try {
      print('Clearing route from map...');
      
      // Remove existing route layers and sources
      for (final layerId in ['main-route-layer', 'main-route-outline-layer', 'main-markers-layer', 'main-markers-layer-a', 'main-markers-layer-b']) {
        if (await _mapboxMapController!.style.styleLayerExists(layerId)) {
          await _mapboxMapController!.style.removeStyleLayer(layerId);
          print('Removed layer $layerId');
        }
      }
      
      for (final sourceId in ['main-route-source', 'main-markers-source', 'main-markers-source-a', 'main-markers-source-b']) {
        if (await _mapboxMapController!.style.styleSourceExists(sourceId)) {
          await _mapboxMapController!.style.removeStyleSource(sourceId);
          print('Removed source $sourceId');
        }
      }
      
      isRouteDisplayed.accept(false);
      isMapFixed.accept(false);
      
      // Применяем настройки взаимодействия с картой
      await _applyMapGestureSettings();
      
      print('Route cleared successfully');
    } catch (e) {
      print('Error clearing route: $e');
    }
  }

  @override
  Future<void> createDriverOrder(DriverOrderForm form) async {
    try {
      print('Создание заказа с данными: ${form.toString()}');
      
      // Сохраняем адреса для будущего использования
      saveOrderAddresses(
        fromAddress: form.fromAddress.value ?? '',
        toAddress: form.toAddress.value ?? '',
        fromMapboxId: form.fromMapboxId.value ?? '',
        toMapboxId: form.toMapboxId.value ?? '',
      );
      
      // Определяем тип заказа на основе текущей вкладки
      final orderType = currentTab.value == 0 ? DriverType.TAXI : DriverType.INTERCITY_TAXI;
      
      // Отправляем заказ на сервер
      await onSubmit(form, orderType);
      
      // Обновляем состояние активного заказа
      await fetchActiveOrder();
    } catch (e) {
      print('Ошибка при создании заказа: $e');
      rethrow; // Передаем ошибку дальше для обработки в UI
    }
  }

  @override
  void saveOrderAddresses({
    required String fromAddress,
    required String toAddress,
    required String fromMapboxId,
    required String toMapboxId,
  }) {
    print('Сохранение адресов заказа:');
    print('fromAddress: $fromAddress');
    print('toAddress: $toAddress');
    print('fromMapboxId: $fromMapboxId');
    print('toMapboxId: $toMapboxId');
    
    // Validate addresses - if empty, use default text
    final validFromAddress = fromAddress.isNotEmpty ? fromAddress : "Выберите адрес отправления";
    final validToAddress = toAddress.isNotEmpty ? toAddress : "Выберите адрес прибытия";
    
    // ТОЛЬКО сохраняем в StateNotifier для использования в текущей сессии
    savedFromAddress.accept(validFromAddress);
    savedToAddress.accept(validToAddress);
    savedFromMapboxId.accept(fromMapboxId);
    savedToMapboxId.accept(toMapboxId);
    
    print('Адреса обновлены в StateNotifier (только для текущей сессии):');
    print('savedFromAddress: ${savedFromAddress.value}');
    print('savedToAddress: ${savedToAddress.value}');
    
    // НЕ СОХРАНЯЕМ в SharedPreferences - поля должны быть пустыми после перезапуска
    
    // Если есть оба адреса и координаты - отображаем маршрут на главной карте
    if (fromMapboxId.isNotEmpty && toMapboxId.isNotEmpty && _mapboxMapController != null) {
      try {
        final fromParts = fromMapboxId.split(';');
        final toParts = toMapboxId.split(';');
        
        if (fromParts.length >= 2 && toParts.length >= 2) {
          final fromLat = double.tryParse(fromParts[0]);
          final fromLng = double.tryParse(fromParts[1]);
          final toLat = double.tryParse(toParts[0]);
          final toLng = double.tryParse(toParts[1]);
          
          if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
            print('Отображаем маршрут между точками на главной карте');
            
            // Автоматически фиксируем карту когда оба адреса заданы
            setMapFixed(true);
            
            // Отображаем маршрут
            displayRouteOnMainMap(
              geotypes.Position(fromLng, fromLat),
              geotypes.Position(toLng, toLat),
            );
          }
        }
      } catch (e) {
        print('Ошибка при отображении маршрута после сохранения адресов: $e');
      }
    }
  }

  // Загрузка сохраненных адресов из SharedPreferences
  Future<void> _loadSavedAddresses() async {
    try {
      // Проверяем, не установлены ли уже адреса (например, из map picker)
      final hasFromAddress = savedFromAddress.value != null && savedFromAddress.value!.isNotEmpty;
      final hasToAddress = savedToAddress.value != null && savedToAddress.value!.isNotEmpty;
      
      if (hasFromAddress && hasToAddress) {
        print('Адреса уже установлены, пропускаем загрузку из SharedPreferences');
        return;
      }
      
      final prefs = inject<SharedPreferences>();
      final fromAddress = prefs.getString('saved_from_address');
      final toAddress = prefs.getString('saved_to_address');
      final fromMapboxId = prefs.getString('saved_from_mapbox_id');
      final toMapboxId = prefs.getString('saved_to_mapbox_id');
      
      // Загружаем адреса только если они еще не установлены
      if (!hasFromAddress && fromAddress != null && fromAddress.isNotEmpty) {
        savedFromAddress.accept(fromAddress);
        print('Загружен fromAddress: $fromAddress');
      }
      
      if (!hasToAddress && toAddress != null && toAddress.isNotEmpty) {
        savedToAddress.accept(toAddress);
        print('Загружен toAddress: $toAddress');
      }
      
      if (fromMapboxId != null && fromMapboxId.isNotEmpty) {
        savedFromMapboxId.accept(fromMapboxId);
        print('Загружен fromMapboxId: $fromMapboxId');
      }
      
      if (toMapboxId != null && toMapboxId.isNotEmpty) {
        savedToMapboxId.accept(toMapboxId);
        print('Загружен toMapboxId: $toMapboxId');
      }
      
      print('Загружены сохраненные адреса:');
      print('fromAddress: $fromAddress');
      print('toAddress: $toAddress');
      print('fromMapboxId: $fromMapboxId');
      print('toMapboxId: $toMapboxId');
      
      // Если оба адреса и координаты загружены успешно, отображаем маршрут
      if (fromMapboxId != null && toMapboxId != null && 
          fromMapboxId.isNotEmpty && toMapboxId.isNotEmpty) {
        final fromParts = fromMapboxId.split(';');
        final toParts = toMapboxId.split(';');
        
        if (fromParts.length >= 2 && toParts.length >= 2) {
          final fromLat = double.tryParse(fromParts[0]);
          final fromLng = double.tryParse(fromParts[1]);
          final toLat = double.tryParse(toParts[0]);
          final toLng = double.tryParse(toParts[1]);
          
          if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
            print('Планируем отображение маршрута между сохраненными точками');
            // Планируем отображение маршрута, но только после инициализации карты
            _scheduleRouteDisplay(
              geotypes.Position(fromLng, fromLat),
              geotypes.Position(toLng, toLat),
            );
          }
        }
      }
    } catch (e) {
      print('Ошибка при загрузке сохраненных адресов: $e');
    }
  }
  
  // Планирует отображение маршрута после инициализации карты
  void _scheduleRouteDisplay(geotypes.Position fromPos, geotypes.Position toPos) {
    // Проверяем каждые 100мс, инициализирована ли карта
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_mapboxMapController != null) {
        timer.cancel(); // Останавливаем проверку
        print('Карта инициализирована, отображаем маршрут');
        displayRouteOnMainMap(fromPos, toPos);
      } else {
        print('Ожидаем инициализации карты...');
      }
    });
  }

  // Автоматически определяем текущий адрес "откуда" по GPS
  Future<void> _initializeCurrentLocationAddress() async {
    try {
      print('Начинаем автоматическое определение адреса "откуда"...');
      
      // Ждем получения местоположения с увеличенным количеством попыток
      var attempts = 0;
      while (userLocation.value == null && attempts < 20) {
        print('Ожидание местоположения, попытка $attempts');
        await Future.delayed(Duration(milliseconds: 250));
        attempts++;
      }
      
      if (userLocation.value == null) {
        print('Не удалось получить местоположение для определения адреса, используем координаты по умолчанию');
        // Устанавливаем адрес по умолчанию если не удалось получить GPS
        savedFromAddress.accept('Текущее местоположение');
        savedFromMapboxId.accept('43.693695;51.260834'); // Координаты Актау
        return;
      }
      
      final position = userLocation.value!;
      print('Определяем адрес для позиции: ${position.lat}, ${position.lng}');
      
      // Получаем адрес по координатам через ваш собственный API
      final restClient = inject<RestClient>();
      final addressData = await restClient.getPlaceDetail(
        latitude: position.lat.toDouble(),
        longitude: position.lng.toDouble(),
      );
      
      if (addressData != null && addressData.isNotEmpty && addressData != "Адрес не найден") {
        final placeName = addressData;
        
        print('Автоматически определен адрес "откуда": $placeName');
        
        // Устанавливаем адрес "откуда" и его координаты
        savedFromAddress.accept(placeName);
        savedFromMapboxId.accept('${position.lat};${position.lng}');
        
        print('Адрес "откуда" автоматически установлен: $placeName');
        
        // Принудительно обновляем UI
        _forceUIUpdate();
      } else {
        print('Не удалось получить адрес от API или получен пустой ответ');
        // Устанавливаем базовый адрес
        savedFromAddress.accept('Текущее местоположение');
        savedFromMapboxId.accept('${position.lat};${position.lng}');
        
        // Принудительно обновляем UI
        _forceUIUpdate();
      }
    } catch (e) {
      print('Ошибка при определении адреса: $e');
      // В случае ошибки устанавливаем базовый адрес
      if (userLocation.value != null) {
        savedFromAddress.accept('Текущее местоположение');
        savedFromMapboxId.accept('${userLocation.value!.lat};${userLocation.value!.lng}');
      } else {
        savedFromAddress.accept('Текущее местоположение');
        savedFromMapboxId.accept('43.693695;51.260834'); // Координаты Актау по умолчанию
      }
      
      // Принудительно обновляем UI
      _forceUIUpdate();
    }
  }
  
  // Принудительное обновление UI
  void _forceUIUpdate() {
    // Принудительно уведомляем UI об изменении адресов
    Future.delayed(Duration(milliseconds: 50), () {
      if (savedFromAddress.value != null) {
        final currentFrom = savedFromAddress.value!;
        savedFromAddress.accept(currentFrom);
        print('Принудительно обновляем fromAddress в UI: $currentFrom');
      }
    });
    
    // Дополнительное обновление
    Future.delayed(Duration(milliseconds: 200), () {
      if (savedFromAddress.value != null) {
        savedFromAddress.accept(savedFromAddress.value!);
        print('UI принудительно обновлен (второй раз)');
      }
    });
  }

  // Принудительно обновить адреса в UI (публичный метод для использования в UI)
  @override
  void forceUpdateAddresses() {
    _forceUIUpdate();
    
    // Дополнительно обновляем адрес "куда" если он есть
    if (savedToAddress.value != null) {
      Future.delayed(Duration(milliseconds: 50), () {
        final currentTo = savedToAddress.value!;
        savedToAddress.accept(currentTo);
        print('Принудительно обновляем toAddress: $currentTo');
      });
    }
    
    print('UI принудительно обновлен с текущими адресами');
  }
}
