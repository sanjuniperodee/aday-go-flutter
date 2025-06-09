import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  Future<void> fetchOrderRequests();

  Future<void> onOrderRequestTap(OrderRequestDomain e);

  void tapNewOrders();

  void requestLocationPermission();

  void registerOrderType();
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
        // При включении "онлайн" - загружаем заказы ОДИН раз
        await fetchOrderRequests();
        await _ensureLocationAndSocket();
      } else {
        // При выключении - очищаем список заказов
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

  Future<void> initializeSocket() async {
    // Проверяем, если сокет уже подключен и работает - не переподключаем
    if ((newOrderSocket?.connected ?? false) && (isWebsocketConnected.value ?? false)) {
      logger.i('✅ Сокет уже подключен и работает, переподключение не требуется');
      return;
    }
    
    // Отключаем предыдущий сокет если есть
    await disconnectWebsocket();
    
    try {
      // Получаем данные для подключения
      final position = await Geolocator.getCurrentPosition();
      final sessionId = inject<SharedPreferences>().getString('sessionId');
      
      if (sessionId == null || sessionId.isEmpty) {
        logger.e('❌ SessionId отсутствует, невозможно подключить сокет');
        isWebsocketConnected.accept(false);
        return;
      }
      
      if (me.value?.id == null) {
        logger.e('❌ ID пользователя отсутствует, ждем загрузки профиля');
        isWebsocketConnected.accept(false);
        return;
      }
      
      logger.i('🚀 Инициализация сокета...');
      logger.i('📍 SessionId: $sessionId');
      logger.i('📍 DriverId: ${me.value!.id}');
      logger.i('📍 Position: ${position.latitude}, ${position.longitude}');
      
      // Создаем новый сокет с уникальными параметрами
      newOrderSocket = IO.io(
        'https://taxi.aktau-go.kz',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'forceNew': true,
          'timeout': 30000,
          'reconnection': true,
          'reconnectionAttempts': 3,
          'reconnectionDelay': 5000,
          'query': {
            'sessionId': sessionId,
            'driverId': me.value!.id.toString(),
            'lat': position.latitude.toString(),
            'lng': position.longitude.toString(),
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        },
      );
      
      // Настраиваем обработчики событий ПЕРЕД подключением
      _setupSocketEventHandlers();
      
      // Подключаем сокет
      newOrderSocket!.connect();
      logger.i('🔌 Сокет создан и подключается...');
      
    } catch (e) {
      logger.e('❌ Ошибка при инициализации сокета: $e');
      isWebsocketConnected.accept(false);
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
      
      // Отправляем информацию о водителе при подключении
      if (me.value != null) {
        try {
          newOrderSocket!.emit('driverOnline', {
            'driverId': me.value!.id,
            'lat': driverPosition.value?.latitude ?? 0,
            'lng': driverPosition.value?.longitude ?? 0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          logger.i('📡 Отправлена информация о водителе онлайн');
        } catch (e) {
          logger.e('❌ Ошибка отправки driverOnline: $e');
        }
      }
    });
    
    // Обработчик отключения
    newOrderSocket!.onDisconnect((reason) {
      logger.w('🔌 Сокет отключен: $reason');
      isWebsocketConnected.accept(false);
      
      // Если отключение не намеренное - попробуем переподключиться
      if (statusController.value && reason != 'io client disconnect') {
        logger.i('🔄 Попытка автоматического переподключения...');
        Future.delayed(Duration(seconds: 3), () {
          if (statusController.value && !(isWebsocketConnected.value ?? false)) {
            initializeSocket();
          }
        });
      }
    });
    
    // Обработчик ошибок подключения
    newOrderSocket!.onConnectError((error) {
      logger.e('❌ Ошибка подключения сокета: $error');
      isWebsocketConnected.accept(false);
    });
    
    // Обработчик переподключения
    newOrderSocket!.onReconnect((attempt) {
      logger.i('🔄 Сокет переподключился (попытка $attempt)');
      isWebsocketConnected.accept(true);
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
      
      // Показываем уведомление
      _showNewOrderNotification();
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
    
    logger.i('🎯 Все обработчики событий настроены');
  }

  // Показ уведомления о новом заказе
  void _showNewOrderNotification() {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.local_taxi, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('🚕 Появился новый заказ!'),
              ],
            ),
            duration: Duration(seconds: 4),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Показать',
              textColor: Colors.white,
              onPressed: () {
                // УБИРАЕМ ручное обновление - все через сокеты
                // fetchOrderRequests(); // УДАЛЕНО
                // Можно добавить скролл к списку заказов или другую логику UI
              },
            ),
          ),
        );
      }
    } catch (e) {
      logger.e('❌ Ошибка показа уведомления: $e');
    }
  }

  Future<void> disconnectWebsocket() async {
    try {
      if (newOrderSocket != null) {
        logger.i('🔌 Отключаем сокет...');
        
        // Отправляем информацию о том, что водитель офлайн
        if ((newOrderSocket!.connected ?? false) && me.value != null) {
          try {
            newOrderSocket!.emit('driverOffline', {
              'driverId': me.value!.id,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
            logger.i('📡 Отправлена информация о водителе офлайн');
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
  final StateNotifier<LocationPermission> locationPermission = StateNotifier();

  @override
  Future<void> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    locationPermission.accept(permission);
    
    if ([LocationPermission.always, LocationPermission.whileInUse].contains(permission)) {
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
    
    // Если разрешение получено, включаем онлайн режим
    if ([LocationPermission.always, LocationPermission.whileInUse].contains(locationPermission.value)) {
      statusController.value = true;
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
      });
    } catch (e) {
      logger.e('Error getting location: $e');
    }
  }
}
