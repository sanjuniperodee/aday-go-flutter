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

import '../../core/colors.dart';
import '../../core/images.dart';
import '../../core/text_styles.dart';
import '../../interactors/order_requests_interactor.dart';
import '../../interactors/common/mapbox_api/mapbox_api.dart';
import '../../interactors/main_navigation_interactor.dart';
import '../../utils/text_editing_controller.dart';
import '../../domains/food/food_category_domain.dart';
import '../../domains/food/food_domain.dart';
import '../../domains/user/user_domain.dart';
import '../../interactors/common/rest_client.dart';
import '../../interactors/food_interactor.dart';
import '../../models/active_client_request/active_client_request_model.dart';
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
      draggableMaxChildSize.accept(1.0);
      draggableScrolledSize.accept(draggableScrollableController.size);
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
      
      // ИЗМЕНЕНО: НЕ загружаем сохраненные адреса при старте
      // Поле "куда" всегда должно быть пустым, а "откуда" - текущее местоположение
      // await _loadSavedAddresses(); // УБРАНО
      
      // ЭТАП 1: Поле "куда" остается пустым
      print('🏷️ Поле "куда" остается пустым при старте приложения');
      
      // ЭТАП 2: Параллельно получаем координаты и определяем адрес "откуда"
      await Future.wait([
        _getCurrentLocationQuickly(), // Быстрое получение координат (3 сек макс)
        _determineAddressFromLocation(), // Определение адреса по координатам (5 сек макс)
      ]);
      
      print('✅ Инициализация завершена - откуда: ${savedFromAddress.value}, куда: пусто');
    } catch (e) {
      print('❌ Ошибка инициализации: $e');
      // Устанавливаем fallback адрес только для "откуда"
      _setFallbackAddress();
    }
  }

  // РЕФАКТОР: Быстрое получение текущих координат
  Future<void> _getCurrentLocationQuickly() async {
    try {
      print('📍 Получение координат...');
      
      // Сначала пробуем получить последнее известное местоположение (быстро)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        userLocation.accept(geotypes.Position(lastKnown.longitude, lastKnown.latitude));
        print('✅ Координаты из кэша: ${lastKnown.latitude}, ${lastKnown.longitude}');
      }
      
      // Затем получаем текущие координаты с коротким таймаутом
      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: geoLocator.LocationSettings(
            accuracy: geoLocator.LocationAccuracy.high,
            timeLimit: Duration(seconds: 3),
          ),
        );
        
        userLocation.accept(geotypes.Position(current.longitude, current.latitude));
        print('✅ Актуальные координаты: ${current.latitude}, ${current.longitude}');
        
        // Сохраняем в SharedPreferences
        final prefs = inject<SharedPreferences>();
        await prefs.setDouble('latitude', current.latitude);
        await prefs.setDouble('longitude', current.longitude);
      } catch (e) {
        print('⚠️ Не удалось получить текущие координаты за 3 сек: $e');
        // Используем координаты из кэша если они есть
      }
      
      // УБИРАЕМ: Автоматическое обновление камеры
      // Пользователь сам решит когда нужно обновить вид карты
      
    } catch (e) {
      print('❌ Ошибка получения координат: $e');
      // Загружаем из SharedPreferences если есть
      await _loadLocationFromPreferences();
    }
  }

  // РЕФАКТОР: Определение адреса по текущим координатам
  Future<void> _determineAddressFromLocation() async {
    try {
      print('🏠 Определение адреса...');
      
      // Ждем координаты максимум 2 секунды
      var attempts = 0;
      while (userLocation.value == null && attempts < 10) {
        await Future.delayed(Duration(milliseconds: 200));
        attempts++;
      }
      
      if (userLocation.value == null) {
        print('⚠️ Координаты недоступны для определения адреса');
        return;
      }
      
      // ИЗМЕНЕНО: Всегда определяем адрес по текущему местоположению
      // Убираем проверку на существующий сохраненный адрес
      print('📍 Определяем адрес по текущему местоположению');
      
      final position = userLocation.value!;
      
      // Показываем индикатор загрузки
      savedFromAddress.accept('Определение местоположения...');
      
      // Получаем адрес с бэка
      final restClient = inject<RestClient>();
      final addressData = await restClient.getPlaceDetail(
        latitude: position.lat.toDouble(),
        longitude: position.lng.toDouble(),
      ).timeout(Duration(seconds: 5));
      
      if (addressData != null && addressData.isNotEmpty && addressData != "Адрес не найден") {
        print('✅ Получен адрес с бэка: $addressData');
        
        // МГНОВЕННО обновляем UI
        savedFromAddress.accept(addressData);
        savedFromMapboxId.accept('${position.lat};${position.lng}');
        
        // ВОССТАНОВЛЕНО: Сохраняем адрес для текущей сессии
        // Будет очищен при следующем запуске приложения
        final prefs = inject<SharedPreferences>();
        await prefs.setString('saved_from_address', addressData);
        await prefs.setString('saved_from_coords', '${position.lat};${position.lng}');
        print('💾 Адрес сохранен для текущей сессии (будет очищен при перезапуске)');
        
      } else {
        print('⚠️ Адрес не найден');
        _setFallbackAddress();
      }
      
    } catch (e) {
      print('❌ Ошибка определения адреса: $e');
      _setFallbackAddress();
    }
  }

  // Загрузка координат из SharedPreferences
  Future<void> _loadLocationFromPreferences() async {
    try {
      final prefs = inject<SharedPreferences>();
      final latitude = prefs.getDouble('latitude');
      final longitude = prefs.getDouble('longitude');
      
      if (latitude != null && longitude != null) {
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
        
        // print('✅ Успешно получены и сохранены координаты: ${location.latitude}, ${location.longitude}');
        
        // УБИРАЕМ: Автоматическое обновление камеры
        // Пользователь сам решит когда нужно центрировать карту на себе
        
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
      
      // Получаем sessionId из SharedPreferences
      final prefs = inject<SharedPreferences>();
      final sessionId = prefs.getString('sessionId') ?? 'client_session_${me.value!.id}';
      
      newOrderSocket = IO.io(
        'https://taxi.aktau-go.kz',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'force new connection': true,
          'query': {
            'userType': 'client',        // ИСПРАВЛЕНИЕ: Добавляем тип пользователя
            'userId': me.value!.id,      // ID клиента
            'sessionId': sessionId,      // ИСПРАВЛЕНИЕ: Добавляем sessionId
          },
        },
      );

      // Настраиваем обработчики событий
      
      // Обработчики подключения для отладки
      newOrderSocket?.onConnect((_) {
        print('✅ КЛИЕНТ: Сокет успешно подключен');
        logger.i('✅ КЛИЕНТ: WebSocket подключение установлено');
      });
      
      newOrderSocket?.onConnectError((error) {
        print('❌ КЛИЕНТ: Ошибка подключения сокета: $error');
        logger.e('❌ КЛИЕНТ: Ошибка WebSocket подключения: $error');
      });
      
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
        print('✅ КЛИЕНТ: Получено событие orderAccepted: $data');
        logger.i('✅ КЛИЕНТ: Заказ принят водителем, обновляем активный заказ');
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
        
        // Увеличенные отступы для лучшего отображения маршрута
        final camera = await _mapboxMapController!.cameraForCoordinateBounds(
          CoordinateBounds(
            southwest: Point(coordinates: geotypes.Position(southwest[0], southwest[1])),
            northeast: Point(coordinates: geotypes.Position(northeast[0], northeast[1])),
            infiniteBounds: false
          ),
          MbxEdgeInsets(
            top: 100,    // Отступ сверху (меньше чтобы видеть больше маршрута)
            left: 60,    // Отступ слева
            bottom: 400, // Отступ снизу (больше чтобы учесть панель)
            right: 60,   // Отступ справа
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
      
      // Remove existing route layers and sources
      final layersToRemove = ['main-route-layer', 'main-route-outline-layer', 'main-markers-layer', 'main-markers-layer-a', 'main-markers-layer-b'];
      final sourcesToRemove = ['main-route-source', 'main-markers-source', 'main-markers-source-a', 'main-markers-source-b'];
      
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
      final fromParts = fromMapboxId.split(';');
      final toParts = toMapboxId.split(';');
      
      if (fromParts.length >= 2 && toParts.length >= 2) {
        final fromLat = double.tryParse(fromParts[0]);
        final fromLng = double.tryParse(fromParts[1]);
        final toLat = double.tryParse(toParts[0]);
        final toLng = double.tryParse(toParts[1]);
        
        if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
          print('🗺️ Отображаем маршрут на карте с автоматической блокировкой');
          
          // Отображаем маршрут (блокировка карты происходит автоматически)
          displayRouteOnMainMap(
            geotypes.Position(fromLng, fromLat),
            geotypes.Position(toLng, toLat),
          );
        }
      }
    } catch (e) {
      print('❌ Ошибка отображения маршрута: $e');
    }
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
            final duration = step['duration'] as double?;
            final distance = step['distance'] as double?;
            final geometry = step['geometry'];
            
            if (duration != null && distance != null && geometry != null) {
              // Вычисляем уровень пробок на основе скорости
              final speed = distance / duration; // м/с
              final speedKmh = speed * 3.6; // км/ч
              
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
}
