import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:geolocator/geolocator.dart';
import 'package:geotypes/geotypes.dart' as geotypes;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:dio/dio.dart';

import '../../core/colors.dart';
import '../../core/images.dart';
import '../../core/text_styles.dart';
import '../../interactors/order_requests_interactor.dart';
import '../../interactors/common/mapbox_api/mapbox_api.dart';
import '../../interactors/main_navigation_interactor.dart';
import '../../utils/text_editing_controller.dart';
import '../../domains/food/food_category_domain.dart';
import '../../domains/food/food_domain.dart';
import '../../domains/food/foods_response_domain.dart';
import '../../domains/user/user_domain.dart';
import '../../interactors/common/rest_client.dart';
import '../../interactors/food_interactor.dart';
import '../../models/active_client_request/active_client_request_model.dart';
import '../../models/order_request/order_request_props_model.dart';
import '../../models/order_request/order_request_client_model.dart';
import '../../utils/logger.dart';
import '../../utils/utils.dart';
import '../widgets/primary_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/rounded_text_field.dart';
import './forms/driver_order_form.dart';
import './tenant_home_model.dart';
import './tenant_home_screen.dart';
import '../../interactors/location_interactor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/network_utils.dart';
import '../../services/websocket_service.dart';

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

  Future<void> fetchActiveOrder();

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
  
  // Состояния блокировки пользователя
  StateNotifier<bool> get isUserBlocked;
  StateNotifier<String?> get userBlockReason;
  StateNotifier<DateTime?> get userBlockedUntil;
}

class TenantHomeWM extends WidgetModel<TenantHomeScreen, TenantHomeModel>
    with SingleTickerProviderWidgetModelMixin, WidgetsBindingObserver
    implements ITenantHomeWM {
  TenantHomeWM(
    TenantHomeModel model,
  ) : super(model);

  
  // Добавляем MapboxMapController для управления картой
  MapboxMap? _mapboxMapController;

  // Кэш для маршрутов
  final Map<String, Map<String, dynamic>> _routeCache = {};
  String? _lastRouteKey;

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
  final StateNotifier<bool> isUserBlocked = StateNotifier(initValue: false);
  
  @override
  final StateNotifier<String?> userBlockReason = StateNotifier();
  
  @override
  final StateNotifier<DateTime?> userBlockedUntil = StateNotifier();

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    
    print('🔄 КЛИЕНТ: Инициализация TenantHomeWM...');
    
    // Добавляем lifecycle observer для отслеживания состояния приложения
    WidgetsBinding.instance.addObserver(this);
    
    // Добавляем слушатель для отладки изменений activeOrder
    activeOrder.addListener(() {
      final order = activeOrder.value;
      if (order != null) {
        print('✅ КЛИЕНТ: activeOrder изменился - статус: ${order.order?.orderStatus}, ID: ${order.order?.id}');
      } else {
        print('❌ КЛИЕНТ: activeOrder стал null');
      }
    });
    
    // Добавляем обработку ошибок сокета
    try {
      final websocketService = WebSocketService();
      websocketService.addClientConnectionListener((isConnected) {
        if (isConnected) {
          print('✅ КЛИЕНТ: WebSocket подключен');
        } else {
          print('❌ КЛИЕНТ: WebSocket отключен');
        }
      });
    } catch (socketError) {
      print('❌ КЛИЕНТ: Ошибка инициализации WebSocket: $socketError');
    }
    
    // Важно: сначала получаем профиль пользователя
    fetchUserProfile().then((_) {
      print('✅ КЛИЕНТ: Профиль пользователя загружен, запрашиваем активный заказ...');
      // Инициализация сокета делается внутри fetchUserProfile(),
      // здесь только запрашиваем активный заказ
      fetchActiveOrder();
      
      // Дополнительный вызов через небольшую задержку для надежности
      Future.delayed(Duration(seconds: 2), () {
        print('🔄 КЛИЕНТ: Повторный запрос активного заказа через 2 секунды...');
        fetchActiveOrder();
      });
    });
    
    // Загружаем категории и еду в параллели
    fetchFoods();
    
    // ИЗМЕНЕНО: Сначала очищаем адреса, затем инициализируем
    _clearSavedAddressesOnStartup().then((_) {
      // ТОЛЬКО ПОСЛЕ очистки запускаем инициализацию
    _initializeLocationAndAddress();
    });
    
    // Настриваем слушатель для draggableScrollableController
    draggableScrollableController.addListener(() {
      draggableScrolledSize.accept(draggableScrollableController.size);
    });
    
    // УПРОЩАЕМ: Убираем лишний слушатель изменения местоположения
    // Оставляем только базовое отслеживание без автоматических обновлений адреса
    Geolocator.getPositionStream(
      locationSettings: geoLocator.LocationSettings(
        accuracy: geoLocator.LocationAccuracy.high,
        distanceFilter: 100, // Обновляем только при перемещении на 100+ метров
      ),
    ).listen((geoLocator.Position position) {
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
      // Устанавливаем максимальный размер
      draggableMaxChildSize.accept(1.0);

      // Не читаем size до тех пор, пока контроллер не будет привязан к листу —
      // иначе выбрасывается AssertionError «DraggableScrollableController is not attached».
      try {
        // Метод size безопасен, только если контроллер уже привязан
        // (после первой отрисовки DraggableScrollableSheet).
        if ((draggableScrollableController as dynamic).attached == true ||
            (draggableScrollableController as dynamic).hasClients == true) {
      draggableScrolledSize.accept(draggableScrollableController.size);
        }
      } catch (_) {
        // Игнорируем: контроллер ещё не привязан, значение обновится через listener
      }
    });
  }
  
  // РЕФАКТОР: Упрощенная последовательная инициализация
  Future<void> _initializeLocationAndAddress() async {
    try {
      print('🚀 Инициализация местоположения и адреса...');
      
      // ВАЖНО: Первым делом очищаем состояние адресов
      savedFromAddress.accept('');
      savedToAddress.accept('');
      savedFromMapboxId.accept('');
      savedToMapboxId.accept('');
      print('🗑️ Состояние адресов очищено');
      
      // ЭТАП 1: Поле "куда" остается пустым
      print('🏷️ Поле "куда" остается пустым при старте приложения');
      
      // ЭТАП 2: Ждем получения реального местоположения пользователя
      print('📍 Ожидание получения реального местоположения пользователя...');
      
      // Получаем реальные координаты пользователя (без дефолтных координат)
      final location = await inject<LocationInteractor>().getCurrentLocation();
      
      if (location != null) {
        userLocation.accept(geotypes.Position(location.longitude, location.latitude));
        print('✅ Реальные координаты получены: ${location.latitude}, ${location.longitude}');
        
        // ТОЛЬКО ПОСЛЕ получения реальных координат определяем адрес
        await _determineAddressFromRealLocation(location.latitude, location.longitude);
          } else {
        print('⚠️ Не удалось получить реальное местоположение пользователя');
        // НЕ устанавливаем дефолтный адрес - оставляем пустым
        print('💡 Адрес "откуда" останется пустым до получения геолокации');
          }
      
      print('✅ Инициализация завершена');
    } catch (e) {
      print('❌ Ошибка инициализации: $e');
      // НЕ устанавливаем fallback адрес - пусть пользователь сам выберет
      print('💡 Пользователь может выбрать адрес вручную');
    }
  }

  // Загрузка координат из SharedPreferences
  Future<void> _loadLocationFromPreferences() async {
    try {
        final prefs = inject<SharedPreferences>();
        final latitude = prefs.getDouble('latitude');
        final longitude = prefs.getDouble('longitude');
        
      if (latitude != null && longitude != null && latitude != 0 && longitude != 0) {
        userLocation.accept(geotypes.Position(longitude, latitude));
        print('✅ Координаты загружены из памяти: $latitude, $longitude');
        } else {
        // Используем координаты Актау по умолчанию
        userLocation.accept(geotypes.Position(51.260834, 43.693695));
        print('✅ Используем координаты Актау по умолчанию');
        }
    } catch (e) {
      print('❌ Ошибка загрузки координат: $e');
      userLocation.accept(geotypes.Position(51.260834, 43.693695));
    }
  }

  // Установка fallback адреса
  void _setFallbackAddress() {
    savedFromAddress.accept('Текущее местоположение');
    if (userLocation.value != null) {
      savedFromMapboxId.accept('${userLocation.value!.lat};${userLocation.value!.lng}');
    } else {
      savedFromMapboxId.accept('43.693695;51.260834');
    }
  }
        
  // Загружаем все сохраненные адреса из SharedPreferences
  Future<void> _loadSavedAddresses() async {
    try {
        final prefs = inject<SharedPreferences>();
      
      // Загружаем адрес "откуда"
      final savedFromAddr = prefs.getString('saved_from_address');
      final savedFromCoords = prefs.getString('saved_from_coords');
      
      if (savedFromAddr != null && savedFromAddr.isNotEmpty && savedFromAddr != "Адрес не найден") {
        savedFromAddress.accept(savedFromAddr);
        if (savedFromCoords != null && savedFromCoords.isNotEmpty) {
          savedFromMapboxId.accept(savedFromCoords);
        }
        print('📍 Загружен сохраненный адрес "откуда": $savedFromAddr');
      }
      
      // Загружаем адрес "куда" 
      final savedToAddr = prefs.getString('saved_to_address');
      final savedToCoords = prefs.getString('saved_to_coords');
      
      if (savedToAddr != null && savedToAddr.isNotEmpty && savedToAddr != "Адрес не найден") {
        savedToAddress.accept(savedToAddr);
        if (savedToCoords != null && savedToCoords.isNotEmpty) {
          savedToMapboxId.accept(savedToCoords);
        }
        print('📍 Загружен сохраненный адрес "куда": $savedToAddr');
      }
      
    } catch (e) {
      print('❌ Ошибка загрузки сохраненных адресов: $e');
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
        
        print('✅ Успешно получены и сохранены координаты: ${location.latitude}, ${location.longitude}');
        
        // ДОБАВЛЯЕМ: Автоматическое перемещение карты к пользователю после получения геопозиции
        await _moveMapToUserLocation();
        
        // Определяем адрес из реальной геолокации пользователя
        await _determineAddressFromRealLocation(location.latitude, location.longitude);
        
      } else {
        // print('⚠️ Не удалось получить координаты');
        // Попробуем использовать сохраненные координаты
        final savedLat = inject<SharedPreferences>().getDouble('latitude');
        final savedLng = inject<SharedPreferences>().getDouble('longitude');
        
        if (savedLat != null && savedLng != null && savedLat != 0 && savedLng != 0) {
          userLocation.accept(
            geotypes.Position(savedLng, savedLat),
          );
          print('📌 Используем сохраненные координаты: $savedLat, $savedLng');
          
          // ДОБАВЛЯЕМ: Перемещение карты к сохраненным координатам если нет текущих
          await _moveMapToUserLocation();
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

  // Новый метод для перемещения карты к местоположению пользователя
  Future<void> _moveMapToUserLocation() async {
    if (_mapboxMapController != null && userLocation.value != null) {
      try {
        await _mapboxMapController!.flyTo(
          CameraOptions(
            center: Point(coordinates: userLocation.value!),
            zoom: 16.0,
          ),
          MapAnimationOptions(duration: 1500),
        );
        print('🗺️ Карта автоматически перемещена к геопозиции пользователя');
      } catch (e) {
        print('❌ Ошибка при перемещении карты к пользователю: $e');
      }
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

    final result = await NetworkUtils.executeWithErrorHandling<FoodsResponseDomain>(
      () => model.fetchFoods(),
      customErrorMessage: 'Не удалось загрузить меню',
    );
    
    if (result != null) {
      foodCategories.accept(result.folders);
      foods.content(result.items);
    } else {
      foods.error(Exception('Не удалось загрузить меню'));
    }
  }

  Future<void> fetchUserProfile() async {
    final result = await NetworkUtils.executeWithErrorHandling<UserDomain>(
      () => model.getUserProfile(),
      showErrorMessages: false, // Не показываем ошибки для автоматических запросов профиля
    );

    if (result != null) {
      me.accept(result);
    initializeSocket();
    }
  }

  @override
  Future<void> onSubmit(DriverOrderForm form, DriverType taxi) async {
    print('🚀 КЛИЕНТ: Создание заказа...');
    print('📋 КЛИЕНТ: Данные формы:');
    print('📍 КЛИЕНТ: Откуда: ${form.fromAddress.value}');
    print('📍 КЛИЕНТ: Куда: ${form.toAddress.value}');
    print('💰 КЛИЕНТ: Стоимость: ${form.cost.value}');
    
    try {
      await NetworkUtils.executeWithErrorHandling<void>(
        () => inject<RestClient>().createDriverOrder(body: {
        "from": form.fromAddress.value,
        "to": form.toAddress.value,
        "lng": userLocation.value?.lng,
        "lat": userLocation.value?.lat,
        "price": form.cost.value,
          "orderType": "TAXI",
        "comment": '${form.comment};${form.fromMapboxId.value};${form.toMapboxId.value}',
        "fromMapboxId": form.fromMapboxId.value,
        "toMapboxId": form.toMapboxId.value,
        }),
        customErrorMessage: 'Не удалось создать заказ',
      );
      
      print('✅ КЛИЕНТ: Заказ успешно создан');
      
      // Check if controller is attached before using it
      try {
        if (draggableScrollableController.isAttached) {
          draggableScrollableController.jumpTo(0.3);
          print('✅ КЛИЕНТ: DraggableScrollableController перемещен в позицию 0.3');
        }
      } catch (e) {
        print('❌ КЛИЕНТ: Ошибка с draggableScrollableController: $e');
      }
      
      // Добавляем задержку перед запросом активного заказа
      print('⏱️ КЛИЕНТ: Ожидаем 1 секунду перед запросом активного заказа...');
      await Future.delayed(Duration(seconds: 1));
      
      print('🔄 КЛИЕНТ: Запрашиваем активный заказ после создания...');
      await fetchActiveOrder();
      
      // Проверяем, что заказ получен
      print('🔍 КЛИЕНТ: Проверка активного заказа после создания: ${activeOrder.value != null ? "получен" : "не получен"}');
      
      // Если заказ не получен, пробуем еще раз через 2 секунды
      if (activeOrder.value == null) {
        print('⏱️ КЛИЕНТ: Заказ не получен, повторная попытка через 2 секунды...');
        await Future.delayed(Duration(seconds: 2));
        await fetchActiveOrder();
        print('🔍 КЛИЕНТ: Повторная проверка: ${activeOrder.value != null ? "получен" : "не получен"}');
      }
    } catch (e) {
      print('❌ КЛИЕНТ: Ошибка при создании заказа: $e');
    }
  }

  Future<void> initializeSocket() async {
    try {
      // Запрашиваем разрешения на геолокацию и обновляем местоположение
      await determineLocationPermission();

      // Проверяем наличие необходимых данных для подключения
      if (me.value == null || me.value!.id == null) {
        logger.e('❌ КЛИЕНТ: Нет данных пользователя для подключения сокета');
        return;
      }

      logger.i('🔌 КЛИЕНТ: Инициализация WebSocket через WebSocketService...');
      
      // Используем централизованный WebSocketService
      final websocketService = WebSocketService();
      
      // Проверяем, не подключен ли уже сокет
      if (websocketService.isClientConnected) {
        logger.i('✅ КЛИЕНТ: WebSocket уже подключен, пропускаем инициализацию');
        return;
      }
      
      // Очищаем все старые обработчики событий (предотвращаем утечки памяти)
      _clearAllEventListeners(websocketService);
      
      // Настраиваем обработчики событий с использованием единого метода
      _setupOrderStatusEventListeners(websocketService);
      
      // Инициализируем подключение
      await websocketService.initializeConnection(
        type: SocketConnectionType.client,
        user: me.value!,
      );
      
      logger.i('🔌 КЛИЕНТ: WebSocket инициализирован через WebSocketService');
      
    } catch (e) {
      logger.e('❌ КЛИЕНТ: Ошибка инициализации WebSocket: $e');
      print('❌ КЛИЕНТ: Ошибка инициализации WebSocket: $e');
    }
  }

  @override
  void dispose() {
    // Отключаем сокет при уничтожении виджета
    print('Отключаем сокет в dispose');
    disconnectWebsocket();
    
    // Удаляем lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('🔄 App lifecycle изменился: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Приложение вернулось на передний план
        print('✅ Приложение возобновлено - синхронизируем состояние заказа');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        // Приложение ушло в фон
        print('⏸️ Приложение приостановлено');
        break;
      case AppLifecycleState.inactive:
        // Приложение неактивно (переходное состояние)
        break;
      case AppLifecycleState.detached:
        // Приложение отсоединено
        break;
      case AppLifecycleState.hidden:
        // Приложение скрыто
        break;
    }
  }

  /// Обрабатывает возврат приложения на передний план
  Future<void> _handleAppResumed() async {
    try {
      print('🔄 КЛИЕНТ: Приложение вернулось на передний план, начинаем синхронизацию...');
      
      // 1. Проверяем подключение к интернету
      final hasInternet = await NetworkUtils.hasInternetConnection();
      if (!hasInternet) {
        print('❌ КЛИЕНТ: Нет подключения к интернету при возврате в приложение');
        return;
      }
      print('✅ КЛИЕНТ: Подключение к интернету доступно');

      // 2. Синхронизируем активный заказ
      print('🔄 КЛИЕНТ: Синхронизация активного заказа...');
      await fetchActiveOrder();
      print('✅ КЛИЕНТ: Активный заказ синхронизирован: ${activeOrder.value != null ? "заказ найден" : "заказа нет"}');

      // 3. Переподключаем WebSocket если он отключен
      final websocketService = WebSocketService();
      if (!websocketService.isClientConnected && me.value != null) {
        print('🔄 КЛИЕНТ: Переподключение WebSocket после возврата в приложение...');
        await initializeSocket();
        print('✅ КЛИЕНТ: WebSocket переподключен');
      } else {
        print('ℹ️ КЛИЕНТ: WebSocket уже подключен или пользователь не авторизован');
      }

      // 4. Обновляем местоположение
      if (locationPermission.value == geoLocator.LocationPermission.always ||
          locationPermission.value == geoLocator.LocationPermission.whileInUse) {
        print('🔄 КЛИЕНТ: Обновление местоположения...');
        await _updateMapCamera();
        print('✅ КЛИЕНТ: Местоположение обновлено');
      } else {
        print('ℹ️ КЛИЕНТ: Нет разрешения на доступ к геолокации');
      }

      // 5. Повторная проверка активного заказа через 2 секунды
      await Future.delayed(Duration(seconds: 2));
      print('🔄 КЛИЕНТ: Повторная проверка активного заказа...');
      await fetchActiveOrder();
      print('✅ КЛИЕНТ: Повторная проверка завершена: ${activeOrder.value != null ? "заказ найден" : "заказа нет"}');

      print('✅ КЛИЕНТ: Синхронизация при возврате в приложение завершена');
    } catch (e) {
      print('❌ КЛИЕНТ: Ошибка при синхронизации после возврата в приложение: $e');
    }
  }

  // Очистка всех обработчиков событий (предотвращение утечек памяти)
  void _clearAllEventListeners(WebSocketService websocketService) {
    websocketService.clearEventListeners(SocketEventType.orderAccepted);
    websocketService.clearEventListeners(SocketEventType.orderRejected);
    websocketService.clearEventListeners(SocketEventType.orderCancelledByClient);
    websocketService.clearEventListeners(SocketEventType.orderStarted);
    websocketService.clearEventListeners(SocketEventType.driverArrived);
    websocketService.clearEventListeners(SocketEventType.rideStarted);
    websocketService.clearEventListeners(SocketEventType.rideEnded);
    websocketService.clearEventListeners(SocketEventType.driverLocation);
  }
  
  // Настройка обработчиков событий для статусов заказа
  void _setupOrderStatusEventListeners(WebSocketService websocketService) {
    // Обработчик события принятия заказа водителем
    websocketService.addEventListener(SocketEventType.orderAccepted, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие orderAccepted');
      print('📦 КЛИЕНТ: Получено событие orderAccepted: $data');
      _handleOrderStatusChange('orderAccepted', data);
    });
    
    // Обработчик события отклонения заказа
    websocketService.addEventListener(SocketEventType.orderRejected, (data) async {
      logger.i('📦 КЛИЕНТ: Получено событие orderRejected');
      print('📦 КЛИЕНТ: Получено событие orderRejected: $data');
      isOrderRejected.accept(true);
      await _showOrderRejectedBottomSheet();
      fetchActiveOrder();
    });
    
    // Обработчик события отмены заказа клиентом
    websocketService.addEventListener(SocketEventType.orderCancelledByClient, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие orderCancelledByClient');
      print('📦 КЛИЕНТ: Получено событие orderCancelledByClient: $data');
      _handleOrderStatusChange('orderCancelledByClient', data);
    });
    
    // Обработчик события начала поездки
    websocketService.addEventListener(SocketEventType.orderStarted, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие orderStarted');
      print('📦 КЛИЕНТ: Получено событие orderStarted: $data');
      _handleOrderStatusChange('orderStarted', data);
    });
    
    // Обработчик события прибытия водителя
    websocketService.addEventListener(SocketEventType.driverArrived, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие driverArrived');
      print('📦 КЛИЕНТ: Получено событие driverArrived: $data');
      _handleOrderStatusChange('driverArrived', data);
    });
    
    // Обработчик события начала поездки
    websocketService.addEventListener(SocketEventType.rideStarted, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие rideStarted');
      print('📦 КЛИЕНТ: Получено событие rideStarted: $data');
      _handleOrderStatusChange('rideStarted', data);
    });
    
    // Обработчик события завершения поездки
    websocketService.addEventListener(SocketEventType.rideEnded, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие rideEnded');
      print('📦 КЛИЕНТ: Получено событие rideEnded: $data');
      _handleRideEnded(data);
    });
    
    // Обработчик события обновления местоположения водителя
    websocketService.addEventListener(SocketEventType.driverLocation, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие driverLocation');
      print('📦 КЛИЕНТ: Получено событие driverLocation: $data');
      
      // Обновляем позицию водителя
      geotypes.Position point;
      if (data['lat'] is String) {
        point = geotypes.Position(double.tryParse(data['lng']) ?? 0, double.tryParse(data['lat']) ?? 0);
      } else {
        point = geotypes.Position(data['lng'], data['lat']);
      }
      driverLocation.accept(point);
      
      // ВАЖНО: Проверяем статус заказа из driverLocation
      final orderStatus = data['orderStatus'] as String?;
      if (orderStatus != null) {
        print('📊 КЛИЕНТ: Получен статус заказа из driverLocation: $orderStatus');
        
        // Если статус изменился на STARTED (водитель принял заказ), обновляем UI
        if (orderStatus == 'STARTED') {
          print('✅ КЛИЕНТ: Водитель принял заказ (статус STARTED), обновляем UI');
          _handleOrderStatusChange('orderAccepted', data);
        }
        // Если статус изменился на WAITING (водитель на месте), обновляем UI
        else if (orderStatus == 'WAITING') {
          print('✅ КЛИЕНТ: Водитель на месте (статус WAITING), обновляем UI');
          _handleOrderStatusChange('driverArrived', data);
        }
        // Если статус изменился на ONGOING (поездка началась), обновляем UI
        else if (orderStatus == 'ONGOING') {
          print('✅ КЛИЕНТ: Поездка началась (статус ONGOING), обновляем UI');
          _handleOrderStatusChange('rideStarted', data);
        }
        // Если статус изменился на COMPLETED (поездка завершена), обновляем UI
        else if (orderStatus == 'COMPLETED') {
          print('✅ КЛИЕНТ: Поездка завершена (статус COMPLETED), обновляем UI');
          _handleRideEnded(data);
        }
      }
    });
    
    // Обработчик события синхронизации активного заказа
    websocketService.addEventListener(SocketEventType.orderSync, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие orderSync');
      print('📦 КЛИЕНТ: Получено событие orderSync: $data');
      _handleOrderSync(data);
    });
    
    // Обработчик события информации о водителе
    websocketService.addEventListener(SocketEventType.driverInfo, (data) {
      logger.i('📦 КЛИЕНТ: Получено событие driverInfo');
      print('📦 КЛИЕНТ: Получено событие driverInfo: $data');
      _handleDriverInfo(data);
    });

    // Настраиваем обработчики подключения
    websocketService.addClientConnectionListener((isConnected) {
      if (isConnected) {
        logger.i('WebSocket подключение установлено');
      } else {
        logger.w('WebSocket отключен');
      }
    });
  }
  
  // Обработка изменения статуса заказа
  void _handleOrderStatusChange(String eventType, Map<String, dynamic> data) {
    print('🔄 КЛИЕНТ: Обработка изменения статуса заказа: $eventType');
    
    // Добавляем небольшую задержку перед первым обновлением
    Future.delayed(Duration(milliseconds: 100), () {
      print('🔄 КЛИЕНТ: Первое обновление активного заказа (100ms)');
      _fetchActiveOrderInternal(forceUpdate: true);
    });
    
    // Повторное обновление для надежности
    Future.delayed(Duration(milliseconds: 500), () {
      print('🔄 КЛИЕНТ: Повторное обновление активного заказа (500ms)');
      _fetchActiveOrderInternal(forceUpdate: true);
    });
  }
  
  // Специальная обработка завершения поездки
  void _handleRideEnded(Map<String, dynamic> data) {
    print('🏁 КЛИЕНТ: Обработка завершения поездки');
    
    // Сначала очищаем активный заказ
    print('🔄 КЛИЕНТ: Очищаем активный заказ');
    activeOrder.accept(null);
    
    // Затем запрашиваем актуальные данные
    Future.delayed(Duration(milliseconds: 200), () {
      print('🔄 КЛИЕНТ: Запрашиваем актуальные данные после завершения поездки');
      _fetchActiveOrderInternal(forceUpdate: true);
    });
    
    // Дополнительная проверка через 1 секунду
    Future.delayed(Duration(seconds: 1), () {
      print('🔄 КЛИЕНТ: Финальная проверка активного заказа');
      _fetchActiveOrderInternal(forceUpdate: true);
    });
  }
  
  // Обработка синхронизации активного заказа
  void _handleOrderSync(Map<String, dynamic> data) {
    print('🔄 КЛИЕНТ: Обработка синхронизации активного заказа');
    print('📋 КЛИЕНТ: Данные синхронизации: $data');
    
    final orderStatus = data['orderStatus'] as String?;
    final orderId = data['orderId'] as String?;
    final driverId = data['driverId'] as String?;
    
    if (orderStatus != null && orderId != null) {
      print('✅ КЛИЕНТ: Синхронизирован активный заказ $orderId со статусом $orderStatus');
      
      // Принудительно обновляем активный заказ
      _fetchActiveOrderInternal(forceUpdate: true);
      
      // Дополнительно обновляем через небольшую задержку для надежности
      Future.delayed(Duration(milliseconds: 500), () {
        _fetchActiveOrderInternal(forceUpdate: true);
      });
    } else {
      print('❌ КЛИЕНТ: Неполные данные синхронизации');
    }
  }
  
  // Обработка информации о водителе
  void _handleDriverInfo(Map<String, dynamic> data) {
    print('🚕 КЛИЕНТ: Получена информация о водителе');
    print('📋 КЛИЕНТ: Данные водителя: $data');
    
    final driverId = data['driverId'] as String?;
    final driver = data['driver'] as Map<String, dynamic>?;
    
    if (driverId != null && driver != null) {
      print('✅ КЛИЕНТ: Информация о водителе $driverId получена');
      // Здесь можно сохранить информацию о водителе для отображения в UI
    } else {
      print('❌ КЛИЕНТ: Неполная информация о водителе');
    }
  }
  
  // Показать модальное окно с сообщением об отклонении заказа
  Future<void> _showOrderRejectedBottomSheet() async {
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
  }

  Future<void> disconnectWebsocket() async {
    print('Отключаем сокет клиента через WebSocketService');
    try {
      final websocketService = WebSocketService();
      
      // Очищаем все обработчики событий перед отключением
      _clearAllEventListeners(websocketService);
      
      await websocketService.disconnectClient();
    } catch (e) {
      print('Ошибка при отключении сокета: $e');
    }
  }

  @override
  Future<void> fetchActiveOrder() async {
    await _fetchActiveOrderInternal(forceUpdate: false);
  }
  
  // Внутренний метод с возможностью принудительного обновления
  Future<void> _fetchActiveOrderInternal({bool forceUpdate = false}) async {
    try {
      print('🔄 КЛИЕНТ: Запрос активного заказа...');
      logger.i('Запрос активного заказа');
      
      // Проверяем наличие токена и данных пользователя
      final token = inject<SharedPreferences>().getString('access_token');
      if (token == null || me.value == null) {
        print('❌ КЛИЕНТ: Нет токена или данных пользователя');
        logger.w('Невозможно получить активный заказ: отсутствует токен или данные пользователя');
        return;
      }
      
      print('✅ КЛИЕНТ: Токен и данные пользователя есть, делаем запрос...');
      
      // Получаем активный заказ с обработкой ошибок
      final result = await NetworkUtils.executeWithErrorHandling<ActiveClientRequestModel>(
        () => model.getMyClientActiveOrder(),
        showErrorMessages: false, // Не показываем ошибки для автоматических запросов
      );
      
      print('📋 КЛИЕНТ: Результат запроса: ${result != null ? "получен" : "null"}');
      
      if (result != null) {
        print('✅ КЛИЕНТ: Получен активный заказ:');
        print('📋 КЛИЕНТ: Статус: ${result.order?.orderStatus}');
        print('🆔 КЛИЕНТ: ID: ${result.order?.id}');
        print('🚕 КЛИЕНТ: Водитель: ${result.driver != null ? "назначен" : "не назначен"}');
        print('🚗 КЛИЕНТ: Автомобиль: ${result.car != null ? "указан" : "не указан"}');
        print('📍 КЛИЕНТ: Маршрут: ${result.order?.from} -> ${result.order?.to}');
        
        logger.i('Получен активный заказ: ${result.order?.orderStatus}');
        
        // Проверяем, изменился ли заказ
        final currentOrder = activeOrder.value;
        final orderChanged = _hasOrderChanged(currentOrder, result);
        
        print('🔄 КЛИЕНТ: Заказ изменился: $orderChanged');
        print('📊 КЛИЕНТ: Текущий статус: ${currentOrder?.order?.orderStatus}');
        print('📊 КЛИЕНТ: Новый статус: ${result.order?.orderStatus}');
        
        // Обновляем только если заказ изменился или его не было, или принудительное обновление
        if (orderChanged || forceUpdate) {
          print('✅ КЛИЕНТ: Заказ изменился или принудительное обновление, обновляем UI');
          logger.i('Заказ изменился или принудительное обновление, обновляем UI');
          activeOrder.accept(result);
        } else {
          print('ℹ️ КЛИЕНТ: Заказ не изменился, UI не обновляем');
        }
      } else {
        print('❌ КЛИЕНТ: Активный заказ не найден (result == null)');
        // Если result == null, это может означать что заказа нет или была ошибка
        // Очищаем activeOrder только если он был не null (чтобы избежать лишних обновлений UI)
        if (activeOrder.value != null) {
          print('🔄 КЛИЕНТ: Очищаем состояние (был заказ, теперь нет)');
          logger.i('Активный заказ не найден, очищаем состояние');
          activeOrder.accept(null);
        } else {
          print('ℹ️ КЛИЕНТ: Состояние уже пустое, ничего не делаем');
        }
      }
    } catch (e) {
      print('❌ КЛИЕНТ: Ошибка при получении активного заказа: $e');
      logger.e('Ошибка при получении активного заказа: $e');
      // При ошибке очищаем состояние только если заказ был
      if (activeOrder.value != null) {
        print('🔄 КЛИЕНТ: Очищаем состояние из-за ошибки');
        activeOrder.accept(null);
      }
    }
  }
  
  // Проверяет, изменился ли заказ
  bool _hasOrderChanged(ActiveClientRequestModel? current, ActiveClientRequestModel? newOrder) {
    // Если один из заказов null, а другой нет - заказ изменился
    if (current == null && newOrder != null) return true;
    if (current != null && newOrder == null) return true;
    if (current == null && newOrder == null) return false;
    
    // Проверяем изменение основных параметров
    if (current!.order?.id != newOrder!.order?.id) return true;
    if (current.order?.orderStatus != newOrder.order?.orderStatus) return true;
    if (current.driver?.props?.phone != newOrder.driver?.props?.phone) return true;
    
    return false;
  }

  @override
  void cancelActiveClientOrder() async {
    if (activeOrder.value?.order?.id == null) return;
    
    try {
      await NetworkUtils.executeWithErrorHandling<void>(
        () => model.rejectOrderByClientRequest(
          orderRequestId: activeOrder.value!.order!.id!,
        ),
        customErrorMessage: 'Не удалось отменить заказ',
      );
      
      // Если отмена прошла успешно (нет исключения)
      // Очищаем активный заказ
      activeOrder.accept(null);
      
      // КРИТИЧЕСКИ ВАЖНО: Очищаем все маршруты и состояние карты при отмене заказа
      await clearRoute();
      print('🧹 Все маршруты очищены после отмены заказа');
      
      // Закрываем окно поиска водителя
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Показываем уведомление об отмене
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Поиск водителя отменен'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Если произошла ошибка, ничего не делаем - NetworkUtils уже показал ошибку
      print('Ошибка при отмене заказа: $e');
    }
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
  
  // Метод для обновления камеры карты (ТОЛЬКО по явному запросу пользователя)
  Future<void> _updateMapCamera() async {
    // ИСПРАВЛЯЕМ: НЕ обновляем камеру если маршрут отображается или карта зафиксирована
    if (isRouteDisplayed.value == true || isMapFixed.value == true) {
      print('Камера НЕ обновлена: маршрут отображается или карта зафиксирована');
      return;
    }
    
    if (_mapboxMapController != null && userLocation.value != null) {
      try {
        await _mapboxMapController!.flyTo(
          CameraOptions(
            center: Point(coordinates: userLocation.value!),
            zoom: 16.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
        print('Камера карты обновлена на текущее местоположение по запросу пользователя');
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
    final wasFixed = isMapFixed.value ?? false;
    isMapFixed.accept(fixed);
    
    // Применяем настройки только если состояние изменилось
    if (wasFixed != fixed) {
    await _applyMapGestureSettings();
      print(fixed ? '🔒 Карта заблокирована для просмотра маршрута' : '🔓 Карта разблокирована для свободного использования');
    }
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
      
      // АВТОМАТИЧЕСКИ блокируем карту при построении маршрута
      setMapFixed(true);
      
      // Создаем уникальный ключ для маршрута
      final routeKey = '${fromPosition.lat.toStringAsFixed(6)},${fromPosition.lng.toStringAsFixed(6)}-${toPosition.lat.toStringAsFixed(6)},${toPosition.lng.toStringAsFixed(6)}';
      
      // Проверяем кэш маршрутов
      Map<String, dynamic>? directions;
      if (_routeCache.containsKey(routeKey)) {
        print('📦 Используем кэшированный маршрут для $routeKey');
        directions = _routeCache[routeKey];
      } else {
        // Получаем маршрут из API Mapbox только если нет в кэше
        print('🌐 Запрашиваем новый маршрут от Mapbox API...');
      final mapboxApi = inject<MapboxApi>();
        directions = await mapboxApi.getDirections(
        fromLat: fromPosition.lat.toDouble(),
        fromLng: fromPosition.lng.toDouble(),
        toLat: toPosition.lat.toDouble(),
        toLng: toPosition.lng.toDouble(),
      );
        
        if (directions != null) {
          // Сохраняем в кэш
          _routeCache[routeKey] = directions;
          print('💾 Маршрут сохранен в кэш');
          
          // Ограничиваем размер кэша (максимум 10 маршрутов)
          if (_routeCache.length > 10) {
            final oldestKey = _routeCache.keys.first;
            _routeCache.remove(oldestKey);
            print('🧹 Удален старый маршрут из кэша: $oldestKey');
          }
        }
      }
      
      if (directions == null) {
        print('Не удалось получить маршрут от API: directions is null');
        // Разблокируем карту если маршрут не удалось построить
        setMapFixed(false);
        return;
      }
      
      // Если это тот же маршрут что уже отображается, не обновляем
      if (_lastRouteKey == routeKey) {
        print('🔄 Тот же маршрут уже отображается, пропускаем обновление');
        return;
      }
      
      _lastRouteKey = routeKey;
      
      // Удаляем существующие слои и источники маршрута
      await clearRoute();
      
      // Проверяем наличие маршрутов в ответе API
      if (!directions.containsKey('routes') || directions['routes'] == null || directions['routes'].isEmpty) {
        print('В ответе API нет маршрутов');
        setMapFixed(false);
        return;
      }
      
      // НОВАЯ ЛОГИКА: Отображаем маршрут с цветами пробок
      final routeData = directions['routes'][0];
      final routeGeometry = routeData['geometry'];
      final legs = routeData['legs'] as List?;
      
      print('Геометрия маршрута: ${routeGeometry.toString().substring(0, min(routeGeometry.toString().length, 100))}...');
      
      // Добавляем источник данных для маршрута
      await _mapboxMapController!.style.addSource(GeoJsonSource(
        id: 'main-route-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [{
            "type": "Feature",
            "geometry": routeGeometry,
            "properties": {}
          }]
        }),
      ));
      
      // Создаем слои для разных уровней пробок
      await _addTrafficAwareLayers();
      
      // Если есть детализированная информация о сегментах, используем её
      if (legs != null && legs.isNotEmpty) {
        await _addTrafficSegments(legs);
      } else {
        // Базовое отображение маршрута с цветом по умолчанию (зеленый - без пробок)
        await _addBasicRouteLayers();
      }
      
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
      
      // ИДЕАЛЬНОЕ отображение маршрута: подстраиваем камеру с оптимальными отступами
      final bounds = directions['routes'][0]['bounds'];
      if (bounds != null) {
        final southwest = bounds[0];
        final northeast = bounds[1];
        
        // Оптимальные отступы для отображения маршрута на весь экран
        final camera = await _mapboxMapController!.cameraForCoordinateBounds(
          CoordinateBounds(
            southwest: Point(coordinates: geotypes.Position(southwest[0], southwest[1])),
            northeast: Point(coordinates: geotypes.Position(northeast[0], northeast[1])),
            infiniteBounds: false
          ),
          MbxEdgeInsets(
            top: 80,     // Минимальный отступ сверху
            left: 40,    // Отступ слева
            bottom: 120, // Минимальный отступ снизу для панели
            right: 40,   // Отступ справа
          ),
          null, // bearing
          null, // pitch
          null, // maxZoom
          null, // minZoom
        );
        
        await _mapboxMapController!.flyTo(
          camera,
          MapAnimationOptions(duration: 1200), // Плавная анимация 1.2 сек
        );
        
        print('📷 Камера идеально настроена для отображения маршрута');
      }
      
      // БЛОКИРУЕМ карту для лучшего UX при просмотре маршрута
        await _applyMapGestureSettings();
      
      // Обновляем состояние отображения маршрута
      setRouteDisplayed(true);
      
      print('✅ Маршрут отображен с заблокированной картой для идеального просмотра');
      
    } catch (e) {
      print('Ошибка при отображении маршрута: $e');
      // В случае ошибки разблокируем карту
      setMapFixed(false);
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
      
      // Очищаем кэш текущего маршрута
      _lastRouteKey = null;
      print('🧹 Очищен кэш текущего маршрута');
      
      // КОМПЛЕКСНАЯ ОЧИСТКА: Remove все возможные слои маршрутов
      final layersToRemove = [
        // Основные слои маршрута
        'main-route-layer', 
        'main-route-outline-layer', 
        'main-markers-layer', 
        'main-markers-layer-a', 
        'main-markers-layer-b',
        // Динамические слои
        'dynamic-route-layer',
        'dynamic-route-outline-layer',
        // Общие слои маршрутов
        'route-layer',
        'route-outline-layer',
        // Слои маркеров водителя
        'client-driver-marker-layer'
      ];
      
      final sourcesToRemove = [
        // Основные источники
        'main-route-source', 
        'main-markers-source', 
        'main-markers-source-a', 
        'main-markers-source-b',
        // Динамические источники
        'dynamic-route-source',
        // Общие источники
        'route-source',
        // Источники маркеров водителя
        'client-driver-marker-source'
      ];
      
      // Также удаляем слои сегментов пробок (проверяем популярные индексы)
      for (int legIndex = 0; legIndex < 5; legIndex++) {
        for (int stepIndex = 0; stepIndex < 20; stepIndex++) {
          final segmentId = 'route-segment-$legIndex-$stepIndex';
          layersToRemove.add(segmentId);
          sourcesToRemove.add('$segmentId-source');
        }
      }
      
      for (final layerId in layersToRemove) {
        try {
        if (await _mapboxMapController!.style.styleLayerExists(layerId)) {
          await _mapboxMapController!.style.removeStyleLayer(layerId);
          print('Removed layer $layerId');
          }
        } catch (e) {
          // Игнорируем ошибки - слой может не существовать
        }
      }
      
      for (final sourceId in sourcesToRemove) {
        try {
        if (await _mapboxMapController!.style.styleSourceExists(sourceId)) {
          await _mapboxMapController!.style.removeStyleSource(sourceId);
          print('Removed source $sourceId');
          }
        } catch (e) {
          // Игнорируем ошибки - источник может не существовать
        }
      }
      
      // ВАЖНО: Очищаем также состояние позиции водителя
      driverLocation.accept(null);
      print('🧹 Позиция водителя очищена');
      
      // АВТОМАТИЧЕСКИ разблокируем карту и сбрасываем состояния
      isRouteDisplayed.accept(false);
      setMapFixed(false); // Это автоматически применит настройки через _applyMapGestureSettings
      
      print('✅ Маршрут очищен и карта разблокирована для свободного использования');
    } catch (e) {
      print('Error clearing route: $e');
    }
  }

  @override
  Future<void> createDriverOrder(DriverOrderForm form) async {
    // Проверяем блокировку пользователя перед созданием заказа
    if (isUserBlocked.value == true) {
      final reason = userBlockReason.value ?? 'Причина не указана';
      final blockedUntil = userBlockedUntil.value;
      NetworkUtils.showUserBlockedMessage(reason, blockedUntil);
      return;
    }

    // Сразу создаем временный заказ в UI для мгновенного отображения
    final temporaryOrder = ActiveClientRequestModel(
      order: OrderRequestClientModel(
        id: "temp_${DateTime.now().millisecondsSinceEpoch}",
        orderStatus: 'CREATED',
        from: form.fromAddress.value,
        to: form.toAddress.value,
        price: form.cost.value?.toInt(),
        orderType: "TAXI",
        fromMapboxId: form.fromMapboxId.value,
        toMapboxId: form.toMapboxId.value,
        comment: '',
      ),
      // Водитель пока не назначен
      driver: null,
      car: null,
    );
    
    // Обновляем UI с временным заказом
    activeOrder.accept(temporaryOrder);

    try {
      await inject<RestClient>().createDriverOrder(body: {
        "from": form.fromAddress.value,
        "to": form.toAddress.value,
        "lng": userLocation.value?.lng,
        "lat": userLocation.value?.lat,
        "price": form.cost.value,
        "orderType": "TAXI",
        "comment": '${form.comment};${form.fromMapboxId.value};${form.toMapboxId.value}',
        "fromMapboxId": form.fromMapboxId.value,
        "toMapboxId": form.toMapboxId.value,
      });
      
      // Получаем актуальный заказ с сервера
      await Future.delayed(Duration(milliseconds: 500)); // Небольшая задержка для обработки заказа на сервере
      await fetchActiveOrder();
      
      // Если по какой-то причине заказ не получен с сервера, оставляем временный
      if (activeOrder.value == null) {
        activeOrder.accept(temporaryOrder);
      }
    } catch (error) {
      // При ошибке сохраняем временный заказ
      activeOrder.accept(temporaryOrder);
      
      // Специальная обработка ошибки блокировки пользователя
      if (error is DioException && 
          error.response?.statusCode == 403 &&
          error.response?.data != null &&
          error.response?.data['message'] == 'Ваш аккаунт заблокирован. Создание заказов недоступно.') {
        
        // Обновляем состояние блокировки
        final String reason = error.response?.data['reason'] ?? 'Причина не указана';
        final String? blockedUntilStr = error.response?.data['blockedUntil'];
        DateTime? blockedUntil;
        
        if (blockedUntilStr != null) {
          try {
            blockedUntil = DateTime.parse(blockedUntilStr);
          } catch (e) {
            print('Error parsing blockedUntil date: $e');
          }
        }
        
        // Обновляем состояние
        isUserBlocked.accept(true);
        userBlockReason.accept(reason);
        userBlockedUntil.accept(blockedUntil);
        
        // Показываем детальную информацию о блокировке
        NetworkUtils.showUserBlockedMessage(reason, blockedUntil);
      } else {
        // Обычная обработка других ошибок
        NetworkUtils.handleNetworkError(error);
      }
    }
  }

  @override
  void saveOrderAddresses({
    required String fromAddress,
    required String toAddress,
    required String fromMapboxId,
    required String toMapboxId,
  }) {
    print('🔄 Сохранение адресов заказа...');
    
    // РЕФАКТОР: МГНОВЕННОЕ обновление UI без задержек
    final validFromAddress = fromAddress.isNotEmpty ? fromAddress : "Выберите адрес отправления";
    final validToAddress = toAddress.isNotEmpty ? toAddress : "Выберите адрес прибытия";
    
    // Проверяем изменение координат для оптимизации маршрута
    final coordinatesChanged = (savedFromMapboxId.value != fromMapboxId || 
                               savedToMapboxId.value != toMapboxId);
    
    // МГНОВЕННО обновляем состояние
    savedFromAddress.accept(validFromAddress);
    savedToAddress.accept(validToAddress);
    savedFromMapboxId.accept(fromMapboxId);
    savedToMapboxId.accept(toMapboxId);
    
    print('✅ Адреса мгновенно обновлены в UI');
    
    // Асинхронно сохраняем в SharedPreferences
    _saveAddressesToPreferences(validFromAddress, validToAddress, fromMapboxId, toMapboxId);
    
    // Отображаем маршрут только при изменении координат
    if (coordinatesChanged && fromMapboxId.isNotEmpty && toMapboxId.isNotEmpty) {
      _displayRouteIfNeeded(fromMapboxId, toMapboxId);
    }
  }

  // РЕФАКТОР: Упрощенное отображение маршрута
  void _displayRouteIfNeeded(String fromMapboxId, String toMapboxId) {
      try {
        print('🔍 Анализ координат для маршрута:');
        print('  📍 fromMapboxId: "$fromMapboxId"');
        print('  📍 toMapboxId: "$toMapboxId"');
        
        final fromParts = fromMapboxId.split(';');
        final toParts = toMapboxId.split(';');
        
        print('  📍 fromParts: $fromParts');
        print('  📍 toParts: $toParts');
        
        if (fromParts.length >= 2 && toParts.length >= 2) {
          final fromLat = double.tryParse(fromParts[0]);
          final fromLng = double.tryParse(fromParts[1]);
          final toLat = double.tryParse(toParts[0]);
          final toLng = double.tryParse(toParts[1]);
          
          print('  🧭 Координаты FROM: lat=$fromLat, lng=$fromLng');
          print('  🧭 Координаты TO: lat=$toLat, lng=$toLng');
          
          if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
            // Проверяем что координаты действительно разные
            final distance = _calculateDistance(fromLat, fromLng, toLat, toLng);
            print('  📏 Расстояние между точками: ${distance.toStringAsFixed(2)} м');
            
            if (distance < 10) {
              print('  ⚠️ Точки слишком близко друг к другу (${distance.toStringAsFixed(2)} м)');
              print('  ⚠️ Возможно, координаты назначения не обновились правильно');
              return;
            }
            
            print('🗺️ Отображаем маршрут на карте с автоматической блокировкой');
            
            // Отображаем маршрут (блокировка карты происходит автоматически)
            displayRouteOnMainMap(
              geotypes.Position(fromLng, fromLat),
              geotypes.Position(toLng, toLat),
            );
          } else {
            print('  ❌ Не удалось распарсить координаты');
          }
        } else {
          print('  ❌ Неправильный формат координат');
        }
      } catch (e) {
        print('❌ Ошибка отображения маршрута: $e');
      }
  }
  
  // Вспомогательный метод для вычисления расстояния между двумя точками
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Радиус Земли в метрах
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // РЕФАКТОР: Сохранение в SharedPreferences во время сессии
  Future<void> _saveAddressesToPreferences(String fromAddress, String toAddress, String fromMapboxId, String toMapboxId) async {
    try {
      final prefs = inject<SharedPreferences>();
      
      // ВОССТАНОВЛЕНО: Сохраняем адреса во время сессии
      // Они будут очищены только при следующем запуске приложения
      
      // Сохраняем только валидные адреса
      if (_isValidAddress(fromAddress)) {
        await prefs.setString('saved_from_address', fromAddress);
        if (fromMapboxId.isNotEmpty) {
          await prefs.setString('saved_from_coords', fromMapboxId);
        }
        print('💾 Адрес "откуда" сохранен для текущей сессии: $fromAddress');
      }
      
      if (_isValidAddress(toAddress)) {
        await prefs.setString('saved_to_address', toAddress);
        if (toMapboxId.isNotEmpty) {
          await prefs.setString('saved_to_coords', toMapboxId);
        }
        print('💾 Адрес "куда" сохранен для текущей сессии: $toAddress');
      }
      
      print('ℹ️ Адреса будут очищены при следующем запуске приложения');
      
    } catch (e) {
      print('❌ Ошибка сохранения адресов: $e');
    }
  }
  
  // Проверка валидности адреса
  bool _isValidAddress(String address) {
    return address.isNotEmpty && 
           address != "Выберите адрес отправления" && 
           address != "Выберите адрес прибытия" && 
           address != "Адрес не найден" &&
           address != "Определение местоположения...";
  }

  // UI теперь использует StateNotifierBuilder и обновляется автоматически
  // Метод forceUpdateAddresses больше не нужен
  @override
  void forceUpdateAddresses() {
    // Оставляем пустым - UI обновляется автоматически через StateNotifierBuilder
    print('⚡ UI обновляется автоматически через StateNotifierBuilder');
  }

  // НОВЫЕ МЕТОДЫ: Создание слоев маршрута с цветами пробок
  
  // Создает базовые слои для отображения маршрута с учетом пробок
  Future<void> _addTrafficAwareLayers() async {
    try {
      // Слой контура (белая граница для лучшей видимости)
      await _mapboxMapController!.style.addLayer(LineLayer(
        id: 'main-route-outline-layer',
        sourceId: 'main-route-source',
        lineColor: Colors.white.value,
        lineWidth: 8.0,
        lineOpacity: 0.9,
      ));
      
      print('✅ Базовые слои маршрута созданы');
    } catch (e) {
      print('❌ Ошибка создания базовых слоев: $e');
      }
  }

  // Добавляет детализированные сегменты с информацией о пробках
  Future<void> _addTrafficSegments(List legs) async {
    try {
      print('🚦 Анализируем данные о пробках...');
      int segmentCount = 0;
      int freeSegments = 0;
      int moderateSegments = 0;
      int heavySegments = 0;
      
      for (int legIndex = 0; legIndex < legs.length; legIndex++) {
        final leg = legs[legIndex];
        final steps = leg['steps'] as List?;
        
        if (steps != null) {
          for (int stepIndex = 0; stepIndex < steps.length; stepIndex++) {
            final step = steps[stepIndex];
            final duration = (step['duration'] as num?)?.toDouble();
            final distance = (step['distance'] as num?)?.toDouble();
            final geometry = step['geometry'];
            
            if (duration != null && distance != null && geometry != null && duration > 0) {
              // Вычисляем уровень пробок на основе скорости
              final speed = distance / duration; // м/с
              final speedKmh = speed * 3.6; // км/ч
              
              // Проверяем на валидность скорости
              if (speedKmh.isFinite && speedKmh > 0) {
                final trafficLevel = _calculateTrafficLevel(speedKmh);
                final color = _getTrafficColor(trafficLevel);
              
              // Счетчики для статистики
              segmentCount++;
              switch (trafficLevel) {
                case 'free':
                  freeSegments++;
                  break;
                case 'moderate':
                  moderateSegments++;
                  break;
                case 'heavy':
                  heavySegments++;
                  break;
              }
              
              // Создаем отдельный слой для каждого сегмента
              final segmentId = 'route-segment-${legIndex}-${stepIndex}';
              
              await _mapboxMapController!.style.addSource(GeoJsonSource(
                id: '${segmentId}-source',
                data: json.encode({
                  "type": "FeatureCollection",
                  "features": [{
                    "type": "Feature",
                    "geometry": geometry,
                    "properties": {
                      "traffic_level": trafficLevel,
                      "speed_kmh": speedKmh.round(),
                      "distance_m": distance.round()
                    }
                  }]
                }),
              ));
              
                await _mapboxMapController!.style.addLayer(LineLayer(
                  id: segmentId,
                  sourceId: '${segmentId}-source',
                  lineColor: color.value,
                  lineWidth: 5.0,
                  lineOpacity: 0.9,
                ));
              } else {
                // Пропускаем сегменты с невалидной скоростью
                print('⚠️ Пропущен сегмент с невалидной скоростью: $speedKmh км/ч');
              }
            }
          }
        }
      }
      
      print('🚦 Статистика пробок:');
      print('  📊 Всего сегментов: $segmentCount');
      print('  🟢 Свободная дорога: $freeSegments');
      print('  🟠 Средние пробки: $moderateSegments');
      print('  🔴 Сильные пробки: $heavySegments');
      print('✅ Сегменты с пробками добавлены');
    } catch (e) {
      print('❌ Ошибка добавления сегментов пробок: $e');
      // В случае ошибки используем базовое отображение
      await _addBasicRouteLayers();
    }
  }
  
  // Добавляет базовые слои маршрута без детализации пробок
  Future<void> _addBasicRouteLayers() async {
    try {
      // Основной слой маршрута (зеленый - предполагаем свободную дорогу)
      await _mapboxMapController!.style.addLayer(LineLayer(
        id: 'main-route-layer',
        sourceId: 'main-route-source',
        lineColor: Colors.green.value, // Зеленый для свободной дороги
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
      
      print('✅ Базовый маршрут отображен зеленым цветом');
    } catch (e) {
      print('❌ Ошибка добавления базового маршрута: $e');
    }
  }
  
  // Вычисляет уровень пробок на основе скорости
  String _calculateTrafficLevel(double speedKmh) {
    if (speedKmh >= 50) {
      return 'free'; // Свободная дорога
    } else if (speedKmh >= 25) {
      return 'moderate'; // Средние пробки
      } else {
      return 'heavy'; // Сильные пробки
      }
  }
  
  // Возвращает цвет в зависимости от уровня пробок
  Color _getTrafficColor(String trafficLevel) {
    switch (trafficLevel) {
      case 'free':
        return Colors.green; // Зеленый - свободная дорога
      case 'moderate':
        return Colors.orange; // Оранжевый - средние пробки
      case 'heavy':
        return Colors.red; // Красный - сильные пробки
      default:
        return primaryColor; // Базовый цвет как fallback
    }
  }

  // НОВЫЙ МЕТОД: Очистка сохраненных адресов только при старте приложения
  Future<void> _clearSavedAddressesOnStartup() async {
    try {
      final prefs = inject<SharedPreferences>();
    
      // Очищаем сохраненные адреса
      await prefs.remove('saved_from_address');
      await prefs.remove('saved_to_address');
      await prefs.remove('saved_from_coords');
      await prefs.remove('saved_to_coords');
      
      print('🗑️ Сохраненные адреса очищены при старте приложения');
      print('💡 Поле "откуда" будет определено по текущему местоположению, поле "куда" будет пустым');
    } catch (e) {
      print('❌ Ошибка при очистке сохраненных адресов: $e');
    }
  }

  @override
  Future<void> _determineAddressFromRealLocation(double latitude, double longitude) async {
    try {
      print('🔍 Определение адреса по реальному местоположению...');
      
      // Показываем индикатор загрузки
      savedFromAddress.accept('Определение местоположения...');
      
      // Получаем адрес с бэка
      final restClient = inject<RestClient>();
      final addressData = await restClient.getPlaceDetail(
        latitude: latitude,
        longitude: longitude,
      ).timeout(Duration(seconds: 5));
      
      if (addressData != null && addressData.isNotEmpty && addressData != "Адрес не найден") {
        print('✅ Получен адрес с бэка: $addressData');
        
        // МГНОВЕННО обновляем UI
        savedFromAddress.accept(addressData);
        savedFromMapboxId.accept('${latitude};${longitude}');
        
        // ВОССТАНОВЛЕНО: Сохраняем адрес для текущей сессии
        // Будет очищен при следующем запуске приложения
        final prefs = inject<SharedPreferences>();
        await prefs.setString('saved_from_address', addressData);
        await prefs.setString('saved_from_coords', '${latitude};${longitude}');
        print('💾 Адрес сохранен для текущей сессии (будет очищен при перезапуске)');
      } else {
        print('⚠️ Адрес не найден');
        savedFromAddress.accept('Текущее местоположение');
        savedFromMapboxId.accept('${latitude};${longitude}');
      }
    } catch (e) {
      print('❌ Ошибка определения адреса: $e');
        savedFromAddress.accept('Текущее местоположение');
      if (userLocation.value != null) {
        savedFromMapboxId.accept('${userLocation.value!.lat};${userLocation.value!.lng}');
      }
    }
  }
}
