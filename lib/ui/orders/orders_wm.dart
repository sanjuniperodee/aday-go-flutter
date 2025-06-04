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

  void tabIndexChanged(int tabIndex);

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
  void tabIndexChanged(int tabIndex) {
    this.tabIndex.accept(tabIndex);
    orderType.accept(DriverType.values[tabIndex]);
    fetchOrderRequests();
  }

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
    fetchOrderRequests();
    fetchUserProfile();
    fetchActiveOrder();
    statusController.addListener(() async {
      if (statusController.value) {
        await initializeSocket();
      } else {
        await disconnectWebsocket();
      }
    });
    
    // Start periodic polling for new orders
    _startOrdersPolling();
  }

  Timer? _orderPollingTimer;
  
  // Start periodic polling for orders to ensure we don't miss any
  void _startOrdersPolling() {
    // Cancel any existing timer
    _orderPollingTimer?.cancel();
    
    // Create new timer that polls every 10 seconds
    _orderPollingTimer = Timer.periodic(
      Duration(seconds: 10),
      (timer) {
        if (statusController.value) {
          fetchOrderRequestsCount();
        }
      },
    );
  }

  @override
  void dispose() {
    onUserLocationChanged?.cancel();
    _orderPollingTimer?.cancel();
    disconnectWebsocket(); // Good to disconnect too
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    fetchOrderRequests();
    // Only initialize socket if returning to foreground
    if (state == AppLifecycleState.resumed && statusController.value) {
      initializeSocket();
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

  Future<void> fetchOrderRequestsCount() async {
    try {
      final response = await model.getOrderRequests(
        type: orderType.value!,
      );
      // orderRequests.accept(response);

      if (response.length != orderRequests.value!.length) {
        showNewOrders.accept(true);
      }
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
          fetchOrderRequests();
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
    fetchOrderRequests();
  }

  Future<void> initializeSocket() async {
    // Отменяем предыдущий сокет
    await disconnectWebsocket();
    
    // Запускаем отслеживание местоположения
    _startLocationUpdates();
    
    try {
      // Получаем текущее местоположение
      final position = await Geolocator.getCurrentPosition();
      final sessionId = inject<SharedPreferences>().getString('sessionId');
      
      logger.i('Инициализация сокета с sessionId: $sessionId');
      
      // Создаем новый сокет
      newOrderSocket = IO.io(
        'https://taxi.aktau-go.kz',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'force new connection': true,
          'query': {
            'sessionId': sessionId,
            'lat': position.latitude.toString(),
            'lng': position.longitude.toString(),
          },
        },
      );
      
      // Настраиваем обработчики событий
      newOrderSocket!.onConnect((_) {
        logger.i('Сокет подключен');
        isWebsocketConnected.accept(true);
        
        // Настраиваем обработчики событий
        _setupSocketEventHandlers();
      });
      
      newOrderSocket!.onDisconnect((reason) {
        logger.w('Сокет отключен: $reason');
        isWebsocketConnected.accept(false);
        
        // Пытаемся переподключиться, если это не явное отключение
        if (statusController.value && reason != 'io client disconnect') {
          Future.delayed(Duration(seconds: 3), () {
            if (statusController.value) {
              logger.i('Повторное подключение сокета...');
              newOrderSocket?.connect();
            }
          });
        }
      });
      
      newOrderSocket!.onConnectError((error) {
        logger.e('Ошибка подключения сокета: $error');
        isWebsocketConnected.accept(false);
        
        // Пытаемся переподключиться
        if (statusController.value) {
          Future.delayed(Duration(seconds: 3), () {
            if (statusController.value) {
              logger.i('Повторное подключение сокета после ошибки...');
              newOrderSocket?.connect();
            }
          });
        }
      });
      
      // Подключаем сокет
      newOrderSocket!.connect();
      logger.i('Сокет инициализирован');
    } catch (e) {
      logger.e('Ошибка при инициализации сокета: $e');
    }
  }
  
  // Настройка обработчиков событий сокета
  void _setupSocketEventHandlers() {
    // Удаляем все обработчики
    newOrderSocket!.off('newOrder');
    newOrderSocket!.off('orderRejected');
    newOrderSocket!.off('orderUpdated');
    newOrderSocket!.off('orderDeleted');
    newOrderSocket!.off('orderCancelled');
    
    // Обработчик для отклонения заказа
    newOrderSocket!.on('orderRejected', (data) async {
      logger.i('Получено событие orderRejected (driver): $data');
      
      if (isOrderRejected.value == false) {
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
                      fetchActiveOrder(
                        openBottomSheet: false,
                      );
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
    });
    
    // Обработчик для нового заказа
    newOrderSocket!.on('newOrder', (data) {
      logger.i('Получено событие newOrder (driver): $data');
      logger.i('Тип данных: ${data?.runtimeType}');
      logger.i('Содержимое: $data');
      
      // Показываем индикатор новых заказов
      showNewOrders.accept(true);
      
      // Обновляем список заказов
      fetchOrderRequests();
      
      // Показываем уведомление
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Появился новый заказ!'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Показать',
              onPressed: () {
                fetchOrderRequests();
              },
            ),
          ),
        );
      } catch (e) {
        logger.e('Ошибка при показе уведомления: $e');
      }
      
      // Обновляем заказы еще раз через 500мс
      Future.delayed(Duration(milliseconds: 500), () {
        fetchOrderRequests();
      });
    });
    
    // Обработчик для обновления заказа
    newOrderSocket!.on('orderUpdated', (data) {
      logger.i('Получено событие orderUpdated (driver): $data');
      fetchOrderRequests();
    });
    
    // Обработчик для удаленного заказа
    newOrderSocket!.on('orderDeleted', (data) {
      logger.i('Получено событие orderDeleted (driver): $data');
      
      // Обновляем список заказов
      fetchOrderRequests();
      
      // Проверяем, не наш ли это активный заказ
      if (activeOrder.value != null && 
          data != null && 
          data is Map && 
          data.containsKey('id') && 
          activeOrder.value!.orderRequest?.id.toString() == data['id'].toString()) {
        
        // Если это наш активный заказ, показываем уведомление
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заказ был удален'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
    
    // Обработчик для отмененного заказа
    newOrderSocket!.on('orderCancelled', (data) {
      logger.i('Получено событие orderCancelled (driver): $data');
      
      // Обновляем список заказов
      fetchOrderRequests();
      
      // Проверяем, не наш ли это активный заказ
      if (activeOrder.value != null && 
          data != null && 
          data is Map && 
          data.containsKey('id') && 
          activeOrder.value!.orderRequest?.id.toString() == data['id'].toString()) {
        
        // Если это наш активный заказ, показываем уведомление
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Клиент отменил заказ'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
    
    // Сразу запрашиваем список заказов
    fetchOrderRequests();
  }

  // Метод для запуска отслеживания местоположения
  void _startLocationUpdates() {
    // Отменяем предыдущую подписку
    onUserLocationChanged?.cancel();
    onUserLocationChanged = null;
    
    // Запрашиваем разрешение на использование геолокации
    _checkLocationPermission().then((hasPermission) {
      if (!hasPermission) {
        logger.e("Нет разрешения на использование геолокации");
        return;
      }
      
      try {
        // Создаем подписку на обновления местоположения
        onUserLocationChanged = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5, // Обновляем каждые 5 метров
          ),
        ).listen(
          (position) {
            // Сохраняем позицию
            driverPosition.accept(LatLng(
              position.latitude,
              position.longitude,
            ));
            
            // Сохраняем в SharedPreferences
            inject<SharedPreferences>().setDouble('latitude', position.latitude);
            inject<SharedPreferences>().setDouble('longitude', position.longitude);
            
            // Отправляем на сервер, если подключены
            if (newOrderSocket != null && newOrderSocket!.connected && statusController.value) {
              try {
                newOrderSocket!.emit(
                  'updateLocation',
                  jsonEncode({
                    "driverId": me.value!.id,
                    "latitude": position.latitude.toString(),
                    "longitude": position.longitude.toString(),
                  }),
                );
                logger.i("Геопозиция обновлена: ${position.latitude}, ${position.longitude}");
              } catch (e) {
                logger.e("Ошибка при отправке геопозиции: $e");
              }
            }
          },
          onError: (error) {
            logger.e("Ошибка при получении геопозиции: $error");
          },
        );
        
        logger.i("Отслеживание местоположения запущено");
      } catch (e) {
        logger.e("Ошибка при запуске отслеживания местоположения: $e");
      }
    });
  }
  
  // Проверка разрешения на использование геолокации
  Future<bool> _checkLocationPermission() async {
    try {
      // Проверяем, включены ли сервисы геолокации
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.e("Сервисы геолокации отключены");
        return false;
      }
      
      // Проверяем разрешение
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Запрашиваем разрешение
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          logger.e("Разрешение на использование геолокации отклонено");
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        logger.e("Разрешение на использование геолокации отклонено навсегда");
        return false;
      }
      
      logger.i("Разрешение на использование геолокации получено");
      return true;
    } catch (e) {
      logger.e("Ошибка при проверке разрешения на геолокацию: $e");
      return false;
    }
  }

  Future<void> disconnectWebsocket() async {
    if (newOrderSocket != null) {
      logger.i('Отключаем сокет водителя');
      try {
        // Останавливаем трекинг геопозиции
        onUserLocationChanged?.cancel();
        
        // Отключаем сокет
        newOrderSocket!.disconnect();
        newOrderSocket!.clearListeners();
        isWebsocketConnected.accept(false);
      } catch (e) {
        logger.e('Ошибка при отключении сокета: $e');
      }
    }
  }

  @override
  final StateNotifier<LocationPermission> locationPermission = StateNotifier();

  @override
  Future<void> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    locationPermission.accept(permission);
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      locationPermission.accept(permission);
      
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        logger.i("❌ Разрешения отклонены");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      logger.i("❌ Разрешения отклонены навсегда");
      openAppSettings();
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    
    logger.i("✅ Разрешения получены: $permission");
  }

  @override
  Future<void> registerOrderType() async {
    await Routes.router.navigate(Routes.driverRegistrationScreen);
    await fetchDriverRegisteredCategories();
    await fetchOrderRequests();
  }
}
