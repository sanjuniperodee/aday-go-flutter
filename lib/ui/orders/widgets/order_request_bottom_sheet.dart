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

class _OrderRequestBottomSheetState extends State<OrderRequestBottomSheet> with TickerProviderStateMixin {
  mapbox.MapboxMap? mapboxMapController;
  Map<String, dynamic> route = {};
  bool isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    Future.wait([
      fetchActiveOrderRoute(),
    ]);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Хэндл для перетаскивания
              Container(
                margin: EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Основной контент
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Заголовок с анимированной иконкой - более компактный
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    color: primaryColor,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Новый заказ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Рассмотрите детали поездки',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Стоимость
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              NumUtils.humanizeNumber(widget.orderRequest.price, isCurrency: true) ?? '0 ₸',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Информация о клиенте - более компактная
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.orderRequest.user?.fullName ?? 'Клиент',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Пассажир',
                                    style: TextStyle(
                                      fontSize: 12,
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
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.message,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Комментарий (если есть)
                      if (widget.orderRequest.comment.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                color: Colors.orange.shade700,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.orderRequest.comment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 16),
                      
                      // Маршрут - более компактный
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Откуда
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Откуда',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        widget.orderRequest.from,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Линия маршрута
                            Container(
                              margin: EdgeInsets.only(left: 5, top: 4, bottom: 4),
                              width: 1,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            
                            // Куда
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Куда',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        widget.orderRequest.to,
                                        style: TextStyle(
                                          fontSize: 13,
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
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Карта - уменьшенная
                      Container(
                        height: 160,
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
                                (widget.orderRequest.lng.toDouble() + 
                                double.parse(widget.orderRequest.toMapboxId.split(';')[1])) / 2,
                                (widget.orderRequest.lat.toDouble() + 
                                double.parse(widget.orderRequest.toMapboxId.split(';')[0])) / 2,
                              )),
                              zoom: 10, // Уменьшен зум чтобы весь путь влезал
                            ),
                            onMapCreated: (mapboxController) {
                              setState(() {
                                mapboxMapController = mapboxController;
                              });
                              addImageFromAsset('point_a', 'assets/images/point_a.png');
                              addImageFromAsset('point_b', 'assets/images/point_b.png');
                            },
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Информационные карточки - более компактные
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.purple.shade100),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: Colors.purple.shade600,
                                    size: 16,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    route.isNotEmpty && route.containsKey('routes') && route['routes'].isNotEmpty && route['routes'][0].containsKey('duration')
                                      ? '${((route['routes'][0]['duration'] as double) / 60).round()} мин'
                                      : '-- мин',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Время',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    color: Colors.blue.shade600,
                                    size: 16,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    route.isNotEmpty && route.containsKey('routes') && route['routes'].isNotEmpty && route['routes'][0].containsKey('distance')
                                      ? '${((route['routes'][0]['distance'] as double) / 1000).toStringAsFixed(1)} км'
                                      : '-- км',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Расстояние',
                                    style: TextStyle(
                                      fontSize: 10,
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
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
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
                                onPressed: () => widget.onAccept(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
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
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                    ],
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
    String? sessionId = inject<SharedPreferences>().getString('sessionId');

    final directions = await inject<MapboxApi>().getDirections(
      fromLat: double.parse(widget.orderRequest.fromMapboxId.split(';')[0]),
      fromLng: double.parse(widget.orderRequest.fromMapboxId.split(';')[1]),
      toLat: double.parse(widget.orderRequest.toMapboxId.split(';')[0]),
      toLng: double.parse(widget.orderRequest.toMapboxId.split(';')[1]),
    );

    setState(() {
      route = directions;
    });

    if (mapboxMapController != null && route.isNotEmpty) {
      try {
        // Add route line to map using new API
        await addRouteToMap();
        // Add markers for start and end points
        await addMarkersToMap();
      } catch (e) {
        print('Error adding route to map: $e');
      }
    }
  }

  Future<void> addRouteToMap() async {
    if (mapboxMapController == null || route.isEmpty) return;

    try {
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

      // Adjust camera to fit route
      await fitRouteInView();
    } catch (e) {
      print('Error adding route line: $e');
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
            double.parse(widget.orderRequest.fromMapboxId.split(';')[1]),
            double.parse(widget.orderRequest.fromMapboxId.split(';')[0])
          ]
        },
        "properties": {"marker-symbol": "start"}
      };

      final endPoint = {
        "type": "Feature", 
        "geometry": {
          "type": "Point",
          "coordinates": [
            double.parse(widget.orderRequest.toMapboxId.split(';')[1]),
            double.parse(widget.orderRequest.toMapboxId.split(';')[0])
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
      
      // Get route coordinates
      List<dynamic> coordinates = route['routes'][0]['geometry']['coordinates'];
      
      // Get start and end points
      final startPoint = {
        'longitude': double.parse(widget.orderRequest.fromMapboxId.split(';')[1]),
        'latitude': double.parse(widget.orderRequest.fromMapboxId.split(';')[0])
      };
      
      final endPoint = {
        'longitude': double.parse(widget.orderRequest.toMapboxId.split(';')[1]),
        'latitude': double.parse(widget.orderRequest.toMapboxId.split(';')[0])
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
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
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
      
      // Animate camera to show all points
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
}
