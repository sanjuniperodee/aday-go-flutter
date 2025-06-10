import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../core/colors.dart';
import '../../core/images.dart';
import '../../core/text_styles.dart';
import '../../domains/driver_registered_category/driver_registered_category_domain.dart';
import '../../domains/order_request/order_request_domain.dart';
import '../../domains/user/user_domain.dart';
import '../../interactors/order_requests_interactor.dart';
import '../../router/router.dart';
import '../../utils/logger.dart';
import '../../utils/utils.dart';
import '../widgets/primary_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import './widgets/order_request_bottom_sheet.dart';
import './orders_model.dart';
import './orders_screen.dart';
import 'widgets/active_order_bottom_sheet.dart';

defaultOrdersWMFactory(BuildContext context) => OrdersWM(OrdersModel(
      inject<OrderRequestsInteractor>(),
      inject<ProfileInteractor>(),
    ));

abstract class IOrdersWM implements IWidgetModel {
  StateNotifier<int> get tabIndex;

  StateNotifier<List<OrderRequestDomain>> get orderRequests;

  StateNotifier<ActiveRequestDomain> get activeOrder;

  StateNotifier<List<DriverRegisteredCategoryDomain>> get driverRegisteredCategories;

  StateNotifier<UserDomain> get me;

  StateNotifier<bool> get showNewOrders;

  StateNotifier<bool> get isWebsocketConnected;

  StateNotifier<LocationPermission> get locationPermission;

  StateNotifier<DriverType> get orderType;

  StateNotifier<LatLng> get driverPosition;

  ValueNotifier<bool> get statusController;

  StateNotifier<bool> get isOrderRejected;

  StateNotifier<bool> get isWebSocketConnecting;

  StateNotifier<String?> get webSocketConnectionError;

  StateNotifier<int> get tabIndexController;

  StateNotifier<Position?> get driverPositionController;

  StateNotifier<bool> get showNewOrdersController;

  StateNotifier<bool?> get isWebsocketConnectedController;

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
  OrdersWM(
    OrdersModel model,
  ) : super(model);

  IO.Socket? newOrderSocket;

  StreamSubscription<Position>? onUserLocationChanged;

  @override
  final StateNotifier<int> tabIndex = StateNotifier(
    initValue: 0,
  );

  @override
  final ValueNotifier<bool> statusController = ValueNotifier(false);

  @override
  final StateNotifier<bool> showNewOrders = StateNotifier(
    initValue: false,
  );

  @override
  final StateNotifier<bool> isWebsocketConnected = StateNotifier(
    initValue: false,
  );

  @override
  final StateNotifier<bool> isOrderRejected = StateNotifier(
    initValue: false,
  );

  @override
  final StateNotifier<DriverType> orderType = StateNotifier(
    initValue: DriverType.TAXI,
  );

  @override
  final StateNotifier<List<DriverRegisteredCategoryDomain>> driverRegisteredCategories =
      StateNotifier(
    initValue: const [],
  );

  @override
  final StateNotifier<UserDomain> me = StateNotifier();

  @override
  final StateNotifier<LatLng> driverPosition = StateNotifier(
      initValue: LatLng(
    inject<SharedPreferences>().getDouble('latitude') ?? 0,
    inject<SharedPreferences>().getDouble('longitude') ?? 0,
  ));

  @override
  final StateNotifier<List<OrderRequestDomain>> orderRequests = StateNotifier(
    initValue: const [],
  );

  @override
  final StateNotifier<bool> isWebSocketConnecting = StateNotifier(initValue: false);
  
  @override
  final StateNotifier<String?> webSocketConnectionError = StateNotifier();

  @override
  final StateNotifier<int> tabIndexController = StateNotifier(initValue: 0);

  @override
  final StateNotifier<Position?> driverPositionController = StateNotifier();

  @override
  final StateNotifier<bool?> isWebsocketConnectedController = StateNotifier();

  @override
  final StateNotifier<bool> showNewOrdersController = StateNotifier();

  @override
  final StateNotifier<LocationPermission> locationPermission = StateNotifier();

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    fetchDriverRegisteredCategories();
    // НЕ загружаем заказы при инициализации - только при включении кнопки "онлайн"
    // fetchOrderRequests(); // УДАЛЕНО
    fetchUserProfile();
    fetchActiveOrder();
    
    // Автоматически запрашиваем геолокацию при запуске
    _initializeLocationAndSocket();
    
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
    
    // НЕ запускаем периодический polling - все через сокеты
    // _startOrdersPolling(); // УДАЛЕНО
  }

  @override
  void dispose() {
    onUserLocationChanged?.cancel();
    disconnectWebsocket(); // Good to disconnect too
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // УБИРАЕМ ручное обновление при изменении состояния приложения
    // fetchOrderRequests(); // УДАЛЕНО
    // Only initialize socket if returning to foreground
    if (state == AppLifecycleState.resumed && statusController.value) {
      initializeSocket();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем заказы при возврате на страницу, если водитель онлайн
    if (statusController.value && (isWebsocketConnected.value ?? false)) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (context.mounted) {
          fetchOrderRequests();
        }
      });
    }
  }

  Future<void> fetchDriverRegisteredCategories() async {
    try {
      final response = await inject<ProfileInteractor>().fetchDriverRegisteredCategories();

      driverRegisteredCategories.accept(response);
    } on Exception catch (e) {
      logger.e(e);
    }
  }

  @override
  Future<void> fetchOrderRequests() async {
    try {
      final response = await model.getOrderRequests(
        type: orderType.value!,
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
          // УБИРАЕМ ручное обновление - все через сокеты
          // fetchOrderRequests(); // УДАЛЕНО
        },
      ),
    );
  }

  Future<void> acceptOrderRequest(OrderRequestDomain orderRequest) async {
    await model.acceptOrderRequest(
      driver: me.value!,
      orderRequest: orderRequest,
    );

    fetchActiveOrder();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await model.getUserProfile();

      me.accept(response);

      if (statusController.value) {
        await initializeSocket();
      }
    } on Exception catch (e) {
      logger.e(e);
      // Don't call fetchUserProfile recursively as it can cause an infinite loop
      Future.delayed(Duration(seconds: 5), fetchUserProfile);
    }
  }

  @override
  final StateNotifier<ActiveRequestDomain> activeOrder = StateNotifier();

  void fetchActiveOrder({
    bool openBottomSheet = true,
  }) async {
    try {
      final response = await model.getActiveOrder();
      await fetchUserProfile();
      activeOrder.accept(response);
      if (openBottomSheet) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => ActiveOrderBottomSheet(
            me: me.value!,
            activeOrder: activeOrder.value!,
            activeOrderListener: activeOrder,
            onCancel: () {},
          ),
        );
      }
    } on Exception catch (e) {
      logger.e(e);
      if (!openBottomSheet) {
        Navigator.of(context).popUntil(
          (predicate) => predicate.isFirst,
        );
        final snackBar = SnackBar(
          content: Text(
            'Заказ был отменен',
          ),
        );
        fetchOrderRequests();
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  @override
  void tapNewOrders() {
    showNewOrders.accept(false);
    // Обновляем список заказов по запросу пользователя
    fetchOrderRequests();
  }

  @override
  Future<void> initializeSocket() async {
    try {
      // ДОБАВЛЕНО: Показываем состояние загрузки
      isWebSocketConnecting.accept(true);
      webSocketConnectionError.accept(null);
      
      // Проверяем данные для подключения
      if (me.value == null) {
        logger.e('❌ Профиль водителя не найден');
        isWebSocketConnecting.accept(false);
        webSocketConnectionError.accept('Профиль водителя не найден');
        return;
      }
      
      // Проверяем разрешения на геолокацию
      if (![LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
        logger.e('❌ Нет разрешений на геолокацию');
        isWebSocketConnecting.accept(false);
        webSocketConnectionError.accept('Нет разрешений на геолокацию');
        return;
      }
      
      // Проверяем наличие координат
      if (driverPosition.value == null) {
        logger.e('❌ Местоположение водителя недоступно');
        isWebSocketConnecting.accept(false);
        webSocketConnectionError.accept('Местоположение недоступно');
        return;
      }
      
      // Отключаем существующий сокет если есть
      await disconnectWebsocket();
      
      // Генерируем или получаем sessionId
      final sessionId = await inject<SharedPreferences>().getString('session_id') ?? generateUUID();
      logger.i('📍 SessionId: $sessionId');
      final driverId = me.value?.id ?? '';
      logger.i('📍 DriverId: $driverId');
      final position = driverPosition.value;
      logger.i('📍 Position: ${position?.latitude}, ${position?.longitude}');
      
      // ИСПРАВЛЯЕМ: Используем правильную конфигурацию сокета для продакшна
      newOrderSocket = IO.io(
        'https://taxi.aktau-go.kz',  // УБИРАЕМ слэш в конце для стабильности
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()  // Принудительно создаем новое соединение
            .setReconnectionAttempts(5)  // Ограничиваем попытки переподключения
            .setReconnectionDelay(3000)  // 3 секунды между попытками
            .setTimeout(10000)  // 10 секунд таймаут
            .setQuery({
              'userType': 'driver',        // ← Тип пользователя
              'userId': driverId,          // ← ID водителя как userId
              'driverId': driverId,        // ← ДОБАВЛЯЕМ driverId отдельно
              'sessionId': sessionId,      // ← sessionId для аутентификации
              'lat': position?.latitude?.toString() ?? '0',
              'lng': position?.longitude?.toString() ?? '0',
              // ДОБАВЛЯЕМ дополнительные параметры для продакшна
              'version': '1.0.16',         // Версия приложения
              'platform': Platform.isIOS ? 'ios' : 'android',
            })
            .build(),
      );

      // Настройка обработчиков событий
      _setupSocketEventHandlers();
      
      logger.i('🔌 Сокет создан и подключается...');
      
      // Сохраняем sessionId если его не было
      if (!(await inject<SharedPreferences>().containsKey('session_id'))) {
        await inject<SharedPreferences>().setString('session_id', sessionId);
      }
      
    } catch (e) {
      logger.e('❌ Ошибка инициализации сокета: $e');
      isWebsocketConnected.accept(false);
      isWebSocketConnecting.accept(false);
      webSocketConnectionError.accept('Ошибка подключения: ${e.toString()}');
    }
  }
  
  // Настройка обработчиков событий сокета
  void _setupSocketEventHandlers() {
    if (newOrderSocket == null) return;
    
    // Очищаем все старые обработчики
    newOrderSocket!.clearListeners();
    
    // Обработчик успешного подключения
    newOrderSocket!.onConnect((_) {
      logger.i('✅ Сокет успешно подключен');
      isWebsocketConnected.accept(true);
      isWebSocketConnecting.accept(false);  // ДОБАВЛЕНО: Убираем индикатор загрузки
      webSocketConnectionError.accept(null); // ДОБАВЛЕНО: Очищаем ошибки
      
      // ИСПРАВЛЯЕМ: Отправляем корректные данные водителя при подключении
      if (me.value != null && driverPosition.value != null) {
        try {
          // Отправляем информацию о водителе онлайн с задержкой для стабильности
          Future.delayed(Duration(milliseconds: 500), () {
            if (newOrderSocket != null && (newOrderSocket!.connected ?? false)) {
              newOrderSocket!.emit('driverOnline', {
                'driverId': me.value!.id,
                'userId': me.value!.id,
                'userType': 'driver',
                'lat': driverPosition.value!.latitude,
                'lng': driverPosition.value!.longitude,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'status': 'online',
              });
              logger.i('📡 Отправлена информация о водителе онлайн');
              
              // Отправляем координаты отдельно для регистрации в кеше
              _sendLocationUpdate(
                driverPosition.value!.latitude, 
                driverPosition.value!.longitude
              );
            }
          });
        } catch (e) {
          logger.e('❌ Ошибка отправки driverOnline: $e');
        }
      } else {
        logger.w('⚠️ Данные водителя или позиция недоступны при подключении');
      }
    });
    
    // Обработчик отключения
    newOrderSocket!.onDisconnect((reason) {
      logger.w('🔌 Сокет отключен: $reason');
      isWebsocketConnected.accept(false);
      isWebSocketConnecting.accept(false);  // ДОБАВЛЕНО: Убираем индикатор загрузки
      
      // УЛУЧШЕННАЯ логика переподключения
      if (statusController.value && reason != 'io client disconnect') {
        logger.i('🔄 Попытка автоматического переподключения...');
        
        // Увеличиваем задержку для стабильности в продакшне
        Future.delayed(Duration(seconds: 5), () {
          if (statusController.value && 
              !(isWebsocketConnected.value ?? false) &&
              me.value != null &&
              driverPosition.value != null) {
            initializeSocket();
          }
        });
      }
    });
    
    // Обработчик ошибок подключения
    newOrderSocket!.onConnectError((error) {
      logger.e('❌ Ошибка подключения сокета: $error');
      isWebsocketConnected.accept(false);
      isWebSocketConnecting.accept(false);  // ДОБАВЛЕНО: Убираем индикатор загрузки
      webSocketConnectionError.accept('Ошибка подключения: ${error.toString()}'); // ДОБАВЛЕНО: Показываем ошибку
      
      // ДОБАВЛЯЕМ: Retry с увеличенной задержкой при ошибке
      if (statusController.value) {
        Future.delayed(Duration(seconds: 10), () {
          if (statusController.value && !(isWebsocketConnected.value ?? false)) {
            logger.i('🔄 Повторная попытка подключения после ошибки...');
            initializeSocket();
          }
        });
      }
    });
    
    // Обработчик переподключения
    newOrderSocket!.onReconnect((attempt) {
      logger.i('🔄 Сокет переподключился (попытка $attempt)');
      isWebsocketConnected.accept(true);
      
      // При переподключении заново отправляем статус онлайн
      if (me.value != null && driverPosition.value != null) {
        Future.delayed(Duration(milliseconds: 1000), () {
          if (newOrderSocket != null && (newOrderSocket!.connected ?? false)) {
            newOrderSocket!.emit('driverOnline', {
              'driverId': me.value!.id,
              'userId': me.value!.id,
              'userType': 'driver',
              'lat': driverPosition.value!.latitude,
              'lng': driverPosition.value!.longitude,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'status': 'online',
            });
            logger.i('📡 Статус онлайн восстановлен после переподключения');
          }
        });
      }
    });
    
    // Обработчик ошибок переподключения
    newOrderSocket!.onReconnectError((error) {
      logger.e('❌ Ошибка переподключения: $error');
      isWebsocketConnected.accept(false);
    });
    
    // === ОБРАБОТЧИКИ СОБЫТИЙ ЗАКАЗОВ ===
    
    // Новый заказ
    newOrderSocket!.on('newOrder', (data) {
      logger.i('📦 Получено событие newOrder: $data');
      
      // Показываем индикатор новых заказов
      showNewOrders.accept(true);
      
      // Обновляем список заказов если водитель онлайн
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
    });
    
    // Заказ принят другим водителем
    newOrderSocket!.on('orderTaken', (data) {
      logger.i('👤 Заказ принят другим водителем: $data');
      
      // Обновляем список заказов если водитель онлайн
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
    });
    
    // Заказ отклонен клиентом
    newOrderSocket!.on('orderRejected', (data) async {
      logger.i('❌ Получено событие orderRejected: $data');
      
      // Обновляем список заказов если водитель онлайн
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
      
      if (isOrderRejected.value == false && context.mounted) {
        isOrderRejected.accept(true);
        
        try {
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
                      'Поездка отклонена клиентом',
                      style: text500Size20Greyscale90,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton.primary(
                      onPressed: () async {
                        isOrderRejected.accept(false);
                        fetchActiveOrder(openBottomSheet: false);
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
        } catch (e) {
          logger.e('❌ Ошибка показа уведомления об отклонении: $e');
          isOrderRejected.accept(false);
        }
      }
    });
    
    // Заказ обновлен
    newOrderSocket!.on('orderUpdated', (data) {
      logger.i('🔄 Заказ обновлен: $data');
      
      // Обновляем список заказов если водитель онлайн
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
      
      // Если это активный заказ - обновляем его тоже
      if (activeOrder.value != null) {
        fetchActiveOrder(openBottomSheet: false);
      }
    });
    
    // Заказ отменен клиентом
    newOrderSocket!.on('orderCancelled', (data) {
      logger.i('🚫 Заказ отменен клиентом: $data');
      
      // Обновляем список заказов если водитель онлайн
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
      
      // Если это наш активный заказ - показываем уведомление
      try {
        if (activeOrder.value != null && 
            data != null && 
            data is Map && 
            data.containsKey('id') && 
            activeOrder.value!.orderRequest?.id.toString() == data['id'].toString()) {
          
          Navigator.of(context).popUntil((route) => route.isFirst);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Клиент отменил заказ'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          
          activeOrder.accept(ActiveRequestDomain());
        }
      } catch (e) {
        logger.e('❌ Ошибка обработки отмены заказа: $e');
      }
    });
    
    // Заказ удален
    newOrderSocket!.on('orderDeleted', (data) {
      logger.i('🗑️ Заказ удален: $data');
      
      // Обновляем список заказов если водитель онлайн
      if (statusController.value) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            fetchOrderRequests();
          }
        });
      }
    });
    
    // Подтверждение получения события
    newOrderSocket!.on('eventAck', (data) {
      logger.i('✅ Подтверждение события: $data');
    });
    
    // ДОБАВЛЯЕМ: Обработчик подтверждения соединения
    newOrderSocket!.on('connectionConfirmed', (data) {
      logger.i('✅ Подключение подтверждено сервером: $data');
      isWebsocketConnected.accept(true);
    });
    
    logger.i('🎯 Все обработчики событий настроены');
  }

  @override
  Future<void> disconnectWebsocket() async {
    try {
      if (newOrderSocket != null) {
        logger.i('🔌 Отключаем сокет...');
        
        // Отправляем информацию о том, что водитель офлайн
        if ((newOrderSocket!.connected ?? false) && me.value != null) {
          try {
            newOrderSocket!.emit('driverOffline', {
              'driverId': me.value!.id,
              'userId': me.value!.id,          // Дублируем как userId
              'userType': 'driver',            // Подтверждаем тип пользователя
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'status': 'offline',             // Статус водителя
            });
            logger.i('📡 Отправлена информация о водителе офлайн');
            
            // Даем время серверу обработать сообщение
            await Future.delayed(Duration(milliseconds: 500));
          } catch (e) {
            logger.e('❌ Ошибка отправки driverOffline: $e');
          }
        }
        
        // Очищаем обработчики
        newOrderSocket!.clearListeners();
        
        // Отключаем сокет
        newOrderSocket!.disconnect();
        newOrderSocket!.dispose();
        newOrderSocket = null;
        
        logger.i('✅ Сокет отключен и очищен');
      }
      
      isWebsocketConnected.accept(false);
    } catch (e) {
      logger.e('❌ Ошибка при отключении сокета: $e');
      isWebsocketConnected.accept(false);
    }
  }

  @override
  Future<void> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    locationPermission.accept(permission);
    
    if ([LocationPermission.always, LocationPermission.whileInUse].contains(permission)) {
      // Автоматически включаем онлайн режим ТОЛЬКО при явном запросе разрешений пользователем
      statusController.value = true;
      await _startLocationTracking();
    }
  }

  @override
  Future<void> registerOrderType() async {
    await Routes.router.navigate(Routes.driverRegistrationScreen);
    await fetchDriverRegisteredCategories();
    // УБИРАЕМ ручное обновление - заказы обновятся автоматически если водитель онлайн
    // await fetchOrderRequests(); // УДАЛЕНО
  }

  // Инициализация геолокации и сокета при запуске
  Future<void> _initializeLocationAndSocket() async {
    final permission = await Geolocator.checkPermission();
    locationPermission.accept(permission);
    
    if (![LocationPermission.always, LocationPermission.whileInUse].contains(permission)) {
      // Автоматически запрашиваем разрешение
      final newPermission = await Geolocator.requestPermission();
      locationPermission.accept(newPermission);
    }
    
    // ИСПРАВЛЯЕМ: НЕ включаем автоматически онлайн режим при запуске
    // Пользователь должен сам включить переключатель
    // if ([LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
    //   statusController.value = true;
    //   await _startLocationTracking();
    // }
    
    // Просто инициализируем отслеживание местоположения если разрешения есть
    if ([LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
      await _startLocationTracking();
    }
  }

  // Обеспечиваем геолокацию и сокет при включении онлайн режима
  Future<void> _ensureLocationAndSocket() async {
    if ([LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
      await _startLocationTracking();
      await initializeSocket();
    }
  }

  // Запуск отслеживания местоположения
  Future<void> _startLocationTracking() async {
    // Отменяем предыдущее отслеживание если есть
    onUserLocationChanged?.cancel();
    
    try {
      // Получаем текущее местоположение
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Сохраняем в SharedPreferences
      final prefs = inject<SharedPreferences>();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
      
      // Обновляем состояние
      driverPosition.accept(LatLng(position.latitude, position.longitude));
      
      // ДОБАВЛЯЕМ: Отправляем координаты на сервер
      _sendLocationUpdate(position.latitude, position.longitude);
      
      // Начинаем отслеживание изменений
      onUserLocationChanged = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Обновляем только при изменении на 10+ метров
        ),
      ).listen((Position position) async {
        await prefs.setDouble('latitude', position.latitude);
        await prefs.setDouble('longitude', position.longitude);
        driverPosition.accept(LatLng(position.latitude, position.longitude));
        
        // ДОБАВЛЯЕМ: Отправляем обновленные координаты на сервер
        _sendLocationUpdate(position.latitude, position.longitude);
      });
    } catch (e) {
      logger.e('Error getting location: $e');
    }
  }
  
  // УЛУЧШЕННЫЙ МЕТОД: Отправка координат на сервер
  void _sendLocationUpdate(double latitude, double longitude) {
    try {
      if (newOrderSocket != null && 
          (newOrderSocket!.connected ?? false) && 
          statusController.value && 
          me.value != null) {
        
        // Отправляем с дополнительными параметрами для совместимости
        newOrderSocket!.emit('driverLocationUpdate', {
          'driverId': me.value!.id,
          'userId': me.value!.id,          // Дублируем как userId 
          'userType': 'driver',            // Подтверждаем тип пользователя
          'lat': latitude,
          'lng': longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'online',              // Статус водителя
        });
        
        logger.i('📍 Координаты отправлены на сервер: $latitude, $longitude');
      } else {
        logger.w('⚠️ Не могу отправить координаты: сокет отключен или водитель оффлайн');
      }
    } catch (e) {
      logger.e('❌ Ошибка отправки координат: $e');
    }
  }

  // Генерация UUID для sessionId
  String generateUUID() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Устанавливаем версию (4) и вариант
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    
    return [
      bytes.sublist(0, 4),
      bytes.sublist(4, 6),
      bytes.sublist(6, 8),
      bytes.sublist(8, 10),
      bytes.sublist(10, 16),
    ].map((part) => part.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()).join('-');
  }
}
