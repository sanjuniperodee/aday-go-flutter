import 'dart:async';

import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/services.dart';

import '../../domains/driver_registered_category/driver_registered_category_domain.dart';
import '../../domains/order_request/order_request_domain.dart';
import '../../domains/user/user_domain.dart';
import '../../interactors/order_requests_interactor.dart';
import '../../router/router.dart';
import '../../utils/logger.dart';
import '../../utils/utils.dart';
import './widgets/order_request_bottom_sheet.dart';
import './orders_model.dart';
import './orders_screen.dart';
import 'widgets/active_order_bottom_sheet.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';

defaultOrdersWMFactory(BuildContext context) => OrdersWM(OrdersModel(
      inject<OrderRequestsInteractor>(),
      inject<ProfileInteractor>(),
    ));

abstract class IOrdersWM implements IWidgetModel {
  StateNotifier<int> get tabIndex;
  StateNotifier<List<OrderRequestDomain>> get orderRequests;
  StateNotifier<ActiveRequestDomain?> get activeOrder;
  StateNotifier<List<DriverRegisteredCategoryDomain>> get driverRegisteredCategories;
  StateNotifier<UserDomain?> get me;
  StateNotifier<bool> get showNewOrders;
  StateNotifier<bool> get isWebsocketConnected;
  StateNotifier<LocationPermission> get locationPermission;
  StateNotifier<DriverType> get orderType;
  StateNotifier<LatLng> get driverPosition;
  ValueNotifier<bool> get statusController;
  StateNotifier<bool> get isOrderRejected;
  StateNotifier<bool> get isWebSocketConnecting;
  StateNotifier<String?> get webSocketConnectionError;

  Future<void> fetchOrderRequests();
  Future<void> onOrderRequestTap(OrderRequestDomain e);
  void tapNewOrders();
  void requestLocationPermission();
  void registerOrderType();
  Future<void> initializeSocket();
}

class OrdersWM extends WidgetModel<OrdersScreen, OrdersModel>
    with WidgetsBindingObserver
    implements IOrdersWM {
  OrdersWM(super.model);

  IO.Socket? newOrderSocket;
  StreamSubscription<Position>? onUserLocationChanged;
  Timer? _activeOrderCheckTimer;

  @override
  final StateNotifier<int> tabIndex = StateNotifier(initValue: 0);

  @override
  final ValueNotifier<bool> statusController = ValueNotifier(false);

  @override
  final StateNotifier<bool> showNewOrders = StateNotifier(initValue: false);

  @override
  final StateNotifier<bool> isWebsocketConnected = StateNotifier(initValue: false);

  @override
  final StateNotifier<bool> isOrderRejected = StateNotifier(initValue: false);

  @override
  final StateNotifier<DriverType> orderType = StateNotifier(initValue: DriverType.TAXI);

  @override
  final StateNotifier<List<DriverRegisteredCategoryDomain>> driverRegisteredCategories =
      StateNotifier(initValue: const []);

  @override
  final StateNotifier<UserDomain?> me = StateNotifier();

  @override
  final StateNotifier<LatLng> driverPosition = StateNotifier(
      initValue: LatLng(
    inject<SharedPreferences>().getDouble('latitude') ?? 0,
    inject<SharedPreferences>().getDouble('longitude') ?? 0,
  ));

  @override
  final StateNotifier<List<OrderRequestDomain>> orderRequests = StateNotifier(initValue: const []);

  @override
  final StateNotifier<bool> isWebSocketConnecting = StateNotifier(initValue: false);
  
  @override
  final StateNotifier<String?> webSocketConnectionError = StateNotifier();

  @override
  final StateNotifier<LocationPermission> locationPermission = StateNotifier();

  @override
  final StateNotifier<ActiveRequestDomain?> activeOrder = StateNotifier();

  // Separate non-nullable notifier for ActiveOrderBottomSheet
  final StateNotifier<ActiveRequestDomain> _activeOrderNotifier = StateNotifier();

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    fetchDriverRegisteredCategories();
    fetchUserProfile();
    
    // Сразу загружаем последнюю известную позицию водителя
    _loadLastKnownDriverPosition();
    
    // Автоматически запрашиваем геолокацию при запуске
    _initializeLocationAndSocket();
    
    // ВАЖНО: Проверяем активный заказ с задержкой чтобы UI успел инициализироваться
    Future.delayed(Duration(milliseconds: 500), () {
      fetchActiveOrder(openBottomSheet: true);
    });
    
    // Запускаем периодическую проверку активного заказа
    _startActiveOrderMonitoring();
    
    // Добавляем слушатель переключения статуса
    statusController.addListener(() async {
      logger.i('🔄 Статус изменен на: ${statusController.value}');
      
      if (statusController.value) {
        // При включении "онлайн" - проверяем все условия
        if (me.value == null) {
          logger.e('❌ Профиль водителя не загружен');
          statusController.value = false;
          return;
        }
        
        if (driverPosition.value == null) {
          logger.e('❌ Местоположение водителя недоступно');
          await _startLocationTracking();
          if (driverPosition.value == null) {
            statusController.value = false;
            return;
          }
        }
        
        // Загружаем заказы и инициализируем сокет
        await fetchOrderRequests();
        await _ensureLocationAndSocket();
        
        // Принудительно отправляем текущие координаты
        if (driverPosition.value != null) {
          _sendLocationUpdate(
            driverPosition.value!.latitude, 
            driverPosition.value!.longitude
          );
        }
        
        logger.i('✅ Водитель переведен в онлайн режим');
      } else {
        // При выключении - очищаем заказы и отключаемся
        logger.i('🔄 Водитель переходит в оффлайн режим');
        orderRequests.accept([]);
        await disconnectWebsocket();
      }
    });
  }

  @override
  void dispose() {
    _activeOrderCheckTimer?.cancel();
    onUserLocationChanged?.cancel();
    disconnectWebsocket();
    super.dispose();
  }

  Future<void> _initializeLocationAndSocket() async {
    try {
      isWebSocketConnecting.accept(true);
      webSocketConnectionError.accept(null);
      
      // Запрашиваем разрешение на геолокацию
      await _requestLocationPermission();
      
      // Если разрешение получено, запускаем отслеживание
      if ([LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
        await _startLocationTracking();
      }
      
      isWebSocketConnecting.accept(false);
    } catch (e) {
      logger.e('❌ Ошибка инициализации: $e');
      isWebSocketConnecting.accept(false);
      webSocketConnectionError.accept('Ошибка инициализации: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      locationPermission.accept(permission);
    } catch (e) {
      logger.e('❌ Ошибка запроса разрешения на геолокацию: $e');
      locationPermission.accept(LocationPermission.denied);
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      if (![LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
        return;
      }

      // Сначала пытаемся загрузить последнюю сохраненную позицию для быстрого старта
      try {
        final prefs = inject<SharedPreferences>();
        final savedLat = prefs.getDouble('latitude');
        final savedLng = prefs.getDouble('longitude');
        
        if (savedLat != null && savedLng != null && savedLat != 0 && savedLng != 0) {
          driverPosition.accept(LatLng(savedLat, savedLng));
          logger.i('📍 Загружена последняя сохраненная позиция: $savedLat, $savedLng');
        }
      } catch (e) {
        logger.e('⚠️ Ошибка загрузки сохраненной позиции: $e');
      }

      // Получаем текущее местоположение
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10), // Ограничиваем время ожидания
        ),
      );

      driverPosition.accept(LatLng(position.latitude, position.longitude));
      
      // Сохраняем координаты
      await inject<SharedPreferences>().setDouble('latitude', position.latitude);
      await inject<SharedPreferences>().setDouble('longitude', position.longitude);
      
      logger.i('📍 Обновлена текущая позиция: ${position.latitude}, ${position.longitude}');

      // Запускаем отслеживание изменений
      onUserLocationChanged?.cancel();
      onUserLocationChanged = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Обновляем при перемещении на 10 метров
        ),
      ).listen((Position position) {
        driverPosition.accept(LatLng(position.latitude, position.longitude));
        
        // Сохраняем новую позицию
        inject<SharedPreferences>().setDouble('latitude', position.latitude);
        inject<SharedPreferences>().setDouble('longitude', position.longitude);
        
        // Отправляем обновление местоположения через WebSocket
        if (newOrderSocket != null && newOrderSocket!.connected) {
          _sendLocationUpdate(position.latitude, position.longitude);
        }
      });

      logger.i('✅ Отслеживание местоположения запущено');
    } catch (e) {
      logger.e('❌ Ошибка запуска отслеживания местоположения: $e');
      
      // Если не удалось получить текущую позицию, используем сохраненную
      try {
        final prefs = inject<SharedPreferences>();
        final savedLat = prefs.getDouble('latitude');
        final savedLng = prefs.getDouble('longitude');
        
        if (savedLat != null && savedLng != null && savedLat != 0 && savedLng != 0 && driverPosition.value == null) {
          driverPosition.accept(LatLng(savedLat, savedLng));
          logger.i('📍 Используем сохраненную позицию как fallback: $savedLat, $savedLng');
        }
      } catch (fallbackError) {
        logger.e('❌ Ошибка загрузки fallback позиции: $fallbackError');
      }
    }
  }

  Future<void> _ensureLocationAndSocket() async {
    try {
      if (newOrderSocket == null || !newOrderSocket!.connected) {
        await initializeWebsocket();
      }
    } catch (e) {
      logger.e('❌ Ошибка обеспечения подключения: $e');
      webSocketConnectionError.accept('Ошибка подключения: $e');
    }
  }

  @override
  Future<void> initializeSocket() async {
    await initializeWebsocket();
  }

  Future<void> initializeWebsocket() async {
    try {
      isWebSocketConnecting.accept(true);
      webSocketConnectionError.accept(null);
      
      if (me.value == null) {
        logger.e('❌ Профиль пользователя не загружен');
        webSocketConnectionError.accept('Профиль пользователя не загружен');
        isWebSocketConnecting.accept(false);
        return;
      }

      final driverId = me.value!.id;
      final sessionId = inject<SharedPreferences>().getString('session_id') ?? 
                       DateTime.now().millisecondsSinceEpoch.toString();
      final position = driverPosition.value;

      logger.i('🔌 Инициализация WebSocket...');
      logger.i('📍 Параметры: driverId=$driverId, sessionId=$sessionId');
      
      // Отключаем существующее соединение
      if (newOrderSocket != null) {
        newOrderSocket!.close();
        newOrderSocket = null;
      }

      // Создаем новое соединение
      newOrderSocket = IO.io(
        'ws://taxi.aktau-go.kz',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'forceNew': true,
          'timeout': 30000,
          'reconnection': true,
          'reconnectionAttempts': 5,
          'reconnectionDelay': 3000,
          'query': {
            'userType': 'driver',
            'userId': driverId,
            'driverId': driverId,
            'sessionId': sessionId,
            'lat': position?.latitude.toString() ?? '0',
            'lng': position?.longitude.toString() ?? '0',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        },
      );

      // Настройка обработчиков событий
      _setupSocketEventHandlers();
      
      // Подключаемся после настройки обработчиков
      newOrderSocket!.connect();
      
      logger.i('🔌 Сокет создан и подключается...');
      logger.i('📍 Параметры подключения: userType=driver, userId=$driverId, sessionId=$sessionId');
      
      // Сохраняем sessionId если его не было
      if (!inject<SharedPreferences>().containsKey('session_id')) {
        await inject<SharedPreferences>().setString('session_id', sessionId);
      }
      
    } catch (e) {
      logger.e('❌ Ошибка инициализации WebSocket: $e');
      isWebSocketConnecting.accept(false);
      webSocketConnectionError.accept('Ошибка подключения: $e');
      isWebsocketConnected.accept(false);
    }
  }

  void _setupSocketEventHandlers() {
    if (newOrderSocket == null) return;

    // Подключение установлено
    newOrderSocket!.onConnect((data) {
      logger.i('✅ WebSocket подключен');
      isWebsocketConnected.accept(true);
      isWebSocketConnecting.accept(false);
      webSocketConnectionError.accept(null);
      
      // Отправляем текущие координаты при подключении
      if (driverPosition.value != null) {
        _sendLocationUpdate(
          driverPosition.value!.latitude,
          driverPosition.value!.longitude,
        );
      }
    });

    // Соединение разорвано
    newOrderSocket!.onDisconnect((data) {
      logger.i('🔄 WebSocket отключен: $data');
      isWebsocketConnected.accept(false);
      isWebSocketConnecting.accept(false);
    });

    // Ошибка соединения
    newOrderSocket!.onError((data) {
      logger.e('❌ Ошибка WebSocket: $data');
      isWebsocketConnected.accept(false);
      isWebSocketConnecting.accept(false);
      webSocketConnectionError.accept('Ошибка соединения: $data');
    });

    // Попытка переподключения
    newOrderSocket!.onReconnectAttempt((attemptNumber) {
      logger.i('🔄 Попытка переподключения #$attemptNumber');
      isWebSocketConnecting.accept(true);
      webSocketConnectionError.accept('Переподключение...');
    });

    // Успешное переподключение
    newOrderSocket!.onReconnect((data) {
      logger.i('✅ WebSocket переподключен');
      isWebsocketConnected.accept(true);
      isWebSocketConnecting.accept(false);
      webSocketConnectionError.accept(null);
    });

    // Новый заказ
    newOrderSocket!.on('newOrder', (data) {
      logger.i('🚗 Получен новый заказ: $data');
      _handleNewOrder(data);
    });

    // Обновление заказа
    newOrderSocket!.on('orderUpdated', (data) {
      logger.i('📝 Обновление заказа: $data');
      _handleOrderUpdate(data);
    });

    // Заказ принят мной
    newOrderSocket!.on('orderAcceptedByMe', (data) {
      logger.i('✅ Я успешно принял заказ: $data');
      
      // Немедленно обновляем список заказов
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
      
      // Получаем активный заказ для отображения
      Future.delayed(Duration(milliseconds: 200), () {
        if (context.mounted) {
          fetchActiveOrder();
        }
      });
    });

    // Заказ отклонен клиентом
    newOrderSocket!.on('orderRejected', (data) async {
      logger.i('❌ Получено событие orderRejected: $data');
      
      try {
        // Закрываем все открытые модальные окна
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        
        // Показываем уведомление об отклонении
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заказ был отклонен клиентом'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Обновляем список заказов
        await fetchOrderRequests();
        
        // Очищаем активный заказ
        activeOrder.accept(null);
        
      } catch (e) {
        logger.e('❌ Ошибка обработки отклонения заказа: $e');
      }
    });

    // Заказ отменен клиентом (после принятия водителем)
    newOrderSocket!.on('orderCancelledByClient', (data) async {
      logger.i('🚫 Получено событие orderCancelledByClient: $data');
      
      try {
        final orderId = data['orderId'];
        final reason = data['reason'] ?? 'cancelled_by_client';
        final message = data['message'] ?? 'Клиент отменил заказ';
        
        // Закрываем все открытые модальные окна (особенно важно для окна активного заказа)
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        
        // Показываем уведомление об отмене
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ОК',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        
        // Показываем haptic feedback
        HapticFeedback.heavyImpact();
        
        // Обновляем список заказов
        await fetchOrderRequests();
        
        // Очищаем активный заказ
        activeOrder.accept(null);
        
        logger.i('✅ Обработка отмены заказа клиентом завершена для заказа: $orderId');
        
      } catch (e) {
        logger.e('❌ Ошибка обработки отмены заказа клиентом: $e');
      }
    });

    // Завершение поездки
    newOrderSocket!.on('rideEnded', (data) {
      logger.i('🏁 Поездка завершена: $data');
      
      // Очищаем активный заказ
      activeOrder.accept(null);
      
      // Обновляем список заказов если водитель онлайн
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
      
      // Показываем уведомление об успешном завершении
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Поездка успешно завершена'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    // Заказ удален (отменен клиентом)
    newOrderSocket!.on('orderDeleted', (data) {
      logger.i('🗑️ Заказ удален: $data');
      
      try {
        // Обновляем список заказов чтобы убрать отмененный заказ
        if (statusController.value) {
          fetchOrderRequests();
        }

      } catch (e) {
        logger.e('❌ Ошибка обработки удаления заказа: $e');
      }
    });

    // Заказ принят другим водителем
    newOrderSocket!.on('orderTaken', (data) {
      logger.i('🤝 Заказ принят другим водителем: $data');
      
      try {
        final orderId = data['orderId'];
        final takenBy = data['takenBy'];
        
        // Обновляем список заказов чтобы убрать принятый заказ
        if (statusController.value) {
          fetchOrderRequests();
        }
        
      } catch (e) {
        logger.e('❌ Ошибка обработки принятия заказа другим водителем: $e');
      }
    });
  }

  void _sendLocationUpdate(double latitude, double longitude) {
    try {
      if (newOrderSocket != null && newOrderSocket!.connected) {
        newOrderSocket!.emit('driverLocationUpdate', {
          'lat': latitude,
          'lng': longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        logger.d('📍 Отправлено обновление местоположения водителя: $latitude, $longitude');
      }
    } catch (e) {
      logger.e('❌ Ошибка отправки обновления местоположения: $e');
    }
  }

  void _handleNewOrder(dynamic orderData) {
    try {
      fetchOrderRequests();
      _showNewOrderNotification();
      showNewOrders.accept(true);
      HapticFeedback.heavyImpact();
    } catch (e) {
      logger.e('❌ Ошибка обработки нового заказа: $e');
    }
  }
  
  void _handleOrderUpdate(dynamic orderData) {
    try {
      fetchOrderRequests();
      fetchActiveOrder(openBottomSheet: false);
    } catch (e) {
      logger.e('❌ Ошибка обработки обновления заказа: $e');
    }
  }
  
  Future<void> _showNewOrderNotification() async {
    try {
      // Показываем простое уведомление в приложении
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚗 Новый заказ!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logger.e('❌ Ошибка отображения уведомления о новом заказе: $e');
    }
  }

  @override
  Future<void> fetchOrderRequests() async {
    try {
      final orderTypeValue = orderType.value;
      if (orderTypeValue == null) return;
      
      final response = await model.getOrderRequests(
        type: orderTypeValue,
      );
      orderRequests.accept(response);
      showNewOrders.accept(false);
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  @override
  Future<void> onOrderRequestTap(OrderRequestDomain e) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => OrderRequestBottomSheet(
        orderRequest: e,
        onAccept: () async {
          await acceptOrderRequest(e);
          Routes.router.popUntil((predicate) => predicate.isFirst);
        },
      ),
    );
  }

  Future<void> acceptOrderRequest(OrderRequestDomain orderRequest) async {
    final meValue = me.value;
    if (meValue == null) return;
    
    // 🔒 КРИТИЧЕСКИ ВАЖНО: Проверяем геопозицию водителя перед принятием заказа
    if (driverPosition.value == null) {
      logger.w('❌ Попытка принять заказ без доступной геопозиции водителя');
      
      // Пытаемся получить текущую позицию
      await _startLocationTracking();
      
      // Если все еще нет позиции - блокируем принятие
      if (driverPosition.value == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Невозможно принять заказ без доступа к геопозиции'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Разрешить',
                textColor: Colors.white,
                onPressed: () => requestLocationPermission(),
              ),
            ),
          );
        }
        logger.e('❌ ЗАКАЗ НЕ ПРИНЯТ: геопозиция водителя недоступна');
        return; // Блокируем принятие заказа
      }
    }
    
    // ✅ Геопозиция доступна - принимаем заказ и СРАЗУ отправляем позицию
    logger.i('✅ Принятие заказа: геопозиция водителя доступна (${driverPosition.value!.latitude}, ${driverPosition.value!.longitude})');
    
    await model.acceptOrderRequest(
      driver: meValue,
      orderRequest: orderRequest,
    );

    // ГАРАНТИРОВАННО отправляем текущую позицию водителя на бэк сразу после принятия
    if (driverPosition.value != null) {
      _sendLocationUpdate(
        driverPosition.value!.latitude, 
        driverPosition.value!.longitude
      );
      logger.i('📍 Позиция водителя отправлена на бэк сразу после принятия заказа');
    }

    fetchActiveOrder();
  }

  @override
  void tapNewOrders() {
    showNewOrders.accept(false);
    fetchOrderRequests();
  }

  @override
  void requestLocationPermission() async {
    try {
      await _requestLocationPermission();
      
      // После получения разрешения запускаем отслеживание
      if ([LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
        await _startLocationTracking();
      }
    } catch (e) {
      logger.e('❌ Ошибка запроса разрешения на геолокацию: $e');
    }
  }

  @override
  void registerOrderType() {
    // Открываем страницу регистрации водителя
    Routes.router.navigate('/driver-registration');
  }

  void fetchActiveOrder({bool openBottomSheet = true}) async {
    try {
      final response = await model.getActiveOrder();
      if (response != null) {
        activeOrder.accept(response);
        _activeOrderNotifier.accept(response);
        
        // 🚨 КРИТИЧЕСКИ ВАЖНО: При восстановлении активного заказа ОБЯЗАТЕЛЬНО отправляем позицию водителя
        if (driverPosition.value != null) {
          _sendLocationUpdate(
            driverPosition.value!.latitude, 
            driverPosition.value!.longitude
          );
          logger.i('📍 Позиция водителя отправлена на бэк при восстановлении активного заказа');
        } else {
          // Если позиции нет - пытаемся получить текущую
          logger.w('⚠️ При восстановлении активного заказа нет позиции водителя, пытаемся получить');
          await _startLocationTracking();
          if (driverPosition.value != null) {
            _sendLocationUpdate(
              driverPosition.value!.latitude, 
              driverPosition.value!.longitude
            );
            logger.i('📍 Позиция водителя получена и отправлена при восстановлении заказа');
          } else {
            logger.e('❌ Не удалось получить позицию водителя при восстановлении активного заказа');
          }
        }
        
        final meValue = me.value;
        if (openBottomSheet && context.mounted && meValue != null) {
          showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => ActiveOrderBottomSheet(
              me: meValue,
              activeOrder: response,
              activeOrderListener: _activeOrderNotifier,
              ordersWm: this,
              onCancel: () {},
            ),
          );
        }
      } else {
        // Если нет активного заказа
        activeOrder.accept(null);
      }
    } catch (e) {
      logger.e('❌ Ошибка получения активного заказа: $e');
      activeOrder.accept(null);
    }
  }
  
  Future<void> fetchDriverRegisteredCategories() async {
    try {
      final response = await inject<ProfileInteractor>().fetchDriverRegisteredCategories();
      driverRegisteredCategories.accept(response);
    } catch (e) {
      logger.e('❌ Ошибка получения списка зарегистрированных категорий: $e');
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final userProfile = await inject<RestClient>().getUserProfile();
      if (userProfile != null) {
        final userDomain = UserDomain(
          id: userProfile.id,
          firstName: userProfile.firstName,
          lastName: userProfile.lastName,
          phone: userProfile.phone,
        );
        me.accept(userDomain);
      }
    } catch (e) {
      logger.e('❌ Ошибка загрузки профиля пользователя: $e');
    }
  }

  Future<void> disconnectWebsocket() async {
    try {
      newOrderSocket?.close();
      newOrderSocket = null;
      isWebsocketConnected.accept(false);
      logger.i('🔄 WebSocket отключен');
    } catch (e) {
      logger.e('❌ Ошибка отключения WebSocket: $e');
    }
  }

  // Запускаем мониторинг активного заказа
  void _startActiveOrderMonitoring() {
    _activeOrderCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      // Проверяем активный заказ только если окно не открыто
      if (activeOrder.value == null && context.mounted) {
        fetchActiveOrder(openBottomSheet: true);
      }
    });
  }

  // Загружаем последнюю известную позицию водителя
  Future<void> _loadLastKnownDriverPosition() async {
    try {
      final prefs = inject<SharedPreferences>();
      final savedLat = prefs.getDouble('latitude');
      final savedLng = prefs.getDouble('longitude');
      
      if (savedLat != null && savedLng != null && savedLat != 0 && savedLng != 0) {
        driverPosition.accept(LatLng(savedLat, savedLng));
        logger.i('📍 Загружена последняя известная позиция водителя при инициализации: $savedLat, $savedLng');
      } else {
        logger.i('📍 Нет сохраненной позиции водителя');
      }
    } catch (e) {
      logger.e('❌ Ошибка загрузки последней позиции при инициализации: $e');
    }
  }
} 