import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
// import 'package:mapbox_gl/mapbox_gl.dart' as mapbox;

import '../../core/images.dart';
import '../../domains/food/food_category_domain.dart';
import '../../domains/food/food_domain.dart';
import '../../interactors/common/mapbox_api/mapbox_api.dart';
import '../../utils/utils.dart';
import '../widgets/my_mapbox_map.dart';
import './widgets/tenant_home_create_food_view.dart';
import './widgets/tenant_home_create_order_view.dart';
import './widgets/tenant_home_tab_view.dart';
import '../widgets/primary_bottom_sheet.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geotypes/geotypes.dart' as geotypes;

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../domains/user/user_domain.dart';
import '../../forms/driver_registration_form.dart';
import '../../forms/inputs/required_formz_input.dart';
import '../../models/active_client_request/active_client_request_model.dart';
import '../../domains/food/food_category_domain.dart';
import '../../domains/food/food_domain.dart';
import '../widgets/primary_bottom_sheet.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:elementary_helper/elementary_helper.dart';
import './widgets/tenant_home_create_food_view.dart';
import './widgets/tenant_home_create_order_view.dart';
import './widgets/tenant_home_tab_view.dart';
import './forms/driver_order_form.dart';
import 'tenant_home_wm.dart';
import 'widgets/active_client_order_bottom_sheet.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/ui/widgets/notification_badge.dart';
import 'package:aktau_go/ui/map_picker/map_picker_screen.dart';

class TenantHomeScreen extends ElementaryWidget<ITenantHomeWM> {
  TenantHomeScreen({
    Key? key,
  }) : super(
          (context) => defaultTenantHomeWMFactory(context),
        );

  // Add price state variable
  static const double _defaultPrice = 400;
  
  @override
  Widget build(ITenantHomeWM wm) {
    // Add a state variable for the price
    final ValueNotifier<double> priceNotifier = ValueNotifier<double>(_defaultPrice);
    // Контроллер для комментариев
    final TextEditingController commentController = TextEditingController();
    
    return TripleSourceBuilder(
      firstSource: wm.userLocation,
      secondSource: wm.driverLocation,
      thirdSource: wm.draggableScrolledSize,
      builder: (
        context,
        geotypes.Position? userLocation,
        geotypes.Position? driverLocation,
        double? draggableScrolledSize,
      ) {
        // Add route state variables
        final bool isRouteDisplayed = wm.isRouteDisplayed.value ?? false;
        final bool isMapFixed = wm.isMapFixed.value ?? false;
        
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Map container - takes full screen
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: MapWidget(
                        key: ValueKey("mainMapWidget"),
                        cameraOptions: CameraOptions(
                          center: Point(coordinates: geotypes.Position(
                            userLocation?.lng ?? 76.893156,
                            userLocation?.lat ?? 43.239337,
                          )),
                          zoom: 18.0,
                        ),
                        onMapCreated: (mapboxController) async {
                          // Pass controller to WidgetModel
                          wm.setMapboxController(mapboxController);
                          
                          // Load marker images
                          _addImageFromAsset(mapboxController, 'point_b', 'assets/images/point_b.png');
                          _addImageFromAsset(mapboxController, 'point_a', 'assets/images/point_a.png');
                          _addImageFromAsset(mapboxController, 'car_icon', 'assets/images/car_icon.png');
                          
                          // Enable built-in user location display
                          try {
                            await mapboxController.location.updateSettings(
                              LocationComponentSettings(
                                enabled: true,
                                pulsingEnabled: true,
                                showAccuracyRing: true,
                                puckBearingEnabled: false,
                              ),
                            );
                          } catch (e) {
                            print('Ошибка при включении отображения местоположения: $e');
                          }
                          
                          // Setup map localization
                          _setupMapLocalization(mapboxController);
                          
                          // Setup map styling
                          await _setupMapStyling(mapboxController);
                        },
                      ),
                    ),
                    
                    // Location button with improved shadow
                    Positioned(
                      top: 32,
                      right: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: wm.getMyLocation,
                              child: Container(
                                width: 48,
                                height: 48,
                                child: Icon(
                                  Icons.my_location,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Route preview hint (shows briefly when route is drawn)
                    if (isRouteDisplayed)
                    Positioned(
                      top: 90,
                      left: 0,
                      right: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Маршрут построен',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom sheet containing the form
              TripleSourceBuilder(
                firstSource: wm.activeOrder,
                secondSource: wm.me,
                thirdSource: wm.locationPermission,
                builder: (
                  context,
                  ActiveClientRequestModel? activeOrder,
                  UserDomain? me,
                  LocationPermission? locationPermission,
                ) {
                  // Check location permission
                  if (![
                    LocationPermission.always,
                    LocationPermission.whileInUse
                  ].contains(locationPermission)) {
                    return _buildLocationPermissionBottomSheet(wm);
                  }
                  
                  // Check for active order
                  if (activeOrder != null) {
                    return _buildActiveOrderBottomSheet(activeOrder, me!, wm);
                  }
                  
                  // Order creation panel
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, -2),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Компактный индикатор для перетаскивания
                          Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 4),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          
                          // Основное содержимое
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Откуда
                                _buildAddressField(
                                  context: context,
                                  icon: Icons.radio_button_checked,
                                  iconColor: Colors.green,
                                  hint: 'Откуда',
                                  value: wm.savedFromAddress.value ?? '',
                                  onTap: () async {
                                    try {
                                      print('Открываю экран выбора адреса "Откуда"');
                                      
                                      // Создаем экземпляр MapAddressPickerScreenArgs для точки А
                                      final args = MapAddressPickerScreenArgs(
                                        placeName: wm.savedFromAddress.value,
                                        position: wm.savedFromMapboxId.value != null ? 
                                            _parseMapboxId(wm.savedFromMapboxId.value!) : null,
                                        onSubmit: (position, placeName) {
                                          print('Выбран адрес отправления: $placeName в позиции ${position.lat}, ${position.lng}');
                                          
                                          // Убедимся, что имя места не пустое
                                          final actualPlaceName = placeName.isNotEmpty ? placeName : "Адрес не найден";
                                          print('Сохраняем адрес отправления: $actualPlaceName');
                                          
                                          // НЕМЕДЛЕННО сохраняем адреса
                                          wm.saveOrderAddresses(
                                            fromAddress: actualPlaceName,
                                            toAddress: wm.savedToAddress.value ?? '',
                                            fromMapboxId: '${position.lat};${position.lng}',
                                            toMapboxId: wm.savedToMapboxId.value ?? '',
                                          );
                                          wm.setRouteDisplayed(false);
                                          
                                          // Принудительно обновляем состояние UI
                                          wm.forceUpdateAddresses();
                                          
                                          print('Адрес отправления обновлен на: ${wm.savedFromAddress.value}');
                                        },
                                      );
                                      
                                      // Используем Seafarer вместо Navigator
                                      Routes.router.navigate(
                                        Routes.selectMapPicker,
                                        args: args,
                                      );
                                    } catch (e) {
                                      print('Ошибка при навигации к экрану выбора адреса: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ошибка: $e')),
                                      );
                                    }
                                  },
                                ),
                                
                                // Куда
                                _buildAddressField(
                                  context: context,
                                  icon: Icons.location_on,
                                  iconColor: Colors.red,
                                  hint: 'Куда',
                                  value: wm.savedToAddress.value ?? '',
                                  onTap: () async {
                                    try {
                                      print('Открываю экран выбора адреса "Куда"');
                                      
                                      // Создаем экземпляр MapAddressPickerScreenArgs для точки Б
                                      final args = MapAddressPickerScreenArgs(
                                        placeName: wm.savedToAddress.value,
                                        position: wm.savedToMapboxId.value != null ? 
                                            _parseMapboxId(wm.savedToMapboxId.value!) : null,
                                        fromPosition: wm.savedFromMapboxId.value != null ? 
                                            _parseMapboxId(wm.savedFromMapboxId.value!) : null,
                                        onSubmit: (position, placeName) {
                                          print('Выбран адрес назначения: $placeName в позиции ${position.lat}, ${position.lng}');
                                          
                                          // Убедимся, что имя места не пустое
                                          final actualPlaceName = placeName.isNotEmpty ? placeName : "Адрес не найден";
                                          print('Сохраняем адрес назначения: $actualPlaceName');
                                          
                                          // НЕМЕДЛЕННО сохраняем адреса
                                          wm.saveOrderAddresses(
                                            fromAddress: wm.savedFromAddress.value ?? '',
                                            toAddress: actualPlaceName,
                                            fromMapboxId: wm.savedFromMapboxId.value ?? '',
                                            toMapboxId: '${position.lat};${position.lng}',
                                          );
                                          wm.setRouteDisplayed(false);
                                          
                                          // Принудительно обновляем состояние UI
                                          wm.forceUpdateAddresses();
                                          
                                          print('Адрес назначения обновлен на: ${wm.savedToAddress.value}');
                                        },
                                      );
                                      
                                      // Используем Seafarer вместо Navigator
                                      Routes.router.navigate(
                                        Routes.selectMapPicker,
                                        args: args,
                                      );
                                    } catch (e) {
                                      print('Ошибка при навигации к экрану выбора адреса: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ошибка: $e')),
                                      );
                                    }
                                  },
                                ),
                                
                                // Комментарий - прямой ввод без диалога
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.chat_bubble_outline, color: Colors.grey),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: commentController,
                                          decoration: InputDecoration(
                                            hintText: 'Комментарий (необязательно)',
                                            hintStyle: TextStyle(color: Colors.grey),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Ввод цены - как на скрине
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.monetization_on_outlined, color: Colors.grey),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: ValueListenableBuilder<double>(
                                          valueListenable: priceNotifier,
                                          builder: (context, price, _) {
                                            // Текстовое поле для ввода цены
                                            return TextFormField(
                                              initialValue: price > 0 ? price.round().toString() : "",
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: '1000',
                                                hintStyle: TextStyle(color: Colors.grey),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                                suffixText: "₸",
                                                suffixStyle: TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 16,
                                              ),
                                              onChanged: (value) {
                                                final newPrice = double.tryParse(value);
                                                if (newPrice != null) {
                                                  priceNotifier.value = newPrice;
                                                }
                                              },
                                            );
                                          }
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Кнопка вызова такси
                                Padding(
                                  padding: EdgeInsets.only(top: 8, bottom: 16),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Проверка полей
                                      if ((wm.savedFromAddress.value ?? '').isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Пожалуйста, укажите пункт отправления')),
                                        );
                                        return;
                                      }
                                      
                                      if ((wm.savedToAddress.value ?? '').isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Пожалуйста, укажите пункт назначения')),
                                        );
                                        return;
                                      }
                                      
                                      // Создание формы заказа
                                      final orderForm = DriverOrderForm(
                                        fromAddress: Required.dirty(wm.savedFromAddress.value ?? ''),
                                        toAddress: Required.dirty(wm.savedToAddress.value ?? ''),
                                        fromMapboxId: Required.dirty(wm.savedFromMapboxId.value ?? ''),
                                        toMapboxId: Required.dirty(wm.savedToMapboxId.value ?? ''),
                                        cost: Required.dirty(priceNotifier.value.round()),
                                        comment: commentController.text, // Используем текст из поля комментария
                                      );
                                      
                                      // Создание заказа
                                      wm.createDriverOrder(orderForm);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: Text(
                                      'Вызвать',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    );
  }

  // Map utility methods - completely revamped with smaller marker sizes
  Future<void> _addImageFromAsset(MapboxMap mapboxController, String name, String assetName) async {
    try {
      final ByteData bytes = await rootBundle.load(assetName);
      final Uint8List list = bytes.buffer.asUint8List();
      final image = await decodeImageFromList(list);
      
      // Create a custom scaled version for point_a and point_b to make them much smaller
      if (name == 'point_a' || name == 'point_b') {
        // Scale down to 50% of original size
        final scaleFactor = 0.5;
        final ui.Codec codec = await ui.instantiateImageCodec(list);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image originalImage = frameInfo.image;
        
        // Calculate scaled dimensions
        final int scaledWidth = (originalImage.width * scaleFactor).round();
        final int scaledHeight = (originalImage.height * scaleFactor).round();
        
        // Create a scaled version of the image
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        canvas.drawImageRect(
          originalImage,
          Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
          Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
          Paint()..filterQuality = FilterQuality.high
        );
        
        final ui.Picture picture = recorder.endRecording();
        final ui.Image scaledImage = await picture.toImage(scaledWidth, scaledHeight);
        final ByteData? scaledData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
        
        if (scaledData != null) {
          final Uint8List scaledList = scaledData.buffer.asUint8List();
          await mapboxController.style.addStyleImage(
            name,
            1.0,
            MbxImage(
              width: scaledWidth,
              height: scaledHeight,
              data: scaledList,
            ),
            false, // sdf
            [], // stretchX
            [], // stretchY
            null, // content
          );
          print('Added scaled image for $name with dimensions $scaledWidth x $scaledHeight (50% of original)');
          return;
        }
      }
      
      // For other images or if scaling fails, add normally but with appropriate scale
      double scale = 1.0;
      if (name == 'car_icon') scale = 0.8;
      
      await mapboxController.style.addStyleImage(
        name,
        scale,
        MbxImage(
          width: image.width,
          height: image.height,
          data: list,
        ),
        false, // sdf
        [], // stretchX
        [], // stretchY
        null, // content
      );
      
      print('Added normal image for $name with scale: $scale');
    } catch (e) {
      print('Error adding image asset: $e');
    }
  }
  
  Future<void> _setupMapLocalization(MapboxMap mapboxController) async {
    try {
      // Set Russian localization for map
      await mapboxController.style.setStyleImportConfigProperty(
        "basemap",
        "language",
        "ru" // Russian language
      );
    } catch (e) {
      print('Error setting map localization: $e');
    }
  }
  
  // Setup additional map styling
  Future<void> _setupMapStyling(MapboxMap mapboxController) async {
    try {
      // Customize map styling for better appearance
      // These are subtle improvements that make the map look more professional
      await mapboxController.style.setStyleImportConfigProperty(
        "basemap",
        "showPointOfInterestLabels",
        "true"
      );
      
      await mapboxController.style.setStyleImportConfigProperty(
        "basemap", 
        "lightPreset", 
        "day"
      );
    } catch (e) {
      print('Error setting map styling: $e');
    }
  }

  // Method to display route between points on main map with improved visuals
  Future<void> displayRouteOnMainMap(geotypes.Position fromPosition, geotypes.Position toPosition, ITenantHomeWM wm) async {
    try {
      print('Отображение маршрута на главной карте...');
      print('Координаты from: ${fromPosition.lat}, ${fromPosition.lng}');
      print('Координаты to: ${toPosition.lat}, ${toPosition.lng}');
      
      // Get route from Mapbox API
      final mapboxApi = inject<MapboxApi>();
      final directions = await mapboxApi.getDirections(
        fromLat: fromPosition.lat.toDouble(),
        fromLng: fromPosition.lng.toDouble(),
        toLat: toPosition.lat.toDouble(),
        toLng: toPosition.lng.toDouble(),
      );
      
      if (directions == null) {
        print('Не удалось получить маршрут от API: directions is null');
        return;
      }
      
      print('Получен ответ от API маршрутов: ${directions.toString().substring(0, min(directions.toString().length, 200))}...');
      
      // Remove existing route layers and sources if they exist
      final mapController = wm.mapboxMapController;
      if (mapController == null) {
        print('Ошибка: контроллер карты не инициализирован');
        return;
      }
      
      try {
        for (final layerId in ['main-route-layer', 'main-route-outline-layer', 'main-markers-layer', 'main-route-progress-layer']) {
          if (await mapController.style.styleLayerExists(layerId)) {
            await mapController.style.removeStyleLayer(layerId);
            print('Удален слой $layerId');
          }
        }
        
        for (final sourceId in ['main-route-source', 'main-markers-source']) {
          if (await mapController.style.styleSourceExists(sourceId)) {
            await mapController.style.removeStyleSource(sourceId);
            print('Удален источник $sourceId');
          }
        }
      } catch (e) {
        print('Ошибка при удалении существующих слоев: $e');
      }
      
      // Create GeoJSON LineString from route geometry
      if (!directions.containsKey('routes') || directions['routes'] == null || directions['routes'].isEmpty) {
        print('В ответе API нет маршрутов');
        return;
      }
      
      final routeGeometry = directions['routes'][0]['geometry'];
      print('Геометрия маршрута: ${routeGeometry.toString().substring(0, min(routeGeometry.toString().length, 100))}...');
      
      final lineString = {
        "type": "Feature",
        "geometry": routeGeometry,
        "properties": {}
      };
      
      // Convert to JSON
      final jsonData = json.encode({
        "type": "FeatureCollection",
        "features": [lineString]
      });
      
      // Add data source for route
      await mapController.style.addSource(GeoJsonSource(
        id: 'main-route-source',
        data: jsonData,
      ));
      print('Добавлен источник данных для маршрута');
      
      // Add outline layer (white border to make route more visible)
      await mapController.style.addLayer(LineLayer(
        id: 'main-route-outline-layer',
        sourceId: 'main-route-source',
        lineColor: Colors.white.value,
        lineWidth: 8.0,
        lineOpacity: 0.9,
      ));
      
      // Add main route line layer with primary color
      await mapController.style.addLayer(LineLayer(
        id: 'main-route-layer',
        sourceId: 'main-route-source',
        lineColor: primaryColor.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
      print('Добавлены слои линии для маршрута');
      
      // Add markers for origin and destination points
      try {
        // Add GeoJSON for markers
        final markersJson = {
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
            },
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
        
        // Add data source for markers
        await mapController.style.addSource(GeoJsonSource(
          id: 'main-markers-source',
          data: json.encode(markersJson),
        ));
        print('Добавлен источник данных для маркеров');
        
        // Add symbol layer for markers
        await mapController.style.addLayer(SymbolLayer(
          id: 'main-markers-layer',
          sourceId: 'main-markers-source',
          iconImage: "{icon}",
          iconSize: 0.3,
          iconAnchor: IconAnchor.BOTTOM,
        ));
        print('Добавлен слой символов для маркеров');
      } catch (e) {
        print('Ошибка при добавлении маркеров: $e');
      }
      
      // Fit camera to show entire route
      final bounds = directions['routes'][0]['bounds'];
      if (bounds != null) {
        final southwest = bounds[0];
        final northeast = bounds[1];
        
        final camera = await mapController.cameraForCoordinateBounds(
          CoordinateBounds(
            southwest: Point(coordinates: geotypes.Position(southwest[0], southwest[1])),
            northeast: Point(coordinates: geotypes.Position(northeast[0], northeast[1])),
            infiniteBounds: false
          ),
          MbxEdgeInsets(top: 150, left: 50, bottom: 350, right: 50),
          null, // bearing
          null, // pitch
          null, // maxZoom
          null, // minZoom
        );
        
        await mapController.flyTo(
          camera,
          MapAnimationOptions(duration: 1000),
        );
        print('Камера карты обновлена для отображения всего маршрута');
      }
      
      // Lock map interaction if fixed mode is enabled
      if (wm.isMapFixed.value == true) {
        try {
          await mapController.gestures.updateSettings(
            GesturesSettings(
              rotateEnabled: false,
              scrollEnabled: false,
              doubleTapToZoomInEnabled: false,
              doubleTouchToZoomOutEnabled: false,
              quickZoomEnabled: false,
              pitchEnabled: false,
            )
          );
          
          print('Взаимодействие с картой заблокировано');
        } catch (e) {
          print('Ошибка при блокировке взаимодействия с картой: $e');
        }
      }
      
      // Update route display state
      wm.setRouteDisplayed(true);
      
      print('Маршрут успешно отображен на главной карте');
    } catch (e) {
      print('Ошибка при отображении маршрута на главной карте: $e');
    }
  }

  // Панель запроса разрешений на геолокацию
  Widget _buildLocationPermissionBottomSheet(ITenantHomeWM wm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, -2),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(
            width: double.infinity,
            child: Text(
              'Для заказа пожалуйста поделитесь геолокацией',
              style: text400Size24Greyscale60,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton.primary(
              onPressed: () => wm.determineLocationPermission(
                force: true,
              ),
              text: 'Включить геолокацию',
              textStyle: text400Size16White,
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // Панель активного заказа
  Widget _buildActiveOrderBottomSheet(ActiveClientRequestModel activeOrder, UserDomain me, ITenantHomeWM wm) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: [0.35, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: Offset(0, -2),
                spreadRadius: 1,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: ClampingScrollPhysics(),
            child: ActiveClientOrderBottomSheet(
              me: me,
              activeOrder: activeOrder,
              activeOrderListener: wm.activeOrder,
              onCancel: wm.cancelActiveClientOrder,
            ),
          ),
        );
      },
    );
  }

  // Helper method to build address fields
  Widget _buildAddressField({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String hint,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: TextStyle(
                  color: value.isEmpty ? Colors.grey : Colors.black87,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Вспомогательный метод для разбора Mapbox ID
  geotypes.Position? _parseMapboxId(String mapboxId) {
    try {
      final parts = mapboxId.split(';');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          return geotypes.Position(lng, lat);
        }
      }
    } catch (e) {
      print('Ошибка при разборе mapboxId: $e');
    }
    return null;
  }
}
