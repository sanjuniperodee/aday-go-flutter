import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/images.dart';
import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart';
import 'package:aktau_go/interactors/location_interactor.dart';
import 'package:aktau_go/interactors/order_requests_interactor.dart';
import 'package:aktau_go/ui/tenant_home/tenant_home_wm.dart';
import 'package:aktau_go/ui/tenant_home/widgets/active_client_order_bottom_sheet.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart' as vg;
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geotypes/geotypes.dart' as geotypes;

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
import 'package:flutter_svg/flutter_svg.dart' as svg;
class TenantHomeScreen extends ElementaryWidget<ITenantHomeWM> {
  TenantHomeScreen({
    Key? key,
  }) : super(
          (context) => defaultTenantHomeWMFactory(context),
        );

  static const double _defaultPrice = 400;

  // Флаг готовности карты
  bool _isMapReady = false;

  @override
  Widget build(ITenantHomeWM wm) {
    final ValueNotifier<double> priceNotifier = ValueNotifier<double>(_defaultPrice);
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
        final bool isRouteDisplayed = wm.isRouteDisplayed.value ?? false;
        final bool isMapFixed = wm.isMapFixed.value ?? false;
        
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
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
                            userLocation?.lng ?? 51.1973,
                            userLocation?.lat ?? 43.6532,
                          )),
                          zoom: 18.0,
                        ),
                        onMapCreated: (mapboxController) async {
                          wm.setMapboxController(mapboxController);
                          
                          _addImageFromAsset(mapboxController, 'point_b', 'assets/images/point_b.png');
                          _addImageFromAsset(mapboxController, 'point_a', 'assets/images/point_a.png');
                          
                          // Предварительно загружаем иконку машины
                          try {
                            await _loadCarIconFromPng(mapboxController);
                            print('✅ Иконка машины предварительно загружена');
                          } catch (e) {
                            print('⚠️ Не удалось предварительно загрузить иконку машины: $e');
                            try {
                              await _createFallbackCarIcon(mapboxController);
                              print('✅ Fallback иконка машины создана');
                            } catch (e2) {
                              print('❌ Не удалось создать fallback иконку: $e2');
                            }
                          }
                          
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
                          
                          _setupMapLocalization(mapboxController);
                          
                          await _setupMapStyling(mapboxController);
                          
                          wm.driverLocation.addListener(() {
                            final driverPos = wm.driverLocation.value;
                            final activeOrder = wm.activeOrder.value;
                            final userPos = wm.userLocation.value;

                            if (driverPos != null) {
                              print('🚗 Получено обновление позиции водителя: ${driverPos.lat}, ${driverPos.lng}');
                              
                              // Всегда обновляем маркер водителя на карте
                              unawaited(_updateDriverMarkerWithAnimation(mapboxController, driverPos));
                              
                              // Проверяем, нужно ли обновить маршрут
                              if (activeOrder != null) {
                                final status = activeOrder.order?.orderStatus;
                                
                                if (status == 'ACCEPTED' || status == 'STARTED') {
                                  // Водитель едет к клиенту - обновляем маршрут от новой позиции к точке A
                                  print('🔄 Обновление маршрута (${status}): водитель -> клиент');
                                  if (userPos != null) {
                                    unawaited(_updateRouteBasedOnOrderStatus(
                                      mapboxController,
                                      activeOrder,
                                      userPos,
                                      driverPos
                                    ));
                                  }
                                } else if (status == 'WAITING') {
                                  // Водитель ожидает клиента - только обновляем позицию водителя, без маршрута
                                  print('🔄 Обновление позиции водителя в статусе WAITING (ожидание)');
                                  // Маршрут не обновляем, только обновили маркер выше
                                } else if (status == 'ONGOING') {
                                  // Водитель везет клиента - обновляем маршрут от новой позиции к точке B
                                  print('🔄 Обновление маршрута (ONGOING): водитель -> место назначения');
                                  if (userPos != null) {
                                    unawaited(_updateRouteBasedOnOrderStatus(
                                      mapboxController,
                                      activeOrder,
                                      userPos,
                                      driverPos
                                    ));
                                  }
                                }
                              }
                            }
                          });
                          
                          wm.activeOrder.addListener(() {
                            final activeOrder = wm.activeOrder.value;
                            final userPos = wm.userLocation.value;
                            final driverPos = wm.driverLocation.value;
                            
                            if (activeOrder != null && userPos != null) {
                              unawaited(_handleActiveOrderChange(
                                mapboxController,
                                activeOrder,
                                userPos,
                                driverPos
                              ));
                            } else if (activeOrder == null) {
                              unawaited(_clearAllMapElements(mapboxController));
                            }
                          });
                          
                          Timer.periodic(Duration(seconds: 10), (timer) {
                            final activeOrder = wm.activeOrder.value;
                            if (activeOrder != null) {
                              final status = activeOrder.order?.orderStatus;
                              if (status == 'ACCEPTED' || status == 'STARTED' || status == 'ONGOING') {
                                print('🔄 Периодическое обновление маршрута для статуса: $status');
                                final userPos = wm.userLocation.value;
                                final driverPos = wm.driverLocation.value;
                                
                                if (userPos != null) {
                                  unawaited(_updateRouteBasedOnOrderStatus(
                                    mapboxController,
                                    activeOrder,
                                    userPos,
                                    driverPos
                                  ));
                                }
                              }
                            }
                          });
                          
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            unawaited(_restoreActiveOrderState(mapboxController, wm));
                          });
                        },
                      ),
                    ),
                    
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
                              onTap: () {
                                if (isRouteDisplayed) {
                                  wm.clearRoute();
                                }
                                wm.getMyLocation();
                              },
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
                  ],
                ),
              ),
              
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
                  if (![
                    LocationPermission.always,
                    LocationPermission.whileInUse
                  ].contains(locationPermission)) {
                    return _buildLocationPermissionBottomSheet(context, wm);
                  }
                  
                  if (activeOrder != null) {
                    return _buildActiveOrderBottomSheet(activeOrder, me!, wm);
                  }
                  
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
                          
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                StateNotifierBuilder(
                                  listenableState: wm.savedFromAddress,
                                  builder: (context, String? fromAddress) {
                                    return _buildAddressField(
                                      context: context,
                                      icon: Icons.radio_button_checked,
                                      iconColor: Colors.green,
                                      hint: 'Откуда',
                                      value: fromAddress ?? '',
                                      onTap: () async {
                                        try {
                                          print('Открываю экран выбора адреса "Откуда"');
                                          
                                          final args = MapAddressPickerScreenArgs(
                                            placeName: wm.savedFromAddress.value,
                                            position: wm.savedFromMapboxId.value != null ? 
                                                _parseMapboxId(wm.savedFromMapboxId.value!) : null,
                                            onSubmit: (position, placeName) {
                                              print('Выбран адрес отправления: $placeName в позиции ${position.lat}, ${position.lng}');
                                              
                                              final actualPlaceName = placeName.isNotEmpty ? placeName : "Адрес не найден";
                                              print('Сохраняем адрес отправления: $actualPlaceName');
                                              
                                              wm.saveOrderAddresses(
                                                fromAddress: actualPlaceName,
                                                toAddress: wm.savedToAddress.value ?? '',
                                                fromMapboxId: '${position.lat};${position.lng}',
                                                toMapboxId: wm.savedToMapboxId.value ?? '',
                                              );
                                              wm.setRouteDisplayed(false);
                                              
                                              print('Адрес отправления обновлен на: ${wm.savedFromAddress.value}');
                                            },
                                          );
                                          
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
                                    );
                                  },
                                ),
                                
                                StateNotifierBuilder(
                                  listenableState: wm.savedToAddress,
                                  builder: (context, String? toAddress) {
                                    return _buildAddressField(
                                      context: context,
                                      icon: Icons.location_on,
                                      iconColor: Colors.red,
                                      hint: 'Куда',
                                      value: toAddress ?? '',
                                      onTap: () async {
                                        try {
                                          print('Открываю экран выбора адреса "Куда"');
                                          
                                          final args = MapAddressPickerScreenArgs(
                                            placeName: wm.savedToAddress.value,
                                            position: wm.savedToMapboxId.value != null ? 
                                                _parseMapboxId(wm.savedToMapboxId.value!) : null,
                                            fromPosition: wm.savedFromMapboxId.value != null ? 
                                                _parseMapboxId(wm.savedFromMapboxId.value!) : null,
                                            onSubmit: (position, placeName) {
                                              print('Выбран адрес назначения: $placeName в позиции ${position.lat}, ${position.lng}');
                                              
                                              final actualPlaceName = placeName.isNotEmpty ? placeName : "Адрес не найден";
                                              print('Сохраняем адрес назначения: $actualPlaceName');
                                              
                                              wm.saveOrderAddresses(
                                                fromAddress: wm.savedFromAddress.value ?? '',
                                                toAddress: actualPlaceName,
                                                fromMapboxId: wm.savedFromMapboxId.value ?? '',
                                                toMapboxId: '${position.lat};${position.lng}',
                                              );
                                              wm.setRouteDisplayed(false);
                                              
                                              print('Адрес назначения обновлен на: ${wm.savedToAddress.value}');
                                            },
                                          );
                                          
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
                                    );
                                  },
                                ),
                                
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
                                
                                Padding(
                                  padding: EdgeInsets.only(top: 8, bottom: 16),
                                  child: DoubleSourceBuilder(
                                    firstSource: wm.savedFromAddress,
                                    secondSource: wm.savedToAddress,
                                    builder: (context, String? fromAddress, String? toAddress) {
                                      return ElevatedButton(
                                        onPressed: () {
                                          if ((fromAddress ?? '').isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Пожалуйста, укажите пункт отправления')),
                                            );
                                            return;
                                          }
                                          
                                          if ((toAddress ?? '').isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Пожалуйста, укажите пункт назначения')),
                                            );
                                            return;
                                          }
                                          
                                          final orderForm = DriverOrderForm(
                                            fromAddress: Required.dirty(fromAddress ?? ''),
                                            toAddress: Required.dirty(toAddress ?? ''),
                                            fromMapboxId: Required.dirty(wm.savedFromMapboxId.value ?? ''),
                                            toMapboxId: Required.dirty(wm.savedToMapboxId.value ?? ''),
                                            cost: Required.dirty(priceNotifier.value.round()),
                                            comment: commentController.text,
                                          );
                                          
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
                                      );
                                    },
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



  Future<void> _addImageFromAsset(MapboxMap mapboxController, String name, String assetName) async {
    try {
      final ByteData bytes = await rootBundle.load(assetName);
      final Uint8List list = bytes.buffer.asUint8List();
      final image = await decodeImageFromList(list);
      
      if (name == 'point_a' || name == 'point_b') {
        final scaleFactor = 0.5;
        final ui.Codec codec = await ui.instantiateImageCodec(list);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image originalImage = frameInfo.image;
        
        final int scaledWidth = (originalImage.width * scaleFactor).round();
        final int scaledHeight = (originalImage.height * scaleFactor).round();
        
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
            false,
            [],
            [],
            null,
          );
          print('Added scaled image for $name with dimensions $scaledWidth x $scaledHeight (50% of original)');
          return;
        }
      }
      
      double scale = 1.0;
      
      await mapboxController.style.addStyleImage(
        name,
        scale,
        MbxImage(
          width: image.width,
          height: image.height,
          data: list,
        ),
        false,
        [],
        [],
        null,
      );
      
      print('Added normal image for $name with scale: $scale');
    } catch (e) {
      print('Error adding image asset: $e');
    }
  }
  
  Future<void> _setupMapLocalization(MapboxMap mapboxController) async {
    try {
      await mapboxController.style.setStyleImportConfigProperty(
        "basemap",
        "language",
        "ru"
      );
    } catch (e) {
      print('Error setting map localization: $e');
    }
  }
  
  Future<void> _setupMapStyling(MapboxMap mapboxController) async {
    try {
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

  Future<void> displayRouteOnMainMap(geotypes.Position fromPosition, geotypes.Position toPosition, ITenantHomeWM wm) async {
    try {
      print('Отображение маршрута на главной карте...');
      print('Координаты from: ${fromPosition.lat}, ${fromPosition.lng}');
      print('Координаты to: ${toPosition.lat}, ${toPosition.lng}');
      
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
      
      final jsonData = json.encode({
        "type": "FeatureCollection",
        "features": [lineString]
      });
      
      await mapController.style.addSource(GeoJsonSource(
        id: 'main-route-source',
        data: jsonData,
      ));
      print('Добавлен источник данных для маршрута');
      
      await mapController.style.addLayer(LineLayer(
        id: 'main-route-outline-layer',
        sourceId: 'main-route-source',
        lineColor: Colors.white.value,
        lineWidth: 8.0,
        lineOpacity: 0.9,
      ));
      
      await mapController.style.addLayer(LineLayer(
        id: 'main-route-layer',
        sourceId: 'main-route-source',
        lineColor: primaryColor.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
      print('Добавлены слои линии для маршрута');
      
      try {
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
        
        await mapController.style.addSource(GeoJsonSource(
          id: 'main-markers-source',
          data: json.encode(markersJson),
        ));
        print('Добавлен источник данных для маркеров');
        
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
      
      final bounds = directions['routes'][0]['bounds'];
      if (bounds != null) {
        final southwest = bounds[0];
        final northeast = bounds[1];
        
        final midLat = (southwest[1] + northeast[1]) / 2;
        final midLng = (southwest[0] + northeast[0]) / 2;
        await mapController.flyTo(
          CameraOptions(
            center: Point(coordinates: geotypes.Position(midLng, midLat)),
            zoom: 12.0,
            padding: MbxEdgeInsets(top: 100, left: 50, bottom: 300, right: 50),
          ),
          MapAnimationOptions(duration: 1000),
        );
        print('Камера карты обновлена для отображения всего маршрута');
      }
      
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
      
      wm.setRouteDisplayed(true);
      
      print('Маршрут успешно отображен на главной карте');
    } catch (e) {
      print('Ошибка при отображении маршрута на главной карте: $e');
    }
  }

  Widget _buildLocationPermissionBottomSheet(BuildContext context, ITenantHomeWM wm) {
    return PrimaryBottomSheet(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.my_location,
              color: primaryColor,
              size: 32,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Включите геолокацию',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Чтобы показать ближайших водителей и корректно рассчитать стоимость поездки, приложению нужен доступ к вашей геолокации.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: greyscale60,
            ),
          ),

          const SizedBox(height: 24),

          PrimaryButton.primary(
            onPressed: () => wm.determineLocationPermission(force: true),
            text: 'Разрешить доступ',
            textStyle: text400Size16White,
          ),

          const SizedBox(height: 12),

          PrimaryButton.secondary(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            text: 'Не сейчас',
            textStyle: TextStyle(
              fontSize: 16,
              color: greyscale60,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
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

  Future<void> _addDriverMarkerOnMap(MapboxMap mapboxController, geotypes.Position driverPosition) async {
    try {
        // Удаляем старый маркер если есть
        await _clearDriverMarker(mapboxController);

        // Проверяем, загружена ли иконка машины в Mapbox
        bool carIconExists = false;
        try {
          carIconExists = await mapboxController.style.hasStyleImage('professional_car_icon');
          print('🔍 Проверка иконки машины: $carIconExists');
        } catch (e) {
          print('⚠️ Ошибка при проверке иконки машины: $e');
          carIconExists = false;
        }
        
        // Если иконка не загружена, загружаем ее
        if (!carIconExists) {
          print('🔄 Иконка машины не найдена, загружаем...');
          try {
            await _loadCarIconFromPng(mapboxController);
            // Проверяем еще раз после загрузки
            carIconExists = await mapboxController.style.hasStyleImage('professional_car_icon');
            print('✅ Иконка машины загружена: $carIconExists');
          } catch (e) {
            print('⚠️ Не удалось загрузить PNG иконку машины, используем fallback: $e');
            await _createFallbackCarIcon(mapboxController);
            carIconExists = await mapboxController.style.hasStyleImage('professional_car_icon');
            print('✅ Fallback иконка машины создана: $carIconExists');
          }
        }

        // Создаем GeoJSON источник для маркера водителя с ФИКСИРОВАННЫМ ID
        final driverFeatureJson = {
          "type": "Feature",
          "id": "driver-marker",
          "properties": {
            "icon": "professional_car_icon"
          },
          "geometry": {
            "type": "Point",
            "coordinates": [driverPosition.lng, driverPosition.lat]
          }
        };

        final source = GeoJsonSource(
          id: 'driver-marker-source',
          data: json.encode(driverFeatureJson),
        );

        await mapboxController.style.addSource(source);

        // Создаем слой для маркера водителя с ФИКСИРОВАННЫМ ID
        final layer = SymbolLayer(
          id: 'driver-marker-layer',
          sourceId: 'driver-marker-source',
          iconAllowOverlap: true,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: 0.7, // Фиксированный размер иконки
          iconImage: "professional_car_icon",
        );

        await mapboxController.style.addLayer(layer);

        print('🚗 Профессиональный маркер водителя добавлен на карту в позиции: ${driverPosition.lat}, ${driverPosition.lng}');
    } catch (e) {
        print('❌ Ошибка при добавлении маркера водителя на карту: $e');
    }
}

  Future<void> _clearDriverMarker(MapboxMap mapboxController) async {
    try {
      // Удаляем все возможные ID слоев маркера водителя
      final layersToRemove = [
        'driver-marker-layer',
        'driver-layer',
        'driver-source-layer',
        'client-driver-marker-layer',
      ];
      
      // Удаляем все возможные ID источников маркера водителя
      final sourcesToRemove = [
        'driver-marker-source',
        'driver-source',
        'client-driver-marker-source',
      ];
      
      // Удаляем слои
      for (final layerId in layersToRemove) {
        try {
          if (await mapboxController.style.styleLayerExists(layerId)) {
            await mapboxController.style.removeStyleLayer(layerId);
            print('✅ Удален слой маркера водителя: $layerId');
          }
        } catch (e) {
          // Игнорируем ошибки при удалении отдельных слоев
          print('⚠️ Ошибка при удалении слоя $layerId: $e');
        }
      }
      
      // Удаляем источники
      for (final sourceId in sourcesToRemove) {
        try {
          if (await mapboxController.style.styleSourceExists(sourceId)) {
            await mapboxController.style.removeStyleSource(sourceId);
            print('✅ Удален источник маркера водителя: $sourceId');
          }
        } catch (e) {
          // Игнорируем ошибки при удалении отдельных источников
          print('⚠️ Ошибка при удалении источника $sourceId: $e');
        }
      }
      
      print('🧹 Маркер водителя успешно очищен с карты');
    } catch (e) {
      print('❌ Ошибка при очистке маркера водителя: $e');
    }
  }

  // Загружаем PNG иконку машины
  Future<void> _loadCarIconFromPng(MapboxMap mapboxController) async {
    try {
      print('🔄 Загружаем PNG иконку машины...');
      
      // Сначала проверяем, не загружена ли уже иконка
      bool iconExists = await mapboxController.style.hasStyleImage('professional_car_icon');
      if (iconExists) {
        print('✅ Иконка машины уже загружена');
        return;
      }
      
      final ByteData data = await rootBundle.load('assets/images/car-white-svgrepo-com.png');
      print('📁 PNG файл загружен, размер: ${data.lengthInBytes} байт');
      
      // Убедимся что размеры разумные для Mapbox
      const int width = 60;
      const int height = 60;
      
      // Преобразуем PNG данные в формат, который Mapbox сможет обработать
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width,
        targetHeight: height,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? resizedData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (resizedData == null) {
        throw Exception('Не удалось преобразовать изображение');
      }
      
      print('🖼️ Изображение преобразовано, размер: ${resizedData.lengthInBytes} байт');
      
      await mapboxController.style.addStyleImage(
        'professional_car_icon', // Используем одинаковое имя везде
        1.0,
        MbxImage(
          width: width,
          height: height,
          data: resizedData.buffer.asUint8List(),
        ),
        false,
        [],
        [],
        null,
      );

      // Проверяем, что иконка действительно добавлена
      bool added = await mapboxController.style.hasStyleImage('professional_car_icon');
      if (added) {
        print('✅ PNG иконка машины успешно добавлена как professional_car_icon');
      } else {
        throw Exception('Иконка не была добавлена в Mapbox');
      }
    } catch (e) {
      print('❌ Ошибка при загрузке PNG иконки: $e');
      throw e; // Прокидываем ошибку дальше для обработки в вызывающем методе
    }
  }
  
  // Fallback иконка машины (улучшенная)
  Future<void> _createFallbackCarIcon(MapboxMap mapboxController) async {
    try {
      print('🔄 Создаем fallback иконку машины...');
      
      const size = 60;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Фон с тенью
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(size / 2 + 2, size / 2 + 2), 25, shadowPaint);

      // Основной круг
      final bgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size / 2, size / 2), 23, bgPaint);

      // Граница
      final borderPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(size / 2, size / 2), 23, borderPaint);

      // Иконка машины (более детальная)
      final carPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      // Кузов машины
      final carBody = RRect.fromLTRBR(
        size / 2 - 12, size / 2 - 6,
        size / 2 + 12, size / 2 + 6,
        const Radius.circular(3)
      );
      canvas.drawRRect(carBody, carPaint);

      // Колеса
      final wheelPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(size / 2 - 8, size / 2 + 6), 3, wheelPaint);
      canvas.drawCircle(Offset(size / 2 + 8, size / 2 + 6), 3, wheelPaint);

      // Фары
      final lightPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(size / 2 - 8, size / 2 - 4), 2, lightPaint);
      canvas.drawCircle(Offset(size / 2 + 8, size / 2 - 4), 2, lightPaint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        await mapboxController.style.addStyleImage(
          'professional_car_icon',
          1.0,
          MbxImage(
            width: size,
            height: size,
            data: byteData.buffer.asUint8List(),
          ),
          false,
          [],
          [],
          null,
        );
        
        // Проверяем, что иконка действительно добавлена
        bool added = await mapboxController.style.hasStyleImage('professional_car_icon');
        if (added) {
          print('✅ Fallback иконка машины успешно создана');
        } else {
          throw Exception('Fallback иконка не была добавлена в Mapbox');
        }
      } else {
        throw Exception('Не удалось создать изображение');
      }
    } catch (e) {
      print('❌ Ошибка создания fallback иконки машины: $e');
      throw e;
    }
  }

  Future<void> _updateRouteBasedOnOrderStatus(
    MapboxMap mapboxController,
    ActiveClientRequestModel order,
    geotypes.Position? userLocation,
    geotypes.Position? driverLocation
  ) async {
    print('🔄 Обновление маршрута в зависимости от статуса заказа...');
    print('📋 Статус заказа: ${order.order?.orderStatus}');
    print('👤 Позиция пользователя: ${userLocation?.lat}, ${userLocation?.lng}');
    print('🚗 Позиция водителя: ${driverLocation?.lat}, ${driverLocation?.lng}');

    try {
      // Очищаем предыдущие маршруты и маркеры
      await _clearPreviousRoutes(mapboxController);

      final status = order.order?.orderStatus;
      final fromMapboxId = order.order?.fromMapboxId;
      final toMapboxId = order.order?.toMapboxId;

      if (fromMapboxId == null || toMapboxId == null) {
        print('⚠️ Отсутствуют координаты для построения маршрута');
        return;
      }

      print('📍 fromMapboxId: "$fromMapboxId"');
      print('📍 toMapboxId: "$toMapboxId"');

      // Парсим координаты из строк mapboxId
      final fromCoords = _parseMapboxCoordinates(fromMapboxId);
      final toCoords = _parseMapboxCoordinates(toMapboxId);

      if (fromCoords == null || toCoords == null) {
        print('⚠️ Не удалось распарсить координаты');
        return;
      }

      print('🧩 Парсинг fromMapboxId: ${fromCoords.lat}, ${fromCoords.lng}');
      print('🧩 Парсинг toMapboxId: ${toCoords.lat}, ${toCoords.lng}');

      // Обрабатываем разные статусы заказа
      switch (status) {
        case 'CREATED':
          // Заказ создан, но еще не принят - показываем маршрут от пользователя к месту назначения
          if (userLocation != null) {
            print('✅ CREATED: Отображаем маршрут от пользователя к месту назначения');
            await _displayRouteWithDriverMarker(
              mapboxController,
              fromCoords,
              toCoords,
              showDriver: false,
              showPointA: true,
              showPointB: true,
            );
          }
          break;

        case 'STARTED':
        case 'ACCEPTED':
          // Водитель едет к клиенту - показываем маршрут от водителя к клиенту
          if (driverLocation != null) {
            print('✅ STARTED: Отображаем маршрут от водителя к клиенту');
            await _displayRouteWithDriverMarker(
              mapboxController,
              driverLocation,
              fromCoords,
              showDriver: true,
              showPointA: true,
              showPointB: false,
            );
          }
          break;

        case 'WAITING':
          // Водитель ожидает клиента - показываем только маркер водителя
          if (driverLocation != null) {
            print('✅ WAITING: Водитель ожидает клиента, отображаем только машину');
            
            // Загружаем маркеры, но не отображаем маршрут
            await _loadPointMarkers(mapboxController);
            
            // Добавляем только маркер водителя
            await _clearDriverMarker(mapboxController);
            await _addDriverMarkerOnMap(mapboxController, driverLocation);
            
            // Центрируем карту на водителе
            await mapboxController.flyTo(
              CameraOptions(
                center: Point(
                  coordinates: geotypes.Position(
                    driverLocation.lng,
                    driverLocation.lat,
                  ),
                ),
                zoom: 16.0,
              ),
              MapAnimationOptions(
                duration: 1000,
              ),
            );
          }
          break;

        case 'ONGOING':
          // Поездка началась - показываем маршрут от текущего положения водителя к месту назначения
          if (driverLocation != null) {
            print('✅ ONGOING: Отображаем маршрут от водителя к месту назначения');
            await _displayRouteWithDriverMarker(
              mapboxController,
              driverLocation,
              toCoords,
              showDriver: true,
              showPointA: false,
              showPointB: true,
            );
          }
          break;

        case 'COMPLETED':
        case 'REJECTED':
        case 'REJECTED_BY_CLIENT':
        case 'REJECTED_BY_DRIVER':
          // Заказ завершен или отменен - очищаем карту
          print('✅ COMPLETED/REJECTED: Очищаем карту');
          await _clearPreviousRoutes(mapboxController);
          await _clearDriverMarker(mapboxController);
          break;

        default:
          print('⚠️ Неизвестный статус заказа: $status');
          break;
      }
    } catch (e) {
      print('❌ Ошибка обновления маршрута: $e');
    }
  }

  // Парсит координаты из строки mapboxId формата "lat;lng"
  geotypes.Position? _parseMapboxCoordinates(String mapboxId) {
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

  // Очистка слоев маршрута
  Future<void> _clearPreviousRoutes(MapboxMap mapboxController) async {
    try {
      print('🧹 Начинаем ПОЛНУЮ очистку карты от всех маршрутов и маркеров...');
      
      // РАСШИРЕННАЯ ОЧИСТКА: удаляем ВСЕ возможные слои маршрутов и маркеров
      final layersToRemove = [
        // Основные слои маршрутов
        'route-layer',
        'route-outline-layer', 
        'markers-layer',
        'start-marker-layer',
        'end-marker-layer',
        // Основные слои с другими префиксами
        'main-route-layer',
        'main-route-outline-layer',
        'main-markers-layer',
        'main-markers-layer-a',
        'main-markers-layer-b',
        // Динамические слои
        'dynamic-route-layer',
        'dynamic-route-outline-layer',
        'dynamic-route-markers-layer',
        // Дополнительные слои
        'route-progress-layer',
        'static-markers-layer',
        'points-layer',
        // Слои водителя
        'driver-marker-layer',
        'client-driver-marker-layer',
        // Общие слои
        'destination-symbol-layer',
        'destination-icon-layer',
      ];
      
      final sourceToRemove = [
        // Основные источники
        'route-source',
        'markers-source',
        'points-source',
        // С префиксом main
        'main-route-source',
        'main-markers-source',
        'main-markers-source-a',
        'main-markers-source-b',
        // Динамические источники
        'dynamic-route-source',
        'dynamic-markers-source',
        // Дополнительные источники
        'static-markers-source',
        // Источники водителя
        'driver-marker-source',
        'client-driver-marker-source',
      ];
      
      // Также проверяем слои с индексами (сегменты маршрута)
      for (int i = 0; i < 10; i++) {
        layersToRemove.add('route-segment-$i');
        sourceToRemove.add('route-segment-$i-source');
        
        // Проверяем вложенные сегменты (для сложных маршрутов)
        for (int j = 0; j < 10; j++) {
          layersToRemove.add('route-segment-$i-$j');
          sourceToRemove.add('route-segment-$i-$j-source');
        }
      }
      
      // Удаляем слои
      for (final layerId in layersToRemove) {
        try {
          if (await mapboxController.style.styleLayerExists(layerId)) {
            await mapboxController.style.removeStyleLayer(layerId);
            print('✅ Удален слой: $layerId');
          }
        } catch (e) {
          // Игнорируем ошибки при удалении отдельных слоев
          print('⚠️ Ошибка при удалении слоя $layerId: $e');
        }
      }
      
      // Удаляем источники
      for (final sourceId in sourceToRemove) {
        try {
          if (await mapboxController.style.styleSourceExists(sourceId)) {
            await mapboxController.style.removeStyleSource(sourceId);
            print('✅ Удален источник: $sourceId');
          }
        } catch (e) {
          // Игнорируем ошибки при удалении отдельных источников
          print('⚠️ Ошибка при удалении источника $sourceId: $e');
        }
      }
      
      print('✅ Очистка карты успешно завершена');
    } catch (e) {
      print('❌ Ошибка очистки карты: $e');
    }
  }

  Future<void> _displayRouteWithDriverMarker(
    MapboxMap mapboxController,
    geotypes.Position fromPos,
    geotypes.Position toPos,
    {
      required bool showDriver,
      required bool showPointA,
      required bool showPointB,
    }
  ) async {
    try {
      // Сначала загружаем все необходимые иконки
      if (showPointA || showPointB) {
        await _loadPointMarkers(mapboxController);
      }
      
      if (showDriver) {
        // Маркер водителя загружается в методе _addDriverMarkerOnMap
      }
      
      // Отображаем маршрут
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
      await _clearPreviousRoutes(mapboxController);

      // Добавляем источник и слой маршрута
      await mapboxController.style.addSource(GeoJsonSource(
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

      await mapboxController.style.addLayer(LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: primaryColor.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));

      // Добавляем маркеры
      final markers = [];

      if (showPointA) {
        markers.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [fromPos.lng, fromPos.lat]
          },
          "properties": {
            "icon": "point_a"
          }
        });
      }

      if (showPointB) {
        markers.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [toPos.lng, toPos.lat]
          },
          "properties": {
            "icon": "point_b"
          }
        });
      }

      // Добавляем маркеры точек А и Б, если они есть
      if (markers.isNotEmpty) {
        await mapboxController.style.addSource(GeoJsonSource(
          id: 'markers-source',
          data: json.encode({
            "type": "FeatureCollection",
            "features": markers
          }),
        ));

        await mapboxController.style.addLayer(SymbolLayer(
          id: 'markers-layer',
          sourceId: 'markers-source',
          iconImage: "{icon}",
          iconSize: 0.5,
          iconAnchor: IconAnchor.BOTTOM,
          symbolZOrder: SymbolZOrder.AUTO,
        ));
        
        print('✅ Маркеры точек А и/или Б добавлены на карту');
      }
      
      // Добавляем маркер водителя в КОНЦЕ, чтобы он отображался ПОВЕРХ всего
      if (showDriver) {
        await _addDriverMarkerOnMap(mapboxController, fromPos);
      }

    } catch (e) {
      print('❌ Ошибка отображения маршрута: $e');
    }
  }

  Future<void> _displayDynamicRoute(
    MapboxMap mapboxController,
    geotypes.Position fromPos,
    geotypes.Position toPos,
    String description,
  ) async {
    try {
      await _clearPreviousRoutes(mapboxController);
      
      final mapboxApi = inject<MapboxApi>();
      final directions = await mapboxApi.getDirections(
        fromLat: fromPos.lat.toDouble(),
        fromLng: fromPos.lng.toDouble(),
        toLat: toPos.lat.toDouble(),
        toLng: toPos.lng.toDouble(),
      );

      if (directions == null || !directions.containsKey('routes') || directions['routes'].isEmpty) {
        print('❌ Не удалось получить маршрут');
        return;
      }

      final routeGeometry = directions['routes'][0]['geometry'];

      final lineString = {
        "type": "Feature",
        "geometry": routeGeometry,
        "properties": {}
      };

      final jsonData = json.encode({
        "type": "FeatureCollection",
        "features": [lineString]
      });

      await mapboxController.style.addSource(GeoJsonSource(
        id: 'dynamic-route-source',
        data: jsonData,
      ));

      await mapboxController.style.addLayer(LineLayer(
        id: 'dynamic-route-outline-layer',
        sourceId: 'dynamic-route-source',
        lineColor: Colors.white.value,
        lineWidth: 8.0,
        lineOpacity: 0.9,
      ));

      await mapboxController.style.addLayer(LineLayer(
        id: 'dynamic-route-layer',
        sourceId: 'dynamic-route-source',
        lineColor: primaryColor.value,
        lineWidth: 5.0,
        lineOpacity: 1.0,
      ));

      await _addRouteMarkers(mapboxController, fromPos, toPos);

      print('✅ $description отображен на карте');
    } catch (e) {
      print('❌ Ошибка отображения динамического маршрута: $e');
    }
  }

  Future<void> _fitCameraToRoute(
    MapboxMap mapboxController,
    geotypes.Position? driverPosition,
    geotypes.Position? destinationPosition,
  ) async {
    try {
      if (driverPosition == null || destinationPosition == null) return;

      // Рассчитываем границы для отображения всего маршрута
      final minLat = min(driverPosition.lat, destinationPosition.lat);
      final maxLat = max(driverPosition.lat, destinationPosition.lat);
      final minLng = min(driverPosition.lng, destinationPosition.lng);
      final maxLng = max(driverPosition.lng, destinationPosition.lng);

      // Добавляем небольшой отступ
      const padding = 0.01;
      final bounds = CoordinateBounds(
        southwest: Point(coordinates: geotypes.Position(minLng - padding, minLat - padding)),
        northeast: Point(coordinates: geotypes.Position(maxLng + padding, maxLat + padding)),
        infiniteBounds: false,
      );

      // Настраиваем камеру
      await mapboxController.flyTo(
        CameraOptions(
          center: Point(coordinates: geotypes.Position(
            (minLng + maxLng) / 2,
            (minLat + maxLat) / 2,
          )),
          zoom: 14.0,
          padding: MbxEdgeInsets(top: 100, left: 50, bottom: 300, right: 50),
        ),
        MapAnimationOptions(duration: 1000),
      );

    } catch (e) {
      print('❌ Ошибка настройки камеры: $e');
    }
  }

  Future<void> _updateDriverPositionAndRoute(
    MapboxMap mapboxController,
    geotypes.Position driverPos,
    ITenantHomeWM wm,
  ) async {
    try {
      final activeOrder = wm.activeOrder.value;
      if (activeOrder == null) return;

      await _addDriverMarkerOnMap(mapboxController, driverPos);

      final userPos = wm.userLocation.value;
      await _updateRouteBasedOnOrderStatus(
        mapboxController,
        activeOrder,
        userPos,
        driverPos
      );
    } catch (e) {
      print('❌ Ошибка обновления позиции водителя и маршрута: $e');
    }
  }

  Future<void> _handleActiveOrderChange(
    MapboxMap mapboxController,
    ActiveClientRequestModel activeOrder,
    geotypes.Position userPos,
    geotypes.Position? driverPos
  ) async {
    try {
      print('📦 Обработка изменения активного заказа...');
      print('📋 Статус заказа: ${activeOrder.order?.orderStatus}');
      
      // Очищаем предыдущие маршруты и маркеры
      await _clearPreviousRoutes(mapboxController);
      await _clearDriverMarker(mapboxController);
      
      // Обновляем отображение на карте в зависимости от статуса заказа
      await _updateRouteBasedOnOrderStatus(
        mapboxController,
        activeOrder,
        userPos,
        driverPos,
      );
      
    } catch (e) {
      print('❌ Ошибка обработки изменения активного заказа: $e');
    }
  }

  Future<void> _clearAllMapElements(MapboxMap mapboxController) async {
    try {
      print('🧹 Очистка всех элементов карты...');
      await _clearPreviousRoutes(mapboxController);
      await _clearDriverMarker(mapboxController);
    } catch (e) {
      print('❌ Ошибка очистки элементов карты: $e');
    }
  }

  Future<void> _restoreActiveOrderState(MapboxMap mapboxController, ITenantHomeWM wm) async {
    try {
      print('🔄 Восстановление состояния активного заказа после входа в приложение...');
      
      // Небольшая задержка, чтобы карта полностью загрузилась
      await Future.delayed(Duration(milliseconds: 500));
      
      // Получаем текущие данные
      final activeOrder = wm.activeOrder.value;
      final userPos = wm.userLocation.value;
      final driverPos = wm.driverLocation.value;
      
      if (activeOrder == null) {
        print('✅ Нет активного заказа для восстановления, карта остается чистой');
        // На всякий случай очищаем карту
        await _clearPreviousRoutes(mapboxController);
        await _clearDriverMarker(mapboxController);
        return;
      }
      
      // Проверяем, что у нас есть все необходимые данные
      if (userPos == null) {
        print('⚠️ Нет данных о местоположении пользователя, ожидаем...');
        return;
      }
      
      print('📋 Восстанавливаем заказ со статусом: ${activeOrder.order?.orderStatus}');
      
      // Полностью очищаем карту перед восстановлением
      await _clearPreviousRoutes(mapboxController);
      await _clearDriverMarker(mapboxController);
      
      // Обновляем отображение на карте в зависимости от статуса заказа
      await _updateRouteBasedOnOrderStatus(
        mapboxController,
        activeOrder,
        userPos,
        driverPos,
      );
      
      print('✅ Состояние активного заказа успешно восстановлено');
    } catch (e) {
      print('❌ Ошибка восстановления состояния активного заказа: $e');
    }
  }

  Future<void> _addRouteMarkers(MapboxMap mapboxController, geotypes.Position fromPos, geotypes.Position toPos) async {
    try {
      final markersJson = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [fromPos.lng, fromPos.lat]
            },
            "properties": {
              "icon": "point_a"
            }
          },
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [toPos.lng, toPos.lat]
            },
            "properties": {
              "icon": "point_b"
            }
          }
        ]
      };
      
      await mapboxController.style.addSource(GeoJsonSource(
        id: 'dynamic-route-markers-source',
        data: json.encode(markersJson),
      ));
      print('Добавлен источник данных для маркеров');
      
      await mapboxController.style.addLayer(SymbolLayer(
        id: 'dynamic-route-markers-layer',
        sourceId: 'dynamic-route-markers-source',
        iconImage: "{icon}",
        iconSize: 0.3,
        iconAnchor: IconAnchor.BOTTOM,
      ));
      print('Добавлен слой символов для маркеров');
    } catch (e) {
      print('Ошибка при добавлении маркеров: $e');
    }
  }

  Future<void> _addSpecificMarkers(
    MapboxMap mapboxController,
    geotypes.Position? pointAPos,
    geotypes.Position? pointBPos,
    {bool showPointA = true, bool showPointB = true}
  ) async {
    try {
      List<Map<String, dynamic>> features = [];
      
      if (showPointA && pointAPos != null) {
        features.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [pointAPos.lng, pointAPos.lat]
          },
          "properties": {
            "icon": "point_a"
          }
        });
      }
      
      if (showPointB && pointBPos != null) {
        features.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [pointBPos.lng, pointBPos.lat]
          },
          "properties": {
            "icon": "point_b"
          }
        });
      }
      
      if (features.isNotEmpty) {
        final markersJson = {
          "type": "FeatureCollection",
          "features": features
        };
        
        // Remove existing specific markers layer and source if they exist
        if (await mapboxController.style.styleLayerExists('specific-markers-layer')) {
          await mapboxController.style.removeStyleLayer('specific-markers-layer');
        }
        if (await mapboxController.style.styleSourceExists('specific-markers-source')) {
          await mapboxController.style.removeStyleSource('specific-markers-source');
        }
        
        // Add data source for markers
        await mapboxController.style.addSource(GeoJsonSource(
          id: 'specific-markers-source',
          data: json.encode(markersJson),
        ));
        
        // Add symbol layer for markers
        await mapboxController.style.addLayer(SymbolLayer(
          id: 'specific-markers-layer',
          sourceId: 'specific-markers-source',
          iconImage: "{icon}",
          iconSize: 0.3,
          iconAnchor: IconAnchor.BOTTOM,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ));
        
        print('✅ Добавлены специфичные маркеры: A=$showPointA, B=$showPointB');
      }
    } catch (e) {
      print('❌ Ошибка добавления специфичных маркеров: $e');
    }
  }

  // Загружаем маркеры точек А и Б
  Future<void> _loadPointMarkers(MapboxMap mapboxController) async {
    try {
      // Загружаем маркер точки А
      await _loadMarkerImage(mapboxController, 'point_a', 'assets/images/point_a.png');
      
      // Загружаем маркер точки Б
      await _loadMarkerImage(mapboxController, 'point_b', 'assets/images/point_b.png');
      
      print('✅ Маркеры точек А и Б успешно загружены');
    } catch (e) {
      print('❌ Ошибка при загрузке маркеров точек А и Б: $e');
      // Создаем простые маркеры вместо PNG
      await _createSimpleMarkers(mapboxController);
    }
  }

  // Вспомогательный метод для загрузки изображения маркера
  Future<void> _loadMarkerImage(MapboxMap mapboxController, String name, String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      
      // Устанавливаем разумные размеры
      const int width = 40;
      const int height = 40;
      
      // Преобразуем изображение
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width,
        targetHeight: height,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? resizedData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (resizedData == null) {
        throw Exception('Не удалось преобразовать изображение маркера $name');
      }
      
      await mapboxController.style.addStyleImage(
        name,
        1.0,
        MbxImage(
          width: width,
          height: height,
          data: resizedData.buffer.asUint8List(),
        ),
        false,
        [],
        [],
        null,
      );
      
      print('✅ Маркер $name успешно загружен');
    } catch (e) {
      print('❌ Ошибка загрузки маркера $name: $e');
      throw e;
    }
  }

  // Создание простых маркеров на случай ошибки загрузки PNG
  Future<void> _createSimpleMarkers(MapboxMap mapboxController) async {
    try {
      // Создаем маркер точки А (красный круг)
      await _createSimpleMarker(mapboxController, 'point_a', Colors.red);
      
      // Создаем маркер точки Б (зеленый круг)
      await _createSimpleMarker(mapboxController, 'point_b', Colors.green);
      
      print('✅ Простые маркеры созданы успешно');
    } catch (e) {
      print('❌ Ошибка создания простых маркеров: $e');
    }
  }

  // Создание простого маркера заданного цвета
  Future<void> _createSimpleMarker(MapboxMap mapboxController, String name, Color color) async {
    const size = 40;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Рисуем круг с тенью
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size / 2, size / 2), 18, shadowPaint);
    
    // Рисуем сам маркер
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), 16, markerPaint);
    
    // Белая обводка
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size / 2, size / 2), 16, borderPaint);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      await mapboxController.style.addStyleImage(
        name,
        1.0,
        MbxImage(
          width: size,
          height: size,
          data: byteData.buffer.asUint8List(),
        ),
        false,
        [],
        [],
        null,
      );
      print('✅ Простой маркер $name создан');
    }
  }

  // Обновляет позицию маркера водителя с анимацией
  Future<void> _updateDriverMarkerWithAnimation(MapboxMap mapboxController, geotypes.Position driverPosition) async {
    try {
      // Сначала проверяем, существует ли уже слой с маркером водителя
      bool driverMarkerExists = await mapboxController.style.styleLayerExists('driver-marker-layer');
      
      if (driverMarkerExists) {
        // Маркер уже существует - обновляем его позицию с анимацией
        print('🚗 Обновление позиции маркера водителя с анимацией');
        
        // Проверяем существование источника
        bool sourceExists = await mapboxController.style.styleSourceExists('driver-marker-source');
        
        if (sourceExists) {
          // Создаем новый GeoJSON с обновленной позицией
          final updatedFeatureJson = {
            "type": "Feature",
            "id": "driver-marker",
            "properties": {
              "icon": "professional_car_icon"
            },
            "geometry": {
              "type": "Point",
              "coordinates": [driverPosition.lng, driverPosition.lat]
            }
          };
          
          // Удаляем старый источник и создаем новый с тем же ID
          await mapboxController.style.removeStyleSource('driver-marker-source');
          
          final updatedSource = GeoJsonSource(
            id: 'driver-marker-source',
            data: json.encode(updatedFeatureJson),
          );
          
          await mapboxController.style.addSource(updatedSource);
          print('✅ Позиция маркера водителя обновлена плавно');
        } else {
          // Если источник не найден, удаляем и пересоздаем маркер
          print('⚠️ Источник маркера водителя не найден, пересоздаем...');
          await _clearDriverMarker(mapboxController);
          await _addDriverMarkerOnMap(mapboxController, driverPosition);
        }
      } else {
        // Маркер еще не существует - создаем его впервые
        print('🆕 Создание нового маркера водителя');
        await _addDriverMarkerOnMap(mapboxController, driverPosition);
      }
    } catch (e) {
      print('❌ Ошибка при обновлении маркера водителя: $e');
      // В случае ошибки пробуем пересоздать маркер полностью
      try {
        await _clearDriverMarker(mapboxController);
        await _addDriverMarkerOnMap(mapboxController, driverPosition);
      } catch (retryError) {
        print('❌❌ Ошибка при повторной попытке создания маркера: $retryError');
      }
    }
  }
}
