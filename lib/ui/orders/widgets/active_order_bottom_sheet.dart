import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'dart:math' as math;

import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart';
import 'package:aktau_go/interactors/order_requests_interactor.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart' as vg;
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/rendering.dart';
import 'package:geotypes/geotypes.dart' as geotypes;
import 'package:latlong2/latlong.dart' hide Position;

import '../../../core/colors.dart';
import '../../../core/images.dart';
import '../../../core/text_styles.dart';
import '../../widgets/primary_bottom_sheet.dart';
import '../orders_wm.dart';

class ActiveOrderBottomSheet extends StatefulWidget {
  final UserDomain me;
  final ActiveRequestDomain activeOrder;
  final VoidCallback onCancel;
  final StateNotifier<ActiveRequestDomain> activeOrderListener;
  final OrdersWM? ordersWm;

  const ActiveOrderBottomSheet({
    super.key,
    required this.me,
    required this.activeOrder,
    required this.onCancel,
    required this.activeOrderListener,
    this.ordersWm,
  });

  @override
  State<ActiveOrderBottomSheet> createState() => _ActiveOrderBottomSheetState();
}

class _ActiveOrderBottomSheetState extends State<ActiveOrderBottomSheet> {
  late ActiveRequestDomain activeRequest = widget.activeOrder;
  mapbox.MapboxMap? mapboxMapController;
  Map<String, dynamic> route = {};

  int waitingTimerLeft = 180;

  Timer? waitingTimer;
  Timer? mapUpdateTimer;
  StreamSubscription<Position>? positionStreamSubscription;

  bool isLoading = false;
  bool isOrderFinished = false;

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    
    print('🚀 ActiveOrderBottomSheet initState - статус: ${activeRequest.orderRequest?.orderStatus}');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.activeOrderListener.addListener(() {
        fetchActiveOrder();
      });
      
      // Добавляем слушатель позиции водителя для обновления карты
      _setupDriverPositionListener();

      // Добавляем слушателя позиции водителя из orders_wm
      widget.ordersWm?.driverPosition.addListener(() {
        final position = widget.ordersWm?.driverPosition.value;
        if (position != null && mounted && mapboxMapController != null) {
          addDriverMarker(position.latitude, position.longitude);
          print('📍 Позиция водителя обновлена из orders_wm: $position');
        }
      });
      
      // Запускаем таймер для периодического обновления карты
      _startMapUpdateTimer();
      
      // Получаем начальный маршрут ТОЛЬКО если карта еще не инициализирована
      // Иначе это будет сделано в onMapCreated
      if (mapboxMapController != null) {
        fetchActiveOrderRoute();
      }
    });
  }

  @override
  void dispose() {
    waitingTimer?.cancel();
    mapUpdateTimer?.cancel();
    positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchActiveOrder() async {
    try {
      final response = await inject<OrderRequestsInteractor>().getActiveOrder();

      activeRequest = response;

      String? sessionId = inject<SharedPreferences>().getString('sessionId');
      
      // Проверяем статус заказа
      if (activeRequest.orderRequest?.orderStatus == 'COMPLETED') {
        // Заказ завершен - закрываем окно
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      
      setState(() {});

      await fetchActiveOrderRoute();
    } on Exception catch (e) {
      print('Ошибка получения активного заказа: $e');
      // ИСПРАВЛЕНИЕ: Если нет активного заказа, закрываем окно
      if (mounted) {
        setState(() {
          isOrderFinished = true;
        });
        
        // Закрываем окно через небольшую задержку
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  Future<void> fetchActiveOrderRoute() async {
    final orderStatus = activeRequest.orderRequest?.orderStatus;
    
    print('🗺️ Обновление маршрута водителя для статуса: $orderStatus');
    
    // Очищаем все предыдущие элементы карты
    await clearAllMapElements();
    
    // Определяем откуда и куда строить маршрут в зависимости от статуса
    double fromLat, fromLng, toLat, toLng;
    String routeDescription;
    
    try {
      // Получаем текущее местоположение водителя
      final driverPosition = await _getCurrentDriverPosition();
      if (driverPosition == null) {
        print('⚠️ Не удалось получить позицию водителя');
        return;
      }
      
      // Координаты клиента (точка А)
      final clientLat = activeRequest.orderRequest!.lat.toDouble();
      final clientLng = activeRequest.orderRequest!.lng.toDouble();
      
      // Координаты назначения (точка Б) - парсим из toMapboxId
      double destinationLat, destinationLng;
      try {
        final toCoords = activeRequest.orderRequest!.toMapboxId.split(';');
        if (toCoords.length >= 2) {
          destinationLat = double.tryParse(toCoords[0]) ?? 0.0;
          destinationLng = double.tryParse(toCoords[1]) ?? 0.0;
        } else {
          destinationLat = clientLat + 0.01;
          destinationLng = clientLng + 0.01;
        }
      } catch (e) {
        print('⚠️ Ошибка парсинга координат назначения, используем fallback');
        destinationLat = clientLat + 0.01;
        destinationLng = clientLng + 0.01;
      }
      
      // ВАЖНО: Для водителя логика отображения отличается от клиента
      switch (orderStatus) {
        case 'CREATED':
          // Показываем полный маршрут от клиента до назначения (для понимания заказа)
          fromLat = clientLat;
          fromLng = clientLng;
          toLat = destinationLat;
          toLng = destinationLng;
          routeDescription = 'Маршрут заказа';
          print('📍 CREATED: Показываем полный маршрут заказа');
          break;
          
        case 'STARTED':
        case 'ACCEPTED':
          // Водитель едет к клиенту - маршрут от водителя до клиента
          fromLat = driverPosition.latitude;
          fromLng = driverPosition.longitude;
          toLat = clientLat;
          toLng = clientLng;
          routeDescription = 'Маршрут к клиенту';
          print('📍 STARTED: Водитель (${fromLat}, ${fromLng}) → Клиент (${toLat}, ${toLng})');
          break;
          
        case 'WAITING':
          // Водитель на месте, показываем только маркер водителя без маршрута
          print('📍 WAITING: Водитель на месте, показываем только маркер');
          // Добавляем маркер водителя
          await addDriverMarker(driverPosition.latitude, driverPosition.longitude);
          // Добавляем маркер назначения
          await addStaticMarkers([
            {'lat': destinationLat, 'lng': destinationLng, 'type': 'point_b'},
          ]);
          // Центрируем карту на водителе
          await mapboxMapController!.flyTo(
            mapbox.CameraOptions(
              center: mapbox.Point(coordinates: mapbox.Position(driverPosition.longitude, driverPosition.latitude)),
              zoom: 16.0,
              padding: mapbox.MbxEdgeInsets(top: 100, left: 50, bottom: 300, right: 50),
            ),
            mapbox.MapAnimationOptions(duration: 1000),
          );
          return; // Выходим, так как маршрут не нужен
          
        case 'ONGOING':
          // Едем с клиентом - маршрут от текущей позиции водителя до назначения
          fromLat = driverPosition.latitude;
          fromLng = driverPosition.longitude;
          toLat = destinationLat;
          toLng = destinationLng;
          routeDescription = 'Маршрут к пункту назначения';
          print('📍 ONGOING: Водитель → Назначение');
          break;
          
        default:
          // По умолчанию показываем маршрут от клиента до назначения
          fromLat = clientLat;
          fromLng = clientLng;
          toLat = destinationLat;
          toLng = destinationLng;
          routeDescription = 'Маршрут поездки';
          print('📍 DEFAULT: Клиент → Назначение');
          break;
      }
      
      print('   Строим маршрут: От ($fromLat, $fromLng) До ($toLat, $toLng)');
      
      // Получаем маршрут от Mapbox
      final directions = await inject<MapboxApi>().getDirections(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );

      setState(() {
        route = directions;
      });

      if (mapboxMapController != null && route.isNotEmpty) {
        try {
          // 1. Сначала добавляем маршрут на карту
          await addRouteToMap();
          
          // 2. Затем добавляем маркеры в правильном порядке
          if (orderStatus == 'STARTED' || orderStatus == 'ACCEPTED') {
            await addStaticMarkers([
              {'lat': clientLat, 'lng': clientLng, 'type': 'point_a'},
            ]);
            await addDriverMarker(driverPosition.latitude, driverPosition.longitude);
          } else if (orderStatus == 'ONGOING') {
            await addStaticMarkers([
              {'lat': destinationLat, 'lng': destinationLng, 'type': 'point_b'},
            ]);
            await addDriverMarker(driverPosition.latitude, driverPosition.longitude);
          } else {
            await addStaticMarkers([
              {'lat': clientLat, 'lng': clientLng, 'type': 'point_a'},
              {'lat': destinationLat, 'lng': destinationLng, 'type': 'point_b'},
            ]);
          }
          
          // 3. Центрируем камеру на маршруте только при первом показе
          final currentCamera = await mapboxMapController!.getCameraState();
          if (currentCamera.zoom == null || currentCamera.zoom! < 14) {
            // Если зум далекий, подгоняем под маршрут
            await fitRouteInView();
          }
          
          print('✅ $routeDescription обновлен успешно');
        } catch (e) {
          print('❌ Ошибка добавления маршрута на карту: $e');
        }
      }
      
    } catch (e) {
      print('❌ Ошибка получения маршрута: $e');
      // Fallback: показываем маршрут клиент → назначение
      await _showFallbackRoute();
    }
  }
  
  // Новый метод для добавления маркеров в зависимости от статуса
  Future<void> addMarkersBasedOnStatus(
    String orderStatus,
    Position driverPosition,
    double clientLat,
    double clientLng,
    double destinationLat,
    double destinationLng,
  ) async {
    print('🎯 Добавляем маркеры для статуса: $orderStatus');
    
    // ВСЕГДА показываем водителя как машинку (во всех статусах)
    await addDriverMarker(driverPosition.latitude, driverPosition.longitude);
    
    switch (orderStatus) {
      case 'CREATED':
        // Показываем точки А и Б для понимания маршрута (без водителя)
        await addStaticMarkers([
          {'lat': clientLat, 'lng': clientLng, 'type': 'point_a'},
          {'lat': destinationLat, 'lng': destinationLng, 'type': 'point_b'},
        ]);
        break;
        
      case 'STARTED':
        // Водитель едет к клиенту - показываем только точку А (клиент)
        await addStaticMarkers([
          {'lat': clientLat, 'lng': clientLng, 'type': 'point_a'},
        ]);
        break;
        
      case 'WAITING':
      case 'ONGOING':
        // Водитель с клиентом - показываем только точку Б (назначение)
        await addStaticMarkers([
          {'lat': destinationLat, 'lng': destinationLng, 'type': 'point_b'},
        ]);
        break;
        
      default:
        // По умолчанию показываем обе точки
        await addStaticMarkers([
          {'lat': clientLat, 'lng': clientLng, 'type': 'point_a'},
          {'lat': destinationLat, 'lng': destinationLng, 'type': 'point_b'},
        ]);
        break;
    }
    
    print('✅ Маркеры добавлены для статуса $orderStatus');
  }
  
  // Новый метод для очистки всех элементов карты
  Future<void> clearAllMapElements() async {
    try {
      if (mapboxMapController == null) return;
      
      // Удаляем все слои и источники
      final layersToRemove = [
        'route-layer',
        'route-outline-layer',
        'driver-marker-layer',
        'client-marker-layer',
        'destination-marker-layer',
        'live-driver-marker-layer',
      ];
      
      final sourcesToRemove = [
        'route-source',
        'driver-marker-source',
        'client-marker-source',
        'destination-marker-source',
        'live-driver-marker-source',
      ];
      
      // Удаляем слои
      for (final layerId in layersToRemove) {
        try {
          if (await mapboxMapController!.style.styleLayerExists(layerId)) {
            await mapboxMapController!.style.removeStyleLayer(layerId);
          }
        } catch (e) {
          // Игнорируем ошибки при удалении отдельных слоев
        }
      }
      
      // Удаляем источники
      for (final sourceId in sourcesToRemove) {
        try {
          if (await mapboxMapController!.style.styleSourceExists(sourceId)) {
            await mapboxMapController!.style.removeStyleSource(sourceId);
          }
        } catch (e) {
          // Игнорируем ошибки при удалении отдельных источников
        }
      }
    } catch (e) {
      print('❌ Ошибка очистки карты: $e');
    }
  }
  
  // Новый метод для добавления статических маркеров (точки А и Б)
  Future<void> addStaticMarkers(List<Map<String, dynamic>> markers) async {
    if (mapboxMapController == null || markers.isEmpty) return;
    
    try {
      // Сначала удаляем существующие слои статических маркеров
      if (await mapboxMapController!.style.styleLayerExists('start-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('start-marker-layer');
      }
      if (await mapboxMapController!.style.styleLayerExists('end-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('end-marker-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('static-markers-source')) {
        await mapboxMapController!.style.removeStyleSource('static-markers-source');
      }
      
      List<Map<String, dynamic>> features = [];
      
      for (final marker in markers) {
        features.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [marker['lng'], marker['lat']]
          },
          "properties": {
            "type": marker['type']
          }
        });
      }
      
      // Добавляем источник для маркеров
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'static-markers-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": features
        }),
      ));
      
      // Добавляем слой для точки А
      if (markers.any((m) => m['type'] == 'point_a')) {
        await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
          id: 'start-marker-layer',
          sourceId: 'static-markers-source',
          filter: ['==', ['get', 'type'], 'point_a'],
          iconImage: 'point_a',
          iconSize: 0.5, // Увеличиваем размер
          iconAllowOverlap: true,
          symbolSortKey: 1.0, // Низкий приоритет
        ));
      }
      
      // Добавляем слой для точки Б
      if (markers.any((m) => m['type'] == 'point_b')) {
        await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
          id: 'end-marker-layer',
          sourceId: 'static-markers-source',
          filter: ['==', ['get', 'type'], 'point_b'],
          iconImage: 'point_b',
          iconSize: 0.5, // Увеличиваем размер
          iconAllowOverlap: true,
          symbolSortKey: 1.0, // Низкий приоритет
        ));
      }
      
      print('✅ Статические маркеры добавлены: ${markers.map((m) => m['type']).join(', ')}');
    } catch (e) {
      print('❌ Ошибка добавления статических маркеров: $e');
    }
  }

  // Получение текущего местоположения водителя
  Future<Position?> _getCurrentDriverPosition() async {
    try {
      // Сначала пробуем использовать последнюю известную позицию
      if (_currentPosition != null) {
        return _currentPosition;
      }
      
      // Если нет последней известной позиции, запрашиваем текущую
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          return null;
        }
      }
      
      // Получаем текущую позицию
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );
      
      // Сохраняем позицию
      _currentPosition = position;
      return position;
    } catch (e) {
      print('❌ Ошибка получения позиции водителя: $e');
      return null;
    }
  }
  
  // Резервный маршрут (клиент → назначение)
  Future<void> _showFallbackRoute() async {
    try {
      final directions = await inject<MapboxApi>().getDirections(
        fromLat: activeRequest.orderRequest!.lat.toDouble(),
        fromLng: activeRequest.orderRequest!.lng.toDouble(),
        toLat: double.parse(activeRequest.orderRequest!.toMapboxId.split(';')[0]),
        toLng: double.parse(activeRequest.orderRequest!.toMapboxId.split(';')[1]),
      );

      setState(() {
        route = directions;
      });

      if (mapboxMapController != null && route.isNotEmpty) {
        await addRouteToMap();
        await addMarkersToMap();
        await fitRouteInView();
        print('✅ Резервный маршрут отображен');
      }
    } catch (e) {
      print('❌ Ошибка отображения резервного маршрута: $e');
    }
  }

  Future<void> addRouteToMap() async {
    if (mapboxMapController == null || route.isEmpty) return;

    try {
      // Remove existing route layers if they exist
      if (await mapboxMapController!.style.styleLayerExists('route-layer')) {
        await mapboxMapController!.style.removeStyleLayer('route-layer');
      }
      if (await mapboxMapController!.style.styleLayerExists('route-outline-layer')) {
        await mapboxMapController!.style.removeStyleLayer('route-outline-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('route-source')) {
        await mapboxMapController!.style.removeStyleSource('route-source');
      }

      // Create GeoJSON LineString from route geometry
      final routeGeometry = route['routes'][0]['geometry'];
      final lineString = {
        "type": "Feature",
        "geometry": routeGeometry,
        "properties": {}
      };

      // Add source for the route
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'route-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [lineString]
        }),
      ));

      // Add outline layer for the route (для контраста)
      await mapboxMapController!.style.addLayer(mapbox.LineLayer(
        id: 'route-outline-layer',
        sourceId: 'route-source',
        lineColor: 0xFF1565C0, // Темно-синий контур
        lineWidth: 8.0,
        lineOpacity: 0.8,
        lineCap: mapbox.LineCap.ROUND,
        lineJoin: mapbox.LineJoin.ROUND,
      ));

      // Add main line layer for the route
      await mapboxMapController!.style.addLayer(mapbox.LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: 0xFF2196F3, // Яркий синий
        lineWidth: 5.0,
        lineOpacity: 1.0,
        lineCap: mapbox.LineCap.ROUND,
        lineJoin: mapbox.LineJoin.ROUND,
      ));
      
      print('✅ Маршрут добавлен на карту');
    } catch (e) {
      print('❌ Ошибка добавления маршрута: $e');
    }
  }

  Future<void> addMarkersToMap() async {
    // Этот метод больше не используется - используйте addMarkersBasedOnStatus
    return;
  }

  Future<void> arrivedDriver() async {
    setState(() {
      isLoading = false;
    });
    try {
      await inject<OrderRequestsInteractor>().arrivedOrderRequest(
        driver: widget.me,
        orderRequest: widget.activeOrder.orderRequest!,
      );

      waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (waitingTimerLeft > 0) {
          setState(() {
            waitingTimerLeft--;
          });
        } else {
          rejectOrder();
          timer.cancel();
        }
      });

      fetchActiveOrder();
    } on Exception catch (e) {
      // TODO
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> rejectOrder() async {
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
                        await inject<OrderRequestsInteractor>().rejectOrderRequest(
                          orderRequestId: widget.activeOrder.orderRequest!.id,
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

  Future<void> startDrive() async {
    setState(() {
      isLoading = true;
    });
    try {
      await inject<OrderRequestsInteractor>().startOrderRequest(
        driver: widget.me,
        orderRequest: widget.activeOrder.orderRequest!,
      );
      waitingTimer?.cancel();
      fetchActiveOrder();
    } on Exception catch (e) {
      // TODO
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> endDrive() async {
    setState(() {
      isLoading = true;
    });
    try {
      await inject<OrderRequestsInteractor>().endOrderRequest(
        driver: widget.me,
        orderRequest: widget.activeOrder.orderRequest!,
      );
      fetchActiveOrder();
    } on Exception catch (e) {
      // TODO
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fitRouteInView() async {
    if (mapboxMapController == null || route.isEmpty) {
      print('⚠️ Невозможно подогнать камеру: controller или route отсутствуют');
      return;
    }

    try {
      // Получаем координаты маршрута
      final routeCoordinates = route['routes'][0]['geometry']['coordinates'] as List;
      if (routeCoordinates.isEmpty) return;
      
      // Находим границы маршрута
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;
      
      for (var coord in routeCoordinates) {
        final lng = coord[0] as double;
        final lat = coord[1] as double;
        
        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
        minLng = math.min(minLng, lng);
        maxLng = math.max(maxLng, lng);
      }
      
      // Добавляем отступы к границам (20% от размера)
      final latPadding = (maxLat - minLat) * 0.25;
      final lngPadding = (maxLng - minLng) * 0.25;
      
      minLat -= latPadding;
      maxLat += latPadding;
      minLng -= lngPadding;
      maxLng += lngPadding;
      
      // Центр маршрута
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      // Рассчитываем расстояние между точками
      final distance = _calculateDistance(minLat, minLng, maxLat, maxLng);
      
      // Определяем уровень зума в зависимости от расстояния
      // Используем более близкий зум по умолчанию
      double zoom;
      if (distance < 0.3) {
        zoom = 17.0; // Очень близко
      } else if (distance < 0.5) {
        zoom = 16.5;
      } else if (distance < 0.8) {
        zoom = 16.0;
      } else if (distance < 1.2) {
        zoom = 15.5;
      } else if (distance < 2.0) {
        zoom = 15.0;
      } else if (distance < 3.0) {
        zoom = 14.5;
      } else if (distance < 5.0) {
        zoom = 14.0;
      } else if (distance < 8.0) {
        zoom = 13.5;
      } else if (distance < 12.0) {
        zoom = 13.0;
      } else if (distance < 20.0) {
        zoom = 12.5;
      } else if (distance < 30.0) {
        zoom = 12.0;
      } else if (distance < 50.0) {
        zoom = 11.5;
      } else {
        zoom = 11.0; // Далеко
      }
      
      print('📏 Расстояние: ${distance.toStringAsFixed(2)} км, Зум: $zoom');
      
      // Проверяем текущий зум камеры
      final currentCamera = await mapboxMapController!.getCameraState();
      final currentZoom = currentCamera.zoom;
      
      // Если пользователь приблизил карту вручную, не отдаляем автоматически
      if (currentZoom != null && currentZoom > zoom) {
        print('🔍 Сохраняем текущий зум пользователя: $currentZoom');
        zoom = currentZoom;
      }
      
      // Анимированный переход камеры только если нужно
      await mapboxMapController!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(centerLng, centerLat)),
          zoom: zoom,
          padding: mapbox.MbxEdgeInsets(
            top: 80,
            left: 40,
            bottom: 300, // Больше отступа снизу для bottom sheet
            right: 40,
          ),
        ),
        mapbox.MapAnimationOptions(
          duration: 800, // Быстрая анимация
          startDelay: 0,
        ),
      );
      
      print('✅ Камера настроена на маршрут');
    } catch (e) {
      print('❌ Ошибка настройки камеры: $e');
    }
  }
  
  // Вспомогательный метод для расчета расстояния между двумя точками
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Радиус Земли в километрах
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final orderStatus = activeRequest.orderRequest?.orderStatus ?? '';
    
    return PopScope(
      canPop: false,
      child: Container(
        height: MediaQuery.of(context).size.height, // Занимаем почти весь экран
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Полоска для перетаскивания
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Карта занимает большую часть экрана
            Expanded(
              child: Stack(
                children: [
                  // Карта Mapbox
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: mapbox.MapWidget(
                      key: ValueKey("driver_active_order_map"),
                      cameraOptions: mapbox.CameraOptions(
                        center: mapbox.Point(
                          coordinates: geotypes.Position(
                            activeRequest.orderRequest?.lng ?? 0,
                            activeRequest.orderRequest?.lat ?? 0,
                          ),
                        ),
                        zoom: 15.0, // Начальный зум ближе
                      ),
                      onMapCreated: (mapboxController) async {
                        print('🗺️ Карта водителя создана');
                        mapboxMapController = mapboxController;
                        
                        try {
                          // Ждем инициализации карты
                          await Future.delayed(Duration(milliseconds: 300));
                          
                          // Настраиваем жесты карты
                          await mapboxController.gestures.updateSettings(
                            mapbox.GesturesSettings(
                              rotateEnabled: true,
                              scrollEnabled: true,
                              pitchEnabled: true,
                              doubleTapToZoomInEnabled: true,
                              doubleTouchToZoomOutEnabled: true,
                              quickZoomEnabled: true,
                              pinchToZoomEnabled: true,
                            ),
                          );
                          
                          print('✅ Жесты карты включены');
                          
                          // Загружаем изображения маркеров
                          await addImageFromAsset('point_a', 'assets/images/point_a.png');
                          await addImageFromAsset('point_b', 'assets/images/point_b.png');
                          
                          // Небольшая задержка для полной инициализации
                          await Future.delayed(Duration(milliseconds: 200));
                          
                          // Загружаем и отображаем маршрут
                          await fetchActiveOrderRoute();
                          
                          print('✅ Начальный маршрут загружен');
                        } catch (e) {
                          print('❌ Ошибка инициализации карты: $e');
                        }
                      },
                    ),
                  ),
                
                ],
              ),
            ),
            
            // Нижняя панель с информацией и кнопками
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Информация о маршруте
                  _buildRouteSection(),
                  
                  SizedBox(height: 16),
                  
                  // Информация о клиенте и стоимости
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.account_circle,
                          title: 'Клиент',
                          value: activeRequest.whatsappUser?.fullName ?? 'Неизвестно',
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.payments,
                          title: 'Стоимость',
                          value: '${NumUtils.humanizeNumber(activeRequest.orderRequest?.price, isCurrency: true) ?? '0'}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Кнопки действий
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Откуда',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    activeRequest.orderRequest?.from ?? 'Не указано',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        Container(
          margin: EdgeInsets.only(left: 6, top: 8, bottom: 8),
          width: 2,
          height: 20,
          color: Colors.grey.shade300,
        ),
        
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Куда',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    activeRequest.orderRequest?.to ?? 'Не указано',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final orderStatus = activeRequest.orderRequest?.orderStatus ?? '';
    
    if (orderStatus == 'CREATED') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : () async {
                await startDrive();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Начать поездку',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Назад',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await inject<OrderRequestsInteractor>().rejectOrderRequest(
                      orderRequestId: widget.activeOrder.orderRequest!.id,
                    );
                    fetchActiveOrder();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Отменить',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (orderStatus == 'STARTED') ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : waitForClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Я на месте',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (orderStatus == 'WAITING') ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : startTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Начать поездку',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (orderStatus == 'ONGOING') ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : finishTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Завершить поездку',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          SizedBox(height: 12),
          
          // Кнопка звонка клиенту
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _callClient(activeRequest.whatsappUser?.phone),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Позвонить клиенту',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'CREATED':
        return {
          'title': 'Заказ принят',
          'subtitle': 'Начните движение к клиенту',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case 'STARTED':
        return {
          'title': 'В пути к клиенту',
          'subtitle': 'Доберитесь до места посадки',
          'icon': Icons.directions_car,
          'color': Colors.blue,
        };
      case 'WAITING':
        return {
          'title': 'Ожидание клиента',
          'subtitle': 'Клиент должен подойти к автомобилю',
          'icon': Icons.timer,
          'color': Colors.orange,
        };
      case 'ONGOING':
        return {
          'title': 'Поездка началась',
          'subtitle': 'Везите клиента к месту назначения',
          'icon': Icons.directions,
          'color': primaryColor,
        };
      default:
        return {
          'title': 'Заказ',
          'subtitle': 'Обработка заказа',
          'icon': Icons.info,
          'color': Colors.grey,
        };
    }
  }

  Future<void> _callClient(String? phoneNumber) async {
    if (phoneNumber == null) return;
    
    final url = 'tel:$phoneNumber';
    try {
      await launchUrlString(url);
    } catch (e) {
      print('Ошибка при попытке позвонить: $e');
    }
  }

  // Методы для управления заказом
  Future<void> waitForClient() async {
    setState(() {
      isLoading = true;
    });
    try {
      await inject<OrderRequestsInteractor>().arrivedOrderRequest(
        driver: widget.me,
        orderRequest: widget.activeOrder.orderRequest!,
      );

      waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (waitingTimerLeft > 0) {
          setState(() {
            waitingTimerLeft--;
          });
        } else {
          rejectOrder();
          timer.cancel();
        }
      });

      fetchActiveOrder();
    } on Exception catch (e) {
      // TODO
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> startTrip() async {
    setState(() {
      isLoading = true;
    });
    try {
      await inject<OrderRequestsInteractor>().startOrderRequest(
        driver: widget.me,
        orderRequest: widget.activeOrder.orderRequest!,
      );
      waitingTimer?.cancel();
      fetchActiveOrder();
    } on Exception catch (e) {
      // TODO
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> finishTrip() async {
    setState(() {
      isLoading = true;
    });
    try {
      await inject<OrderRequestsInteractor>().endOrderRequest(
        driver: widget.me,
        orderRequest: widget.activeOrder.orderRequest!,
      );
      
      // ИСПРАВЛЕНИЕ: После завершения заказа закрываем окно
      if (mounted) {
        // Показываем уведомление об успешном завершении
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Поездка успешно завершена'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Закрываем окно активного заказа
        Navigator.of(context).pop();
        
        // Обновляем список заказов в главном экране
        // Это вызовет fetchActiveOrder в orders_wm.dart
      }
    } on Exception catch (e) {
      print('Ошибка при завершении поездки: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при завершении поездки'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Добавляем слушатель позиции водителя для обновления карты
  void _setupDriverPositionListener() {
    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Обновляем каждые 5 метров
      ),
    ).listen((Position position) {
      // Обновляем позицию водителя на карте
      if (mounted && mapboxMapController != null) {
        _currentPosition = position; // Сохраняем последнюю известную позицию
        addDriverMarker(position.latitude, position.longitude);
        print('📍 Позиция водителя обновлена: ${position.latitude}, ${position.longitude}');
      }
    });
  }

  // Запускаем таймер для периодического обновления карты
  void _startMapUpdateTimer() {
    mapUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        // Обновляем маршрут и маркеры
        fetchActiveOrderRoute();
        
        print('🔄 Автоматическое обновление карты');
      }
    });
  }

  // Добавить маркер водителя на карту
  Future<void> addDriverMarker(double lat, double lng) async {
    try {
      if (mapboxMapController == null) return;

      // Удаляем существующий маркер водителя
      if (await mapboxMapController!.style.styleLayerExists('live-driver-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('live-driver-marker-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('live-driver-marker-source')) {
        await mapboxMapController!.style.removeStyleSource('live-driver-marker-source');
      }
      
      // Проверяем, существует ли иконка водителя
      bool iconExists = false;
      try {
        iconExists = await mapboxMapController!.style.hasStyleImage('driver-car-icon');
        print('🔍 Проверка наличия иконки машины: $iconExists');
      } catch (e) {
        iconExists = false;
        print('⚠️ Ошибка проверки иконки: $e');
      }
      
      // Если иконка не существует, создаем ее
      if (!iconExists) {
        await createDriverLocationMarker();
      }
      
      // Создаем маркер позиции водителя
      final driverFeature = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [lng, lat]
        },
        "properties": {
          "id": "driver-marker",
          "icon": "driver-car-icon"
        }
      };
      
      // Добавляем источник для маркера водителя
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'live-driver-marker-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [driverFeature]
        }),
      ));
      
      // Добавляем слой для маркера водителя с высоким приоритетом
      await mapboxMapController!.style.addLayer(
        mapbox.SymbolLayer(
          id: 'live-driver-marker-layer',
          sourceId: 'live-driver-marker-source',
          iconImage: "driver-car-icon",
          iconSize: 1.0, // Увеличиваем размер машинки
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconRotationAlignment: mapbox.IconRotationAlignment.MAP,
          symbolZOrder: mapbox.SymbolZOrder.SOURCE, // Порядок отображения по z-index
        ),
      );
      
      print('✅ Маркер водителя (машинка) добавлен: $lat, $lng');
      
    } catch (e) {
      print('❌ Ошибка добавления маркера водителя: $e');
      
      // Если не удалось добавить маркер, пробуем создать fallback
      try {
        await createFallbackDriverIcon();
        
        // Создаем источник и слой заново
        final driverFeature = {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [lng, lat]
          },
          "properties": {
            "id": "driver-marker",
            "icon": "driver-car-icon"
          }
        };
        
        await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
          id: 'live-driver-marker-source',
          data: json.encode({
            "type": "FeatureCollection",
            "features": [driverFeature]
          }),
        ));
        
        await mapboxMapController!.style.addLayer(
          mapbox.SymbolLayer(
            id: 'live-driver-marker-layer',
            sourceId: 'live-driver-marker-source',
            iconImage: "driver-car-icon",
            iconSize: 1.0,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
          ),
        );
        
        print('✅ Fallback маркер водителя добавлен');
      } catch (fallbackError) {
        print('❌❌ Критическая ошибка при добавлении маркера водителя: $fallbackError');
      }
    }
  }

  // Создать кастомную иконку для водителя (машинка)
  Future<void> createDriverLocationMarker() async {
    try {
      // Проверяем, существует ли уже иконка
      if (await mapboxMapController?.style.hasStyleImage('driver-car-icon') == true) {
        print('✓ Иконка водителя уже существует');
        return;
      }
      
      // Попробуем загрузить изображение машинки из ассетов
      try {
        // Сначала пробуем загрузить PNG
        final ByteData pngData = await rootBundle.load('assets/images/car.png');
        
        // Преобразуем PNG данные
        final ui.Codec codec = await ui.instantiateImageCodec(
          pngData.buffer.asUint8List(),
          targetWidth: 80,
          targetHeight: 80,
        );
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ByteData? resizedData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
        
        if (resizedData == null) {
          throw Exception('Не удалось преобразовать PNG');
        }
        
        await mapboxMapController?.style.addStyleImage(
          'driver-car-icon',
          1.0,
          mapbox.MbxImage(
            width: 80,
            height: 80,
            data: resizedData.buffer.asUint8List(),
          ),
          false,
          [],
          [],
          null,
        );
        
        print('✅ PNG иконка машинки загружена');
        return;
      } catch (pngError) {
        print('⚠️ Ошибка загрузки PNG иконки: $pngError');
        // Если не удалось загрузить из ассетов, создаем программно
        throw Exception('Не удалось загрузить иконку из ассетов');
      }
    } catch (e) {
      print('❌ Ошибка создания иконки водителя: $e');
      await createFallbackDriverIcon();
    }
  }
  
  // Создаем fallback иконку водителя программно
  Future<void> createFallbackDriverIcon() async {
    try {
      final int size = 80; // Увеличиваем размер
      
      final pictureRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(pictureRecorder);
      
      // Белый круг фона с тенью
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
        
      // Обводка круга
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
        
      // Основной цвет машинки
      final carPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
        
      // Окна машинки
      final windowPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      // Рисуем тень
      canvas.drawCircle(
        ui.Offset(size / 2 + 2, size / 2 + 2), 
        size / 2 - 2, 
        shadowPaint
      );
      
      // Рисуем белый фон
      canvas.drawCircle(
        ui.Offset(size / 2, size / 2), 
        size / 2 - 2, 
        Paint()..color = Colors.white
      );
      
      // Рисуем обводку
      canvas.drawCircle(
        ui.Offset(size / 2, size / 2), 
        size / 2 - 4, 
        borderPaint
      );
      
      // Рисуем корпус машинки
      final ui.Path carBody = ui.Path();
      final double centerX = size / 2;
      final double centerY = size / 2;
      final double carWidth = size * 0.5;
      final double carHeight = size * 0.6;
      
      // Создаем форму машинки (вид сверху)
      carBody.moveTo(centerX - carWidth/2, centerY + carHeight/3);
      carBody.lineTo(centerX - carWidth/2, centerY - carHeight/4);
      carBody.quadraticBezierTo(
        centerX - carWidth/2, centerY - carHeight/2.5,
        centerX - carWidth/3, centerY - carHeight/2.5
      );
      carBody.lineTo(centerX + carWidth/3, centerY - carHeight/2.5);
      carBody.quadraticBezierTo(
        centerX + carWidth/2, centerY - carHeight/2.5,
        centerX + carWidth/2, centerY - carHeight/4
      );
      carBody.lineTo(centerX + carWidth/2, centerY + carHeight/3);
      carBody.quadraticBezierTo(
        centerX + carWidth/2, centerY + carHeight/2.5,
        centerX, centerY + carHeight/2.5
      );
      carBody.quadraticBezierTo(
        centerX - carWidth/2, centerY + carHeight/2.5,
        centerX - carWidth/2, centerY + carHeight/3
      );
      carBody.close();
      
      canvas.drawPath(carBody, carPaint);
      
      // Рисуем лобовое стекло
      final windshieldRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset(centerX, centerY - carHeight/4),
          width: carWidth * 0.7,
          height: carHeight * 0.15,
        ),
        ui.Radius.circular(2),
      );
      canvas.drawRRect(windshieldRect, windowPaint);
      
      // Рисуем боковые окна
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(
            center: ui.Offset(centerX - carWidth/3, centerY),
            width: carWidth * 0.15,
            height: carHeight * 0.3,
          ),
          ui.Radius.circular(2),
        ),
        windowPaint,
      );
      
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(
            center: ui.Offset(centerX + carWidth/3, centerY),
            width: carWidth * 0.15,
            height: carHeight * 0.3,
          ),
          ui.Radius.circular(2),
        ),
        windowPaint,
      );
      
      // Конвертируем в изображение
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List imageBytes = byteData!.buffer.asUint8List();
      
      // Создаем Mapbox изображение
      final mbxImage = mapbox.MbxImage(
        data: imageBytes,
        width: size,
        height: size,
      );
      
      // Добавляем в стиль карты
      await mapboxMapController?.style.addStyleImage(
        'driver-car-icon',
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );
      
      print('✅ Fallback иконка машинки создана программно');
    } catch (e) {
      print('❌ Ошибка создания fallback иконки водителя: $e');
    }
  }

  // Метод для загрузки изображений из ассетов
  Future<void> addImageFromAsset(String name, String assetName) async {
    try {
      // Create a small colored circle with text
      final int size = 40; // Slightly larger size
      
      // Create a canvas to draw the marker
      final pictureRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(pictureRecorder);
      
      // Background with border
      final bgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        
      final borderPaint = Paint()
        ..color = name == 'point_a' ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw circle with border
      canvas.drawCircle(ui.Offset(size / 2, size / 2), size / 2 - 3, bgPaint);
      canvas.drawCircle(ui.Offset(size / 2, size / 2), size / 2 - 3, borderPaint);
      
      // Add text
      final textStyle = TextStyle(
        color: name == 'point_a' ? Colors.green : Colors.red,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );
      
      final textSpan = TextSpan(
        text: name == 'point_a' ? 'A' : 'B',
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        ui.Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2)
      );
      
      // Convert to image
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List imageBytes = byteData!.buffer.asUint8List();
      
      // Create Mapbox image
      final mbxImage = mapbox.MbxImage(
        data: imageBytes,
        width: size,
        height: size,
      );
      
      // Add to map style
      await mapboxMapController?.style.addStyleImage(
        name,
        1.0, // Normal scale
        mbxImage,
        false, // sdf
        [], // stretchX
        [], // stretchY
        null, // content
      );
      
      print("Custom marker created: $name");
    } catch (e) {
      print("Error creating custom marker: $e");
      // Fallback to asset loading if custom creation fails
      try {
        final ByteData bytes = await rootBundle.load(assetName);
        final Uint8List list = bytes.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(list);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final image = frameInfo.image;
        
        final mbxImage = mapbox.MbxImage(
          data: list,
          height: image.height,
          width: image.width,
        );
        
        await mapboxMapController?.style.addStyleImage(
          name,
          0.5, // Normal scale
          mbxImage,
          false, // sdf
          [], // stretchX
          [], // stretchY
          null, // content
        );
      } catch (e) {
        print("Error loading marker asset: $e");
      }
    }
  }

  // Обновляет карту на стороне водителя в зависимости от статуса заказа
  Future<void> updateDriverMapBasedOnStatus(String orderStatus) async {
    try {
      if (mapboxMapController == null) return;
      print('🔄 Обновление карты водителя для статуса: $orderStatus');
      
      // Очищаем предыдущие маршруты и маркеры
      await clearAllMapElements();
      
      // Получаем координаты точек А и Б
      final fromCoords = parseMapboxCoordinates(widget.activeOrder.orderRequest?.fromMapboxId ?? '');
      final toCoords = parseMapboxCoordinates(widget.activeOrder.orderRequest?.toMapboxId ?? '');
      final driverPosition = await _getCurrentDriverPosition();
      
      if (fromCoords == null || toCoords == null) {
        print('⚠️ Не удалось получить координаты для маршрута');
        return;
      }
      
      print('📍 Точка А: ${fromCoords.lat}, ${fromCoords.lng}');
      print('📍 Точка Б: ${toCoords.lat}, ${toCoords.lng}');
      print('🚗 Позиция водителя: ${driverPosition?.latitude}, ${driverPosition?.longitude}');
      
      // Обрабатываем разные статусы заказа
      switch (orderStatus) {
        case 'CREATED':
          // Заказ создан, но еще не принят - показываем маршрут от водителя к клиенту
          if (driverPosition != null) {
            await displayRouteOnMap(
              LatLng(driverPosition.latitude, driverPosition.longitude),
              LatLng(fromCoords.lat.toDouble(), fromCoords.lng.toDouble()),
              showDriverMarker: true,
              showClientMarker: true,
              showDestinationMarker: false,
            );
          }
          break;
          
        case 'STARTED':
        case 'ACCEPTED':
          // Водитель едет к клиенту - показываем маршрут от водителя к точке А
          if (driverPosition != null) {
            await displayRouteOnMap(
              LatLng(driverPosition.latitude, driverPosition.longitude),
              LatLng(fromCoords.lat.toDouble(), fromCoords.lng.toDouble()),
              showDriverMarker: true,
              showClientMarker: true,
              showDestinationMarker: false,
            );
          }
          break;
          
        case 'WAITING':
          // Водитель ожидает клиента - показываем только маркеры водителя и клиента
          if (driverPosition != null) {
            // Добавляем маркер водителя
            await addDriverMarker(driverPosition.latitude, driverPosition.longitude);
            
            // Добавляем маркер клиента
            await addClientMarker(fromCoords.lat.toDouble(), fromCoords.lng.toDouble());
            
            // Центрируем карту между водителем и клиентом
            await _zoomToShowBounds(
              math.min(driverPosition.latitude, fromCoords.lat.toDouble()) - 0.01,
              math.min(driverPosition.longitude, fromCoords.lng.toDouble()) - 0.01,
              math.max(driverPosition.latitude, fromCoords.lat.toDouble()) + 0.01,
              math.max(driverPosition.longitude, fromCoords.lng.toDouble()) + 0.01
            );
          }
          break;
          
        case 'ONGOING':
          // Водитель везет клиента - показываем маршрут от водителя к точке Б
          if (driverPosition != null) {
            await displayRouteOnMap(
              LatLng(driverPosition.latitude, driverPosition.longitude),
              LatLng(toCoords.lat.toDouble(), toCoords.lng.toDouble()),
              showDriverMarker: true,
              showClientMarker: false,
              showDestinationMarker: true,
            );
          }
          break;
          
        case 'COMPLETED':
        case 'REJECTED':
        case 'REJECTED_BY_CLIENT':
        case 'REJECTED_BY_DRIVER':
          // Заказ завершен или отменен - очищаем карту
          await clearAllMapElements();
          break;
          
        default:
          print('⚠️ Неизвестный статус заказа: $orderStatus');
          break;
      }
    } catch (e) {
      print('❌ Ошибка обновления карты водителя: $e');
    }
  }

  // Парсит координаты из строки mapboxId формата "lat;lng"
  geotypes.Position? parseMapboxCoordinates(String mapboxId) {
    try {
      if (mapboxId.isEmpty) return null;
      
      final parts = mapboxId.split(';');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        
        if (lat != null && lng != null) {
          return geotypes.Position(lng, lat);
        }
      }
      return null;
    } catch (e) {
      print('❌ Ошибка парсинга координат: $e');
      return null;
    }
  }

  // Отображает маршрут на карте водителя
  Future<void> displayRouteOnMap(
    LatLng from,
    LatLng to,
    {
      bool showDriverMarker = true,
      bool showClientMarker = false,
      bool showDestinationMarker = false,
    }
  ) async {
    try {
      if (mapboxMapController == null) return;
      
      // Очищаем предыдущие маршруты
      await clearAllMapElements();
      
      // Получаем маршрут от Mapbox API
      final directions = await inject<MapboxApi>().getDirections(
        fromLat: from.latitude,
        fromLng: from.longitude,
        toLat: to.latitude,
        toLng: to.longitude,
      );
      
      if (directions == null || directions['routes'] == null || directions['routes'].isEmpty) {
        print('❌ Не удалось получить данные маршрута от API');
        return;
      }
      
      final routeGeometry = directions['routes'][0]['geometry'];
      
      // Добавляем источник маршрута
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'route-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [{
            "type": "Feature",
            "geometry": routeGeometry,
            "properties": {}
          }]
        }),
      ));
      
      // Добавляем слой контура маршрута
      await mapboxMapController!.style.addLayer(mapbox.LineLayer(
        id: 'route-outline-layer',
        sourceId: 'route-source',
        lineColor: Colors.black.value,
        lineWidth: 6.0,
        lineOpacity: 0.5,
      ));
      
      // Добавляем слой маршрута
      await mapboxMapController!.style.addLayer(mapbox.LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: primaryColor.value,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      ));
      
      // Добавляем маркеры
      if (showDriverMarker && _currentPosition != null) {
        await addDriverMarker(_currentPosition!.latitude, _currentPosition!.longitude);
      }
      
      if (showClientMarker) {
        await addClientMarker(to.latitude, to.longitude);
      }
      
      if (showDestinationMarker) {
        await addDestinationMarker(to.latitude, to.longitude);
      }
      
      // Настраиваем камеру, чтобы показать весь маршрут
      await _zoomToShowBounds(
        math.min(from.latitude, to.latitude) - 0.01,
        math.min(from.longitude, to.longitude) - 0.01,
        math.max(from.latitude, to.latitude) + 0.01,
        math.max(from.longitude, to.longitude) + 0.01
      );
      
    } catch (e) {
      print('❌ Ошибка отображения маршрута на карте: $e');
    }
  }

  // Добавляет маркер клиента на карту
  Future<void> addClientMarker(double lat, double lng) async {
    try {
      if (mapboxMapController == null) return;
      
      // Удаляем существующий маркер клиента
      if (await mapboxMapController!.style.styleLayerExists('client-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('client-marker-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('client-marker-source')) {
        await mapboxMapController!.style.removeStyleSource('client-marker-source');
      }
      
      // Создаем маркер клиента
      final clientPoint = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [lng, lat]
        },
        "properties": {
          "marker-symbol": "client-marker"
        }
      };
      
      // Добавляем источник для маркера клиента
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'client-marker-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [clientPoint]
        }),
      ));
      
      // Проверяем, загружена ли иконка клиента
      await createClientMarkerIcon();
      
      // Добавляем слой для маркера клиента
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'client-marker-layer',
        sourceId: 'client-marker-source',
        iconImage: "client-marker-icon",
        iconSize: 0.8,
        iconAllowOverlap: true,
        iconAnchor: mapbox.IconAnchor.BOTTOM,
      ));
      
    } catch (e) {
      print('❌ Ошибка добавления маркера клиента: $e');
    }
  }

  // Создает иконку маркера клиента
  Future<void> createClientMarkerIcon() async {
    try {
      if (mapboxMapController == null) return;
      
      // Создаем простую круглую иконку для клиента
      final size = 48.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Рисуем зеленый круг с белой окантовкой
      final paint = Paint()..color = Colors.green;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
      
      // Добавляем белую окантовку
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, borderPaint);
      
      // Создаем изображение из рисунка
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        await mapboxMapController!.style.addStyleImage(
          "client-marker-icon",
          1.0,
          mapbox.MbxImage(
            width: size.toInt(),
            height: size.toInt(),
            data: byteData.buffer.asUint8List(),
          ),
          false,
          [],
          [],
          null,
        );
      }
    } catch (e) {
      print('❌ Ошибка создания иконки маркера клиента: $e');
    }
  }

  // Добавляет маркер пункта назначения на карту
  Future<void> addDestinationMarker(double lat, double lng) async {
    try {
      if (mapboxMapController == null) return;
      
      // Удаляем существующий маркер пункта назначения
      if (await mapboxMapController!.style.styleLayerExists('destination-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('destination-marker-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('destination-marker-source')) {
        await mapboxMapController!.style.removeStyleSource('destination-marker-source');
      }
      
      // Создаем маркер пункта назначения
      final destinationPoint = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [lng, lat]
        },
        "properties": {
          "marker-symbol": "destination-marker"
        }
      };
      
      // Добавляем источник для маркера пункта назначения
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'destination-marker-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [destinationPoint]
        }),
      ));
      
      // Проверяем, загружена ли иконка пункта назначения
      await createDestinationMarkerIcon();
      
      // Добавляем слой для маркера пункта назначения
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'destination-marker-layer',
        sourceId: 'destination-marker-source',
        iconImage: "destination-marker-icon",
        iconSize: 0.8,
        iconAllowOverlap: true,
        iconAnchor: mapbox.IconAnchor.BOTTOM,
      ));
      
    } catch (e) {
      print('❌ Ошибка добавления маркера пункта назначения: $e');
    }
  }

  // Создает иконку маркера пункта назначения
  Future<void> createDestinationMarkerIcon() async {
    try {
      if (mapboxMapController == null) return;
      
      // Создаем простую круглую иконку для пункта назначения
      final size = 48.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Рисуем красный круг с белой окантовкой
      final paint = Paint()..color = Colors.red;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
      
      // Добавляем белую окантовку
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, borderPaint);
      
      // Создаем изображение из рисунка
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        await mapboxMapController!.style.addStyleImage(
          "destination-marker-icon",
          1.0,
          mapbox.MbxImage(
            width: size.toInt(),
            height: size.toInt(),
            data: byteData.buffer.asUint8List(),
          ),
          false,
          [],
          [],
          null,
        );
      }
    } catch (e) {
      print('❌ Ошибка создания иконки маркера пункта назначения: $e');
    }
  }

  Future<void> _fitCameraToBounds(double minLat, double minLng, double maxLat, double maxLng) async {
    try {
      if (mapboxMapController == null) return;
      
      // Добавляем небольшой отступ
      const padding = 0.01;
      
      // Настраиваем камеру
      await mapboxMapController!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(
            (minLng + maxLng) / 2,
            (minLat + maxLat) / 2,
          )),
          zoom: 14.0,
          padding: mapbox.MbxEdgeInsets(top: 100, left: 50, bottom: 300, right: 50),
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );

    } catch (e) {
      print('❌ Ошибка настройки камеры: $e');
    }
  }

  Future<void> _zoomToShowBounds(double minLat, double minLng, double maxLat, double maxLng) async {
    try {
      if (mapboxMapController == null) return;
      
      // Центр области
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      // Рассчитываем расстояние для определения зума
      final distance = _calculateDistance(minLat, minLng, maxLat, maxLng);
      
      // Определяем зум в зависимости от расстояния
      double zoom;
      if (distance < 0.5) zoom = 16.0;
      else if (distance < 1) zoom = 15.5;
      else if (distance < 2) zoom = 15.0;
      else if (distance < 5) zoom = 14.0;
      else if (distance < 10) zoom = 13.0;
      else zoom = 12.0;
      
      // Анимируем камеру
      await mapboxMapController!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(centerLng, centerLat)),
          zoom: zoom,
          padding: mapbox.MbxEdgeInsets(top: 100, left: 50, bottom: 300, right: 50),
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
      
      print('✅ Камера настроена на границы маршрута');
    } catch (e) {
      print('❌ Ошибка настройки камеры: $e');
    }
  }

  Future<void> _displayDynamicRoute(
    mapbox.MapboxMap mapboxController,
    geotypes.Position fromPos,
    geotypes.Position toPos,
    String description,
  ) async {
    try {
      // Получаем маршрут от Mapbox API
      final directions = await inject<MapboxApi>().getDirections(
        fromLat: fromPos.lat.toDouble(),
        fromLng: fromPos.lng.toDouble(),
        toLat: toPos.lat.toDouble(),
        toLng: toPos.lng.toDouble(),
      );
      
      if (directions == null || directions['routes'] == null || directions['routes'].isEmpty) {
        print('❌ Не удалось получить данные маршрута от API');
        return;
      }
      
      final routeGeometry = directions['routes'][0]['geometry'];
      
      // Очищаем предыдущие маршруты
      await clearAllMapElements();
      
      // Добавляем источник маршрута
      await mapboxController.style.addSource(mapbox.GeoJsonSource(
        id: 'dynamic-route-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [{
            "type": "Feature",
            "geometry": routeGeometry,
            "properties": {}
          }]
        }),
      ));
      
      // Добавляем слой маршрута
      await mapboxController.style.addLayer(mapbox.LineLayer(
        id: 'dynamic-route-layer',
        sourceId: 'dynamic-route-source',
        lineColor: primaryColor.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
      
      // Настраиваем камеру для показа маршрута
      await _zoomToShowBounds(
        math.min(fromPos.lat.toDouble(), toPos.lat.toDouble()) - 0.01,
        math.min(fromPos.lng.toDouble(), toPos.lng.toDouble()) - 0.01,
        math.max(fromPos.lat.toDouble(), toPos.lat.toDouble()) + 0.01,
        math.max(fromPos.lng.toDouble(), toPos.lng.toDouble()) + 0.01
      );
      
      print('✅ Динамический маршрут $description добавлен');
    } catch (e) {
      print('❌ Ошибка отображения динамического маршрута: $e');
    }
  }
}
