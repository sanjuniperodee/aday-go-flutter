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
      setState(() {});

      await fetchActiveOrderRoute();
    } on Exception catch (e) {
      setState(() {
        isOrderFinished = true;
      });
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
        iconSize: 0.6,
        iconAllowOverlap: true,
      ));
      
      // Add symbol layer for end marker
      await mapboxMapController!.style.addLayer(mapbox.SymbolLayer(
        id: 'end-marker-layer',
        sourceId: 'markers-source',
        filter: ['==', ['get', 'marker-symbol'], 'end'],
        iconImage: 'point_b',
        iconSize: 0.6,
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
    return PopScope(
      canPop: false,
      child: PrimaryBottomSheet(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                      if (!isOrderFinished && activeRequest.orderRequest?.orderStatus == 'STARTED')
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Вы приняли заказ',
                            style: TextStyle(
                              color: Color(0xFF261619),
                              fontSize: 20,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      else if (!isOrderFinished &&
                          activeRequest.orderRequest?.orderStatus == 'WAITING')
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Вы ожидаете клиента',
                            style: TextStyle(
                              color: Color(0xFF261619),
                              fontSize: 20,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      else if (!isOrderFinished &&
                          activeRequest.orderRequest?.orderStatus == 'ONGOING')
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Вы в пути',
                            style: TextStyle(
                              color: Color(0xFF261619),
                              fontSize: 20,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      else if (isOrderFinished &&
                          activeRequest.orderRequest?.orderStatus == 'REJECTED')
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Заказ отменен',
                            style: TextStyle(
                              color: Color(0xFF261619),
                              fontSize: 20,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      else if (isOrderFinished)
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Заказ завершен',
                            style: TextStyle(
                              color: Color(0xFF261619),
                              fontSize: 20,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 80,
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: ShapeDecoration(
                                image: DecorationImage(
                                  image: NetworkImage("https://via.placeholder.com/48x48"),
                                  fit: BoxFit.cover,
                                ),
                                shape: OvalBorder(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.activeOrder.whatsappUser?.fullName ?? '',
                                      textAlign: TextAlign.center,
                                      style: text400Size16Greyscale90,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Клиент',
                                      textAlign: TextAlign.center,
                                      style: text400Size12Greyscale60,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                launchUrlString(
                                    'https://wa.me/${(widget.activeOrder.whatsappUser?.phone ?? '').replaceAll('+', '')}');
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                child: SvgPicture.asset(icWhatsapp),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if ((widget.activeOrder.orderRequest?.comment ?? '').isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  child: Text(
                                    widget.activeOrder.orderRequest?.comment ?? '',
                                    style: text400Size12Greyscale90,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 300,
                              child: mapbox.MapWidget(
                                key: ValueKey("mapWidget"),
                                cameraOptions: mapbox.CameraOptions(
                                  center: mapbox.Point(coordinates: geotypes.Position(
                                    activeRequest.orderRequest!.lng.toDouble(),
                                    activeRequest.orderRequest!.lat.toDouble(),
                                  )),
                                  zoom: 14.0,
                                  bearing: 0,
                                  pitch: 0,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Откуда',
                                              textAlign: TextAlign.center,
                                              style: text400Size10Greyscale60,
                                            ),
                                            Container(
                                              width: double.infinity,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/icons/placemark.svg',
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      widget.activeOrder.orderRequest?.from ?? '',
                                                      textAlign: TextAlign.left,
                                                      style: text400Size16Black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Куда',
                                              textAlign: TextAlign.center,
                                              style: text400Size10Greyscale60,
                                            ),
                                            Container(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/icons/placemark.svg',
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      widget.activeOrder.orderRequest?.to ?? '',
                                                      textAlign: TextAlign.left,
                                                      style: text400Size16Black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 36,
                        padding: const EdgeInsets.all(8),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                child: Text(
                                  'Цена поездки: ${NumUtils.humanizeNumber(activeRequest.orderRequest?.price)} ₸ ',
                                  style: text400Size16Greyscale90,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activeRequest.orderRequest?.orderStatus == 'WAITING')
                        Container(
                          width: double.infinity,
                          height: 36,
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 24),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  child: Text(
                                    'Ожидание: ${waitingTimerLeft ~/ 60}:${waitingTimerLeft % 60}',
                                    style: text400Size16Greyscale90,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (!isOrderFinished && activeRequest.orderRequest?.orderStatus == 'STARTED')
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton.primary(
                    onPressed: arrivedDriver,
                    isLoading: isLoading,
                    text: 'Включить ожидание',
                    textStyle: text400Size16White,
                  ),
                )
              else if (!isOrderFinished && activeRequest.orderRequest?.orderStatus == 'WAITING')
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton.primary(
                    onPressed: startDrive,
                    isLoading: isLoading,
                    text: 'Начать поездку',
                    textStyle: text400Size16White,
                  ),
                )
              else if (!isOrderFinished && activeRequest.orderRequest?.orderStatus == 'ONGOING')
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton.primary(
                    onPressed: endDrive,
                    isLoading: isLoading,
                    text: 'Завершить',
                    textStyle: text400Size16White,
                  ),
                )
              else if (isOrderFinished || activeRequest.orderRequest?.orderStatus == "REJECTED")
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton.primary(
                    onPressed: Navigator.of(context).pop,
                    text: 'Продолжить',
                    textStyle: text400Size16White,
                  ),
                ),
              const SizedBox(height: 8),
              if (!isOrderFinished)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton.secondary(
                          onPressed: () {
                            launchUrlString(
                                'tel://${(widget.activeOrder.whatsappUser?.phone ?? '')}');
                          },
                          text: 'Отказаться',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(icCall),
                              const SizedBox(width: 8),
                              Text(
                                'Позвонить',
                                style: text400Size16Greyscale60,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton.secondary(
                          onPressed: () {
                            rejectOrder();
                          },
                          text: 'Отменить заказ',
                          textStyle: text400Size16Greyscale60,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
}
//
// TileLayer get openStreetMapTileLayer => TileLayer(
//       urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//       userAgentPackageName: 'dev.fleaflet.flutter_map.example',
//       // Use the recommended flutter_map_cancellable_tile_provider package to
//       // support the cancellation of loading tiles.
//       tileProvider: CancellableNetworkTileProvider(),
//     );
