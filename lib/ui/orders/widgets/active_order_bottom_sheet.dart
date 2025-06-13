import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/rendering.dart';
import 'package:geotypes/geotypes.dart' as geotypes;

import '../../../core/colors.dart';
import '../../../core/images.dart';
import '../../../core/text_styles.dart';
import '../../widgets/primary_bottom_sheet.dart';

class ActiveOrderBottomSheet extends StatefulWidget {
  final UserDomain me;
  final ActiveRequestDomain activeOrder;
  final VoidCallback onCancel;
  final StateNotifier<ActiveRequestDomain> activeOrderListener;

  const ActiveOrderBottomSheet({
    super.key,
    required this.me,
    required this.activeOrder,
    required this.onCancel,
    required this.activeOrderListener,
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

  bool isLoading = false;
  bool isOrderFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.activeOrderListener.addListener(() {
        fetchActiveOrder();
      });
    });
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
      try {
        // Add route line to map using new API
        await addRouteToMap();
        // Add markers for current location and destination
        await addMarkersToMap();
      } catch (e) {
        print('Error adding route to map: $e');
      }
    }
  }

  Future<void> addRouteToMap() async {
    if (mapboxMapController == null || route.isEmpty) return;

    try {
      // Remove existing route layers if they exist
      if (await mapboxMapController!.style.styleLayerExists('route-layer')) {
        await mapboxMapController!.style.removeStyleLayer('route-layer');
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

      // Add line layer for the route
      await mapboxMapController!.style.addLayer(mapbox.LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: Colors.blue.value,
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ));
    } catch (e) {
      print('Error adding route line: $e');
    }
  }

  Future<void> addMarkersToMap() async {
    if (mapboxMapController == null) return;

    try {
      // Remove existing marker layers if they exist
      if (await mapboxMapController!.style.styleLayerExists('start-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('start-marker-layer');
      }
      if (await mapboxMapController!.style.styleLayerExists('end-marker-layer')) {
        await mapboxMapController!.style.removeStyleLayer('end-marker-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('markers-source')) {
        await mapboxMapController!.style.removeStyleSource('markers-source');
      }

      // Create point features for current location and destination
      final currentLocationPoint = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [
            activeRequest.orderRequest!.lng.toDouble(),
            activeRequest.orderRequest!.lat.toDouble()
          ]
        },
        "properties": {"marker-symbol": "start"}
      };

      final destinationPoint = {
        "type": "Feature", 
        "geometry": {
          "type": "Point",
          "coordinates": [
            double.parse(activeRequest.orderRequest!.toMapboxId.split(';')[1]),
            double.parse(activeRequest.orderRequest!.toMapboxId.split(';')[0])
          ]
        },
        "properties": {"marker-symbol": "end"}
      };

      // Add source for markers
      await mapboxMapController!.style.addSource(mapbox.GeoJsonSource(
        id: 'markers-source',
        data: json.encode({
          "type": "FeatureCollection",
          "features": [currentLocationPoint, destinationPoint]
        }),
      ));

      // Add symbol layer for start marker
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'start-marker-layer',
        sourceId: 'markers-source',
        filter: ['==', ['get', 'marker-symbol'], 'start'],
        iconImage: 'point_a',
        iconSize: 0.2,
        iconAllowOverlap: true,
      ));
      
      // Add symbol layer for end marker
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'end-marker-layer',
        sourceId: 'markers-source',
        filter: ['==', ['get', 'marker-symbol'], 'end'],
        iconImage: 'point_b',
        iconSize: 0.2,
        iconAllowOverlap: true,
      ));
    } catch (e) {
      print('Error adding markers: $e');
    }
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
    try {
      if (route.isEmpty || mapboxMapController == null) return;
      
      // Get route coordinates
      List<dynamic> coordinates = route['routes'][0]['geometry']['coordinates'];
      
      // Get start and end points
      final startPoint = {
        'longitude': activeRequest.orderRequest!.lng.toDouble(),
        'latitude': activeRequest.orderRequest!.lat.toDouble()
      };
      
      final endPoint = {
        'longitude': double.parse(activeRequest.orderRequest!.toMapboxId.split(';')[1]),
        'latitude': double.parse(activeRequest.orderRequest!.toMapboxId.split(';')[0])
      };
      
      // Calculate bounds for all points
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;
      
      // Include start and end points in bounds
      minLat = math.min(minLat, startPoint['latitude']!);
      maxLat = math.max(maxLat, startPoint['latitude']!);
      minLng = math.min(minLng, startPoint['longitude']!);
      maxLng = math.max(maxLng, startPoint['longitude']!);
      
      minLat = math.min(minLat, endPoint['latitude']!);
      maxLat = math.max(maxLat, endPoint['latitude']!);
      minLng = math.min(minLng, endPoint['longitude']!);
      maxLng = math.max(maxLng, endPoint['longitude']!);
      
      // Include all route coordinates in bounds
      for (var coord in coordinates) {
        final longitude = coord[0] as double;
        final latitude = coord[1] as double;
        
        minLat = math.min(minLat, latitude);
        maxLat = math.max(maxLat, latitude);
        minLng = math.min(minLng, longitude);
        maxLng = math.max(maxLng, longitude);
      }
      
      // Try to get the user's current position and include it in bounds
      try {
        SharedPreferences prefs = inject<SharedPreferences>();
        final double? userLat = prefs.getDouble('latitude');
        final double? userLng = prefs.getDouble('longitude');
        
        if (userLat != null && userLng != null) {
          minLat = math.min(minLat, userLat);
          maxLat = math.max(maxLat, userLat);
          minLng = math.min(minLng, userLng);
          maxLng = math.max(maxLng, userLng);
          
          // Add user marker if not already present
          await addUserMarker(userLat, userLng);
        }
      } catch (e) {
        print("Could not get user position for bounds: $e");
      }
      
      // Calculate center point
      final adjustedCenterLat = (minLat + maxLat) / 2;
      final adjustedCenterLng = (minLng + maxLng) / 2;
      
      // Add padding to bounds (20%)
      final latPadding = (maxLat - minLat) * 0.2;
      final lngPadding = (maxLng - minLng) * 0.2;
      
      minLat -= latPadding;
      maxLat += latPadding;
      minLng -= lngPadding;
      maxLng += lngPadding;
      
      // Calculate appropriate zoom level
      final double latDiff = (maxLat - minLat).abs();
      final double lngDiff = (maxLng - minLng).abs();
      
      // Use the larger of the two differences to determine zoom
      final double maxDiff = math.max(latDiff, lngDiff);
      
      // Determine zoom based on the maximum difference
      double zoom = 15.0; // Default close zoom
      
      if (maxDiff > 0.02) zoom = 14.0;
      if (maxDiff > 0.05) zoom = 13.0;
      if (maxDiff > 0.1) zoom = 12.0;
      if (maxDiff > 0.2) zoom = 11.0;
      if (maxDiff > 0.5) zoom = 10.0;
      if (maxDiff > 1.0) zoom = 9.0;
      if (maxDiff > 2.0) zoom = 8.0;
      if (maxDiff > 5.0) zoom = 7.0;
      
      // Create a camera animation
      final cameraOptions = mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            adjustedCenterLng,
            adjustedCenterLat,
          )
        ),
        zoom: zoom,
        bearing: 0,
        pitch: 0,
      );
      
      // Animate to fit the route
      await mapboxMapController!.flyTo(
        cameraOptions,
        mapbox.MapAnimationOptions(
          duration: 1,
          startDelay: 0,
        ),
      );
      
      print("Map zoomed to fit route with zoom level: $zoom");
    } catch (e) {
      print('Error fitting route in view: $e');
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

  @override
  Widget build(BuildContext context) {
    final orderStatus = activeRequest.orderRequest?.orderStatus ?? '';
    final statusInfo = _getStatusInfo(orderStatus);
    
    return PopScope(
      canPop: false,
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
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
            
            // Статус заказа
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: statusInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusInfo['color'].withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusInfo['color'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusInfo['icon'],
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusInfo['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          statusInfo['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Детали поездки
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Маршрут
                  _buildRouteSection(),
                  
                  SizedBox(height: 20),
                  
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
                          value: '${NumUtils.humanizeNumber(activeRequest.orderRequest?.price, isCurrency: true) ?? '0'} ₸',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Кнопки действий
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildActionButtons(),
            ),
            
            SizedBox(height: 32),
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
}
//
// TileLayer get openStreetMapTileLayer => TileLayer(
//       urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//       userAgentPackageName: 'dev.fleaflet.flutter_map.example',
//       // Use the recommended flutter_map_cancellable_tile_provider package to
//       // support the cancellation of loading tiles.
//       tileProvider: CancellableNetworkTileProvider(),
//     );
