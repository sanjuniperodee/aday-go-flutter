import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/interactors/order_requests_interactor.dart';
import 'package:aktau_go/models/order_request/order_request_response_model.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../domains/order_request/order_request_domain.dart';
import '../../../core/colors.dart';
import '../../../core/images.dart';
import '../../../utils/num_utils.dart';
import '../../widgets/primary_bottom_sheet.dart';

class OrderRequestBottomSheet extends StatefulWidget {
  final OrderRequestDomain orderRequest;
  final Function onAccept;

  const OrderRequestBottomSheet({
    super.key,
    required this.orderRequest,
    required this.onAccept,
  });

  @override
  State<OrderRequestBottomSheet> createState() => _OrderRequestBottomSheetState();
}

class _OrderRequestBottomSheetState extends State<OrderRequestBottomSheet> {
  mapbox.MapboxMap? mapboxMapController;
  Map<String, dynamic> route = {};
  bool isLoading = false;
  bool isOrderCancelled = false;
  IO.Socket? socket;
  Timer? _orderStatusTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize order monitoring
    _initializeOrderMonitoring();
    
    // Fetch route data with slight delay to ensure proper initialization
    Future.delayed(Duration(milliseconds: 100), () {
      fetchActiveOrderRoute();
    });
  }

  @override
  void dispose() {
    _orderStatusTimer?.cancel();
    socket?.disconnect();
    super.dispose();
  }

  // Инициализация мониторинга заказа
  void _initializeOrderMonitoring() {
    // Подключаемся к WebSocket для получения обновлений в реальном времени
    _connectToSocket();
    
    // Также запускаем периодическую проверку статуса заказа
    _startOrderStatusPolling();
  }

  // Подключение к WebSocket
  void _connectToSocket() {
    try {
      final prefs = inject<SharedPreferences>();
      final sessionId = prefs.getString('access_token');
      final userId = prefs.getString('userId');
      
      if (sessionId != null && userId != null) {
        socket = IO.io('ws://116.203.135.192:3001', <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        });
        
        socket?.connect();
        
        // Слушаем событие отмены заказа
        socket?.on('orderCancelled', (data) {
          print('🚫 Received orderCancelled event: $data');
          if (data != null && data['orderId'] == widget.orderRequest.id) {
            _handleOrderCancellation();
          }
        });
        
        // Слушаем общие обновления заказов
        socket?.on('orderUpdated', (data) {
          print('📝 Received orderUpdated event: $data');
          if (data != null && data['orderId'] == widget.orderRequest.id) {
            if (data['status'] == 'cancelled' || data['status'] == 'completed') {
              _handleOrderCancellation();
            }
          }
        });
        
        print('✅ Socket connected for order monitoring');
      }
    } catch (e) {
      print('❌ Error connecting to socket for order monitoring: $e');
    }
  }

  // Периодическая проверка статуса заказа
  void _startOrderStatusPolling() {
    _orderStatusTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _checkOrderStatus();
    });
  }

  // Проверка статуса заказа через API
  Future<void> _checkOrderStatus() async {
    try {
      final prefs = inject<SharedPreferences>();
      final sessionId = prefs.getString('access_token');
      
      if (sessionId != null && !isOrderCancelled) {
        // Здесь можно добавить API вызов для проверки статуса заказа
        // Пример:
        // final response = await inject<RestClient>().getOrderStatus(widget.orderRequest.id);
        // if (response.status == 'cancelled') {
        //   _handleOrderCancellation();
        // }
      }
    } catch (e) {
      print('❌ Error checking order status: $e');
    }
  }

  // Обработка отмены заказа
  void _handleOrderCancellation() {
    if (!isOrderCancelled && mounted) {
      setState(() {
        isOrderCancelled = true;
      });
      
      // Показываем диалог об отмене
      _showOrderCancelledDialog();
      
      // Останавливаем мониторинг
      _orderStatusTimer?.cancel();
      socket?.disconnect();
    }
  }

  // Диалог об отмене заказа
  void _showOrderCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Заказ отменен',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            'Клиент отменил заказ. Вы можете продолжить поиск других заказов.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалог
                Navigator.of(context).pop(); // Закрываем bottom sheet
              },
              child: Text(
                'Понятно',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Хэндл для перетаскивания
              Container(
                margin: EdgeInsets.only(top: 6, bottom: 4),
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Основной контент без лишних отступов
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  controller: scrollController,
                    physics: ClampingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                      // Информация о клиенте - более компактная
                      Container(
                          padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                                width: 36,
                                height: 36,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.person,
                                color: primaryColor,
                                  size: 18,
                              ),
                            ),
                              SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.orderRequest.user?.fullName ?? 'Клиент',
                                    style: TextStyle(
                                        fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Пассажир',
                                    style: TextStyle(
                                        fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Кнопка WhatsApp
                            InkWell(
                              onTap: () {
                                launchUrlString(
                                    'https://wa.me/${(widget.orderRequest.user?.phone ?? '').replaceAll('+', '')}');
                              },
                              child: Container(
                                  width: 32,
                                  height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.message,
                                  color: Colors.white,
                                    size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Комментарий (если есть)
                      if (widget.orderRequest.comment.isNotEmpty) ...[
                          SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                            padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                color: Colors.orange.shade700,
                                  size: 14,
                              ),
                                SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.orderRequest.comment,
                                  style: TextStyle(
                                      fontSize: 12,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                        SizedBox(height: 8),
                      
                      // Маршрут - более компактный
                      Container(
                          padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                              // Заголовок маршрута с ценой
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Маршрут поездки',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Text(
                                      NumUtils.humanizeNumber(widget.orderRequest.price, isCurrency: true) ?? '0 ₸',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 8),
                              
                            // Откуда
                            Row(
                              children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                  SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Откуда',
                                        style: TextStyle(
                                            fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        widget.orderRequest.from,
                                        style: TextStyle(
                                            fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Линия маршрута
                            Container(
                                margin: EdgeInsets.only(left: 4, top: 2, bottom: 2),
                              width: 1,
                                height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            
                            // Куда
                            Row(
                              children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                  SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Куда',
                                        style: TextStyle(
                                            fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        widget.orderRequest.to,
                                        style: TextStyle(
                                            fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                        SizedBox(height: 8),
                      
                        // Карта - увеличенная
                      Container(
                          height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: mapbox.MapWidget(
                            key: ValueKey("mapWidget"),
                            cameraOptions: mapbox.CameraOptions(
                              center: mapbox.Point(coordinates: mapbox.Position(
                                  // Calculate center between start and end points
                                  (_safeParseCoordinateLng(widget.orderRequest.fromMapboxId) + 
                                  _safeParseCoordinateLng(widget.orderRequest.toMapboxId)) / 2,
                                  (_safeParseCoordinateLat(widget.orderRequest.fromMapboxId) + 
                                  _safeParseCoordinateLat(widget.orderRequest.toMapboxId)) / 2,
                              )),
                                zoom: 12, // Start with moderate zoom
                            ),
                              onMapCreated: (mapboxController) async {
                                print('🗺️ Map created, initializing...');
                              setState(() {
                                mapboxMapController = mapboxController;
                              });
                                
                                try {
                                  // Настройка жестов с задержкой для полной инициализации карты
                                  await Future.delayed(Duration(milliseconds: 500));
                                  
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
                                  print('✅ Gesture settings applied');
                                  
                                  // Add marker images first
                                  await addImageFromAsset('point_a', 'assets/images/point_a.png');
                                  await addImageFromAsset('point_b', 'assets/images/point_b.png');
                                  print('✅ Marker images added');
                                  
                                  // Small delay to ensure map is fully initialized
                                  await Future.delayed(Duration(milliseconds: 300));
                                  
                                  // Load route and display it
                                  await fetchActiveOrderRoute();
                                  print('✅ Route loading initiated');
                                } catch (e) {
                                  print('❌ Error during map initialization: $e');
                                }
                            },
                          ),
                        ),
                      ),
                      
                        SizedBox(height: 10),
                      
                      // Информационные карточки - более компактные
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                                padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.shade100),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: Colors.purple.shade600,
                                      size: 14,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    route.isNotEmpty && route.containsKey('routes') && route['routes'].isNotEmpty && route['routes'][0].containsKey('duration')
                                      ? '${((route['routes'][0]['duration'] as double) / 60).round()} мин'
                                      : '-- мин',
                                    style: TextStyle(
                                        fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Время',
                                    style: TextStyle(
                                        fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                            SizedBox(width: 6),
                          Expanded(
                            child: Container(
                                padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    color: Colors.blue.shade600,
                                      size: 14,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    route.isNotEmpty && route.containsKey('routes') && route['routes'].isNotEmpty && route['routes'][0].containsKey('distance')
                                      ? '${((route['routes'][0]['distance'] as double) / 1000).toStringAsFixed(1)} км'
                                      : '-- км',
                                    style: TextStyle(
                                        fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Расстояние',
                                    style: TextStyle(
                                        fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Кнопки действий - исправлено
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 44,
                              child: OutlinedButton(
                                  onPressed: isOrderCancelled ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: isOrderCancelled ? Colors.grey.shade400 : Colors.grey.shade700,
                                    side: BorderSide(color: isOrderCancelled ? Colors.grey.shade200 : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Отклонить',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 44,
                              child: ElevatedButton(
                                  onPressed: isOrderCancelled ? null : () => widget.onAccept(),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: isOrderCancelled ? Colors.grey.shade300 : primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      if (isOrderCancelled) ...[
                                        Icon(Icons.cancel_outlined, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Заказ отменен',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ] else ...[
                                    Icon(Icons.check_circle, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Принять заказ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                      ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                        
                        // Индикатор отмены заказа
                        if (isOrderCancelled) ...[
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.red.shade700,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Этот заказ был отменен клиентом',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      
                      SizedBox(height: 16),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> fetchActiveOrderRoute() async {
    String? sessionId = inject<SharedPreferences>().getString('access_token');

    try {
      // Safely parse coordinates with enhanced validation
      List<String> fromCoords = widget.orderRequest.fromMapboxId.split(';');
      List<String> toCoords = widget.orderRequest.toMapboxId.split(';');
      
      print('🗺️ === ROUTE FETCHING DEBUG ===');
      print('📍 From MapboxId: ${widget.orderRequest.fromMapboxId}');
      print('📍 To MapboxId: ${widget.orderRequest.toMapboxId}');
      print('📍 From coords array: $fromCoords (length: ${fromCoords.length})');
      print('📍 To coords array: $toCoords (length: ${toCoords.length})');
      
      // Enhanced coordinate validation and parsing
      double fromLat, fromLng, toLat, toLng;
      
      if (fromCoords.length >= 2) {
        fromLat = double.tryParse(fromCoords[0]) ?? widget.orderRequest.lat.toDouble();
        fromLng = double.tryParse(fromCoords[1]) ?? widget.orderRequest.lng.toDouble();
      } else {
        print('⚠️ Invalid fromMapboxId format, using fallback coordinates');
        fromLat = widget.orderRequest.lat.toDouble();
        fromLng = widget.orderRequest.lng.toDouble();
      }
      
      if (toCoords.length >= 2) {
        toLat = double.tryParse(toCoords[0]) ?? 0.0;
        toLng = double.tryParse(toCoords[1]) ?? 0.0;
      } else {
        print('⚠️ Invalid toMapboxId format, using fallback coordinates');
        toLat = 0.0;
        toLng = 0.0;
      }
      
      // Final fallback if destination coordinates are still invalid
      if (toLat == 0.0 && toLng == 0.0) {
        print('⚠️ No valid destination coordinates, creating approximate destination');
        toLat = fromLat + 0.01; // Small offset for demo
        toLng = fromLng + 0.01;
      }
      
      print('📍 Final parsed coordinates:');
      print('   From: $fromLat, $fromLng');
      print('   To: $toLat, $toLng');
      
      // Validate that coordinates are reasonable (rough bounds for Kazakhstan)
      if (fromLat < 40.0 || fromLat > 56.0 || fromLng < 46.0 || fromLng > 88.0) {
        print('⚠️ From coordinates seem invalid for Kazakhstan, using defaults');
        fromLat = 43.2220; // Almaty latitude
        fromLng = 76.8512; // Almaty longitude
      }
      
      if (toLat < 40.0 || toLat > 56.0 || toLng < 46.0 || toLng > 88.0) {
        print('⚠️ To coordinates seem invalid for Kazakhstan, adjusting');
        toLat = fromLat + 0.01;
        toLng = fromLng + 0.01;
      }
      
      print('📍 Validated coordinates:');
      print('   From: $fromLat, $fromLng');
      print('   To: $toLat, $toLng');
      
      // Fetch directions from Mapbox
    final directions = await inject<MapboxApi>().getDirections(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );

      print('🗺️ Mapbox API Response:');
      print('   Success: ${directions.isNotEmpty}');
      if (directions.isNotEmpty) {
        print('   Routes count: ${directions['routes']?.length ?? 0}');
        if (directions['routes'] != null && directions['routes'].isNotEmpty) {
          final route = directions['routes'][0];
          print('   Distance: ${route['distance']} meters');
          print('   Duration: ${route['duration']} seconds');
          print('   Has geometry: ${route.containsKey('geometry')}');
        }
      }

    setState(() {
      route = directions;
    });

      // Add route and markers to map if controller is ready
      if (mapboxMapController != null) {
        print('🗺️ Adding route to map...');
        
        // Clear existing route/markers first
        await clearMapAnnotations();
        
        if (route.isNotEmpty) {
          // Add route line
        await addRouteToMap();
          print('✅ Route line added');
          
          // Add markers
        await addMarkersToMap();
          print('✅ Markers added');
          
          // Fit route in view with delay to ensure everything is loaded
          await Future.delayed(Duration(milliseconds: 500));
          await fitRouteInView();
          print('✅ Route fitted to view');
        } else {
          print('⚠️ Empty route response, only adding markers');
          await addMarkersToMap();
          await fitRouteInView(); // Still fit the view to show start/end points
        }
      } else {
        print('⚠️ Map controller not ready, route will be added when map loads');
      }
      } catch (e) {
      print('❌ Error fetching route: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Helper method to clear existing map annotations
  Future<void> clearMapAnnotations() async {
    if (mapboxMapController == null) return;
    
    try {
      // Remove route layers and sources
      final layersToRemove = ['route-layer', 'start-marker-layer', 'end-marker-layer', 'user-marker-layer'];
      final sourcesToRemove = ['route-source', 'markers-source', 'user-marker-source'];
      
      for (String layerId in layersToRemove) {
        if (await mapboxMapController!.style.styleLayerExists(layerId)) {
          await mapboxMapController!.style.removeStyleLayer(layerId);
        }
      }
      
      for (String sourceId in sourcesToRemove) {
        if (await mapboxMapController!.style.styleSourceExists(sourceId)) {
          await mapboxMapController!.style.removeStyleSource(sourceId);
        }
      }
      
      print('🧹 Map annotations cleared');
    } catch (e) {
      print('⚠️ Error clearing map annotations: $e');
    }
  }

  Future<void> addRouteToMap() async {
    if (mapboxMapController == null || route.isEmpty) {
      print('⚠️ Cannot add route: controller=${mapboxMapController != null}, route=${route.isNotEmpty}');
      return;
    }

    try {
      print('🛣️ Adding route to map...');
      
      // Ensure we have route data
      if (!route.containsKey('routes') || route['routes'].isEmpty) {
        print('❌ No routes in response data');
        return;
      }
      
      final routeData = route['routes'][0];
      if (!routeData.containsKey('geometry')) {
        print('❌ No geometry in route data');
        return;
      }
      
      // Create GeoJSON LineString from route geometry
      final routeGeometry = routeData['geometry'];
      print('📐 Route geometry type: ${routeGeometry['type']}');
      print('📐 Coordinates count: ${routeGeometry['coordinates']?.length ?? 0}');
      
      final lineString = {
        "type": "Feature",
        "geometry": routeGeometry,
        "properties": {
          "color": "#2196F3", // Blue color
          "opacity": 0.8,
          "width": 6
        }
      };

      final sourceData = {
        "type": "FeatureCollection",
        "features": [lineString]
      };

      print('📊 Adding route source...');
      // Add source for the route
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'route-source',
        data: json.encode(sourceData),
      ));

      print('🎨 Adding route layer...');
      // Add line layer for the route with enhanced styling
      await mapboxMapController!.style.addLayer(mapbox.LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: 0xFF2196F3, // Blue color
        lineWidth: 6.0, // Thicker line for better visibility
        lineOpacity: 0.9,
        lineCap: mapbox.LineCap.ROUND,
        lineJoin: mapbox.LineJoin.ROUND,
      ));

      print('✅ Route successfully added to map');
    } catch (e) {
      print('❌ Error adding route line: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> addMarkersToMap() async {
    if (mapboxMapController == null) return;

    try {
      // Remove existing marker layers if they exist
      if (await mapboxMapController!.style.styleLayerExists('markers-layer')) {
        await mapboxMapController!.style.removeStyleLayer('markers-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('markers-source')) {
        await mapboxMapController!.style.removeStyleSource('markers-source');
      }

      // Create point features for start and end
      final startPoint = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [
            _safeParseCoordinateLng(widget.orderRequest.fromMapboxId),
            _safeParseCoordinateLat(widget.orderRequest.fromMapboxId)
          ]
        },
        "properties": {"marker-symbol": "start"}
      };

      final endPoint = {
        "type": "Feature", 
        "geometry": {
          "type": "Point",
          "coordinates": [
            _safeParseCoordinateLng(widget.orderRequest.toMapboxId),
            _safeParseCoordinateLat(widget.orderRequest.toMapboxId)
          ]
        },
        "properties": {"marker-symbol": "end"}
      };

      // Add source for markers
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'markers-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [startPoint, endPoint]
        }),
      ));

      // Add symbol layer for start marker
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'start-marker-layer',
        sourceId: 'markers-source',
        filter: ['==', ['get', 'marker-symbol'], 'start'],
        iconImage: 'point_a',
        iconSize: 0.3,
        iconAllowOverlap: true,
      ));
      
      // Add symbol layer for end marker
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'end-marker-layer',
        sourceId: 'markers-source',
        filter: ['==', ['get', 'marker-symbol'], 'end'],
        iconImage: 'point_b',
        iconSize: 0.3,
        iconAllowOverlap: true,
      ));
    } catch (e) {
      print('Error adding markers: $e');
    }
  }

  Future<void> adjustZoomForPoints(Map<String, double> point1, Map<String, double> point2) async {
    try {
      // Calculate appropriate zoom level based on distance
      final double latDiff = (point1['latitude']! - point2['latitude']!).abs();
      final double lngDiff = (point1['longitude']! - point2['longitude']!).abs();
      
      // Calculate diagonal distance for better zoom calculation
      final double diagonalDistance = math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
      
      // Determine zoom level based on distance with more precise values
      double zoom = 15.0;
      if (diagonalDistance > 0.05) zoom = 14.0;
      if (diagonalDistance > 0.1) zoom = 13.0;
      if (diagonalDistance > 0.2) zoom = 12.0;
      if (diagonalDistance > 0.3) zoom = 11.0;
      if (diagonalDistance > 0.5) zoom = 10.0;
      if (diagonalDistance > 1.0) zoom = 9.0;
      if (diagonalDistance > 2.0) zoom = 8.0;
      
      // Add padding to ensure markers are fully visible
      final double paddingFactor = 0.2; // 20% padding
      final double extraPadding = diagonalDistance * paddingFactor;
      
      // Adjust the map bounds to include padding
      final double minLat = math.min(point1['latitude']!, point2['latitude']!) - extraPadding;
      final double maxLat = math.max(point1['latitude']!, point2['latitude']!) + extraPadding;
      final double minLng = math.min(point1['longitude']!, point2['longitude']!) - extraPadding;
      final double maxLng = math.max(point1['longitude']!, point2['longitude']!) + extraPadding;
      
      // Calculate center point with adjusted bounds
      final double centerLat = (minLat + maxLat) / 2;
      final double centerLng = (minLng + maxLng) / 2;
      
      // Update camera with calculated zoom and center
      await mapboxMapController!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(centerLng, centerLat)),
          zoom: zoom,
          bearing: 0,
          pitch: 0,
        ),
        mapbox.MapAnimationOptions(
          duration: 1,
          startDelay: 0,
        ),
      );
    } catch (e) {
      print('Error adjusting zoom: $e');
    }
  }

  Future<void> addImageFromAsset(String name, String assetName) async {
    try {
      // Create a small colored circle with text
      final int size = 40; // Slightly larger size
      
      // Create a canvas to draw the marker
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      
      // Background with border
      final bgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        
      final borderPaint = Paint()
        ..color = name == 'point_a' ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Draw circle with border
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, bgPaint);
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, borderPaint);
      
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
        Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2)
      );
      
      // Convert to image
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
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
        final image = await decodeImageFromList(list);
        
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

  // New method to fit the camera view to the route
  Future<void> fitRouteInView() async {
    try {
      if (route.isEmpty || mapboxMapController == null) return;
      
      // Get start and end coordinates directly from order request
      final startLat = _safeParseCoordinateLat(widget.orderRequest.fromMapboxId);
      final startLng = _safeParseCoordinateLng(widget.orderRequest.fromMapboxId);
      final endLat = _safeParseCoordinateLat(widget.orderRequest.toMapboxId);
      final endLng = _safeParseCoordinateLng(widget.orderRequest.toMapboxId);
      
      // Use fallback coordinates if parsing fails
      final double fromLat = startLat != 0.0 ? startLat : widget.orderRequest.lat.toDouble();
      final double fromLng = startLng != 0.0 ? startLng : widget.orderRequest.lng.toDouble();
      final double toLat = endLat != 0.0 ? endLat : widget.orderRequest.lat.toDouble() + 0.01;
      final double toLng = endLng != 0.0 ? endLng : widget.orderRequest.lng.toDouble() + 0.01;
      
      print('🎯 Fitting route to view:');
      print('   Start: $fromLat, $fromLng');
      print('   End: $toLat, $toLng');
      
      // Calculate bounds including route coordinates
      double minLat = math.min(fromLat, toLat);
      double maxLat = math.max(fromLat, toLat);
      double minLng = math.min(fromLng, toLng);
      double maxLng = math.max(fromLng, toLng);
      
      // Include all route coordinates for more precise bounds
      if (route.containsKey('routes') && route['routes'].isNotEmpty) {
        List<dynamic> coordinates = route['routes'][0]['geometry']['coordinates'];
      for (var coord in coordinates) {
        final longitude = coord[0] as double;
        final latitude = coord[1] as double;
        
        minLat = math.min(minLat, latitude);
        maxLat = math.max(maxLat, latitude);
        minLng = math.min(minLng, longitude);
        maxLng = math.max(maxLng, longitude);
      }
      }
      
      print('   Bounds: minLat=$minLat, maxLat=$maxLat, minLng=$minLng, maxLng=$maxLng');
      
      // Calculate center point
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      // Calculate differences
      final double latDiff = (maxLat - minLat).abs();
      final double lngDiff = (maxLng - minLng).abs();
      
      // Use the larger of the two differences to determine zoom
      final double maxDiff = math.max(latDiff, lngDiff);
      
      // Determine zoom based on the maximum difference (adjusted for wider view)
      double zoom = 15.0; // Default close zoom, will be adjusted downwards
      
      // УЛУЧШЕННАЯ ЛОГИКА: Более широкий обзор для лучшей видимости маршрута
      if (maxDiff > 0.0001) zoom = 16.0; // Очень близко
      if (maxDiff > 0.0005) zoom = 15.0; // Близко
      if (maxDiff > 0.001) zoom = 14.0;  // Уменьшено с 14.5
      if (maxDiff > 0.005) zoom = 13.0;  // Уменьшено с 14.0
      if (maxDiff > 0.01) zoom = 12.0;   // Уменьшено с 13.5
      if (maxDiff > 0.02) zoom = 11.5;   // Уменьшено с 13.0
      if (maxDiff > 0.03) zoom = 11.0;   // Уменьшено с 12.5
      if (maxDiff > 0.05) zoom = 10.5;   // Уменьшено с 12.0
      if (maxDiff > 0.08) zoom = 10.0;   // Уменьшено с 11.5
      if (maxDiff > 0.1) zoom = 9.5;     // Уменьшено с 11.0
      if (maxDiff > 0.15) zoom = 9.0;    // Уменьшено с 10.5
      if (maxDiff > 0.2) zoom = 8.5;     // Уменьшено с 10.0
      if (maxDiff > 0.3) zoom = 8.0;     // Уменьшено с 9.5
      if (maxDiff > 0.5) zoom = 7.5;     // Уменьшено с 9.0
      if (maxDiff > 0.8) zoom = 7.0;     // Уменьшено с 8.5
      if (maxDiff > 1.0) zoom = 6.5;     // Уменьшено с 8.0
      if (maxDiff > 1.5) zoom = 6.0;     // Уменьшено с 7.5
      if (maxDiff > 2.0) zoom = 5.5;     // Уменьшено с 7.0
      if (maxDiff > 3.0) zoom = 5.0;     // Уменьшено с 6.0
      if (maxDiff > 5.0) zoom = 4.5;     // Уменьшено с 5.0
      
      // ДОПОЛНИТЕЛЬНАЯ КОРРЕКТИРОВКА: Уменьшаем зум на 0.5 для более широкого обзора
      zoom = math.max(4.0, zoom - 0.5);
      
      print('   Calculated zoom: $zoom (maxDiff: $maxDiff)');
      print('   Center: $centerLat, $centerLng');
      
      // Animate camera to show the route perfectly
      await mapboxMapController!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(centerLng, centerLat)),
          zoom: zoom,
          bearing: 0,
          pitch: 0,
        ),
        mapbox.MapAnimationOptions(
          duration: 2000, // Slower animation for better UX
          startDelay: 0,
        ),
      );
      
      print('✅ Route fitted to view successfully');
    } catch (e) {
      print('❌ Error fitting route in view: $e');
    }
  }

  // Add a marker for the user's current location
  Future<void> addUserMarker(double lat, double lng) async {
    try {
      // Remove existing user marker if present
      if (await mapboxMapController!.style.styleLayerExists('user-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('user-marker-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('user-marker-source')) {
        await mapboxMapController!.style.removeStyleSource('user-marker-source');
      }
      
      // Create user location marker
      final userPoint = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [lng, lat]
        },
        "properties": {"marker-symbol": "user"}
      };
      
      // Add source for user marker
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'user-marker-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [userPoint]
        }),
      ));
      
      // Create user location image if it doesn't exist
      await createUserLocationMarker();
      
      // Add layer for user marker
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'user-marker-layer',
        sourceId: 'user-marker-source',
        iconImage: 'user-location',
        iconSize: 0.7,
        iconAllowOverlap: true,
      ));
      
    } catch (e) {
      print("Error adding user marker: $e");
    }
  }
  
  // Create a custom marker for user location
  Future<void> createUserLocationMarker() async {
    try {
      // Create a blue dot with white border for the user location
      final int size = 32;
      
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      
      // Outer white circle
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      // Inner blue circle
      final bluePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
        
      // Draw circles
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, whitePaint);
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, bluePaint);
      
      // Convert to image
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final Uint8List imageBytes = byteData!.buffer.asUint8List();
      
      // Create Mapbox image
      final mbxImage = mapbox.MbxImage(
        data: imageBytes,
        width: size,
        height: size,
      );
      
      // Add to map style
      await mapboxMapController?.style.addStyleImage(
        'user-location',
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );
    } catch (e) {
      print("Error creating user location marker: $e");
    }
  }

  // Helper methods for safe coordinate parsing
  double _safeParseCoordinateLat(String mapboxId) {
    try {
      if (mapboxId.isEmpty) {
        return widget.orderRequest.lat.toDouble();
      }
      
      List<String> coords = mapboxId.split(';');
      if (coords.length >= 2) {
        double lat = double.tryParse(coords[0]) ?? 0.0;
        // Validate latitude range
        if (lat >= -90.0 && lat <= 90.0 && lat != 0.0) {
          return lat;
        }
      }
    } catch (e) {
      print('❌ Error parsing latitude from mapboxId: $e');
    }
    
    // Return fallback latitude
    return widget.orderRequest.lat.toDouble();
  }

  double _safeParseCoordinateLng(String mapboxId) {
    try {
      if (mapboxId.isEmpty) {
        return widget.orderRequest.lng.toDouble();
      }
      
      List<String> coords = mapboxId.split(';');
      if (coords.length >= 2) {
        double lng = double.tryParse(coords[1]) ?? 0.0;
        // Validate longitude range
        if (lng >= -180.0 && lng <= 180.0 && lng != 0.0) {
          return lng;
        }
      }
    } catch (e) {
      print('❌ Error parsing longitude from mapboxId: $e');
    }
    
    // Return fallback longitude
    return widget.orderRequest.lng.toDouble();
  }
}
