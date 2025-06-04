import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
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
import '../../models/active_client_request/active_client_request_model.dart';
import '../../domains/food/food_category_domain.dart';
import '../../domains/food/food_domain.dart';
import '../widgets/primary_bottom_sheet.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:elementary_helper/elementary_helper.dart';
import './widgets/tenant_home_create_food_view.dart';
import './widgets/tenant_home_create_order_view.dart';
import './widgets/tenant_home_tab_view.dart';
import 'tenant_home_wm.dart';
import 'widgets/active_client_order_bottom_sheet.dart';

class TenantHomeScreen extends ElementaryWidget<ITenantHomeWM> {
  TenantHomeScreen({
    Key? key,
  }) : super(
          (context) => defaultTenantHomeWMFactory(context),
        );

  @override
  Widget build(ITenantHomeWM wm) {
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
          return Scaffold(
            resizeToAvoidBottomInset: false,
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
                              userLocation?.lng ?? 76.893156,
                              userLocation?.lat ?? 43.239337,
                            )),
                            zoom: 18.0,
                          ),
                          onMapCreated: (mapboxController) async {
                            // Передаем контроллер в WidgetModel для управления камерой
                            wm.setMapboxController(mapboxController);
                            
                            // Загружаем только маркер для конечных точек маршрута
                            // (point_b остается для отметки конечной точки)
                            _addImageFromAsset(mapboxController, 'point_b', 'assets/images/point_b.png');
                            _addImageFromAsset(mapboxController, 'point_a', 'assets/images/point_a.png');
                            
                            // Включаем встроенное отображение местоположения пользователя
                            try {
                              await mapboxController.location.updateSettings(
                                LocationComponentSettings(
                                  enabled: true,
                                  pulsingEnabled: false,
                                  showAccuracyRing: false,
                                  puckBearingEnabled: false,
                                ),
                              );
                            } catch (e) {
                              print('Ошибка при включении отображения местоположения: $e');
                            }
                            
                            // Настраиваем русскую локализацию
                            _setupMapLocalization(mapboxController);
                          },
                        ),
                      ),
                      Positioned(
                        top: 32,
                        right: 32,
                        child: InkWell(
                          onTap: wm.getMyLocation,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(Icons.location_searching),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  top: 0,
                  child: TripleSourceBuilder(
                      firstSource: wm.currentTab,
                      secondSource: wm.activeOrder,
                      thirdSource: wm.me,
                      builder: (
                        context,
                        int? currentTab,
                        ActiveClientRequestModel? activeOrder,
                        UserDomain? me,
                      ) {
                        return TripleSourceBuilder(
                            firstSource: wm.draggableMaxChildSize,
                            secondSource: wm.locationPermission,
                            thirdSource: wm.showFood,
                            builder: (
                              context,
                              double? draggableMaxChildSize,
                              LocationPermission? locationPermission,
                              bool? showFood,
                            ) {
                              return DraggableScrollableSheet(
                                initialChildSize: 0.3,
                                controller: wm.draggableScrollableController,
                                minChildSize: 0.3,
                                maxChildSize: 1,
                                snap: false,
                                expand: false,
                                builder: (
                                  context,
                                  scrollController,
                                ) {
                                  return Container(
                                    color: Colors.white,
                                    child: SingleChildScrollView(
                                      controller: scrollController,
                                      child: TripleSourceBuilder(
                                        firstSource: wm.currentTab,
                                        secondSource: wm.activeOrder,
                                        thirdSource: wm.me,
                                        builder: (
                                          context,
                                          int? currentTab,
                                          ActiveClientRequestModel? activeOrder,
                                          UserDomain? me,
                                        ) {
                                          if (![
                                            LocationPermission.always,
                                            LocationPermission.whileInUse
                                          ].contains(locationPermission)) {
                                            return Container(
                                              color: Colors.white,
                                              child: PopScope(
                                                canPop: false,
                                                child: PrimaryBottomSheet(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    vertical: 8,
                                                    horizontal: 16,
                                                  ),
                                                  child: SizedBox(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Center(
                                                          child: Container(
                                                            width: 38,
                                                            height: 4,
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  greyscale30,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          1.4),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 24,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: Text(
                                                            'Для заказа пожалуйста поделитесь геолокацией',
                                                            style:
                                                                text400Size24Greyscale60,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 24,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: PrimaryButton
                                                              .primary(
                                                            onPressed: () => wm
                                                                .determineLocationPermission(
                                                              force: true,
                                                            ),
                                                            text:
                                                                'Включить геолокацию',
                                                            textStyle:
                                                                text400Size16White,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          if (activeOrder != null) {
                                            return Container(
                                              color: Colors.white,
                                              child:
                                                  ActiveClientOrderBottomSheet(
                                                me: me!,
                                                activeOrder: activeOrder,
                                                activeOrderListener:
                                                    wm.activeOrder,
                                                onCancel:
                                                    wm.cancelActiveClientOrder,
                                              ),
                                            );
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: greyscale30,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            1.40),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                TabBar(
                                                  controller: wm.tabController,
                                                  isScrollable: true,
                                                  padding:
                                                      EdgeInsets.only(left: 16),
                                                  tabAlignment:
                                                      TabAlignment.start,
                                                  dividerColor:
                                                      Colors.transparent,
                                                  indicatorColor:
                                                      Colors.transparent,
                                                  enableFeedback: false,
                                                  labelPadding:
                                                      EdgeInsets.only(right: 8),
                                                  tabs: [
                                                    ...[
                                                      DriverType.TAXI,
                                                      /* Временно скрываем эти вкладки
                                                      if (showFood == true)
                                                        "FOOD",
                                                      DriverType.DELIVERY,
                                                      DriverType.CARGO,
                                                      */
                                                      DriverType.INTERCITY_TAXI,
                                                    ].asMap().entries.map(
                                                          (e) => InkWell(
                                                            onTap: () => wm
                                                                .tabIndexChanged(
                                                                    e.key),
                                                            child:
                                                                TenantHomeTabView(
                                                              isActive:
                                                                  currentTab ==
                                                                      e.key,
                                                              label: e.value
                                                                      is DriverType
                                                                  ? (e.value
                                                                          as DriverType)
                                                                      .value!.tr()
                                                                  : 'Eда'.tr(),
                                                              asset: e.value
                                                                      is DriverType
                                                                  ? (e.value
                                                                          as DriverType)
                                                                      .asset!
                                                                  : 'assets/icons/food.svg',
                                                            ),
                                                          ),
                                                        )
                                                  ],
                                                ),
                                                const SizedBox(height: 24),
                                
                                // Показываем соответствующий компонент в зависимости от выбранной вкладки
                                Builder(
                                  builder: (context) {
                                    // Видимые вкладки - только такси и межгород
                                    if (currentTab == 0) {
                                      // Такси
                                      return Navigator(
                                        onGenerateRoute: (settings) {
                                          return MaterialPageRoute(
                                            builder: (context) => TenantHomeCreateOrderView(
                                              scrollController: scrollController,
                                              onSubmit: (form) => wm.onSubmit(form, DriverType.TAXI),
                                            ),
                                            settings: settings,
                                          );
                                        },
                                        onPopPage: (route, result) {
                                          if (result != null && result is Map && result['shouldShowRoute'] == true) {
                                            // Обрабатываем результат с маршрутом
                                            final fromPosition = result['fromPosition'] as geotypes.Position?;
                                            final toPosition = result['toPosition'] as geotypes.Position?;
                                            
                                            print('Получены данные для отображения маршрута:');
                                            print('From: ${fromPosition?.lat},${fromPosition?.lng}');
                                            print('To: ${toPosition?.lat},${toPosition?.lng}');
                                            print('From address: ${result['fromAddress']}');
                                            print('To address: ${result['toAddress']}');
                                            
                                            if (fromPosition != null && toPosition != null && wm.mapboxMapController != null) {
                                              print('Отображаем маршрут на карте');
                                              // Используем Future.delayed для обеспечения времени на отрисовку экрана
                                              Future.delayed(Duration(milliseconds: 300), () {
                                                displayRouteOnMainMap(wm.mapboxMapController!, fromPosition, toPosition);
                                              });
                                            } else {
                                              print('Не удается отобразить маршрут: fromPosition=${fromPosition != null}, toPosition=${toPosition != null}, mapController=${wm.mapboxMapController != null}');
                                            }
                                          }
                                          return route.didPop(result);
                                        },
                                      );
                                    } else {
                                      // Межгород
                                      return TenantHomeCreateOrderView(
                                        isIntercity: true,
                                        scrollController: scrollController,
                                        onSubmit: (form) => wm.onSubmit(form, DriverType.INTERCITY_TAXI),
                                      );
                                    }
                                  },
                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            });
                      }),
                )
              ],
            ),
          );
        });
  }

  // Методы для работы с картой
  Future<void> _addImageFromAsset(MapboxMap mapboxController, String name, String assetName) async {
    try {
      final ByteData bytes = await rootBundle.load(assetName);
      final Uint8List list = bytes.buffer.asUint8List();
      final image = await decodeImageFromList(list);
      
      await mapboxController.style.addStyleImage(
        name,
        1.0, // scale
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
    } catch (e) {
      print('Ошибка при добавлении изображения: $e');
    }
  }
  
  Future<void> _setupMapLocalization(MapboxMap mapboxController) async {
    try {
      // Настраиваем русскую локализацию для карты
      await mapboxController.style.setStyleImportConfigProperty(
        "basemap",
        "language",
        "ru" // Русский язык
      );
    } catch (e) {
      print('Error setting map localization: $e');
    }
  }

  // Метод для отображения маршрута между точками на главной карте
  Future<void> displayRouteOnMainMap(MapboxMap mapboxController, geotypes.Position fromPosition, geotypes.Position toPosition) async {
    try {
      print('Отображение маршрута на главной карте...');
      print('Координаты from: ${fromPosition.lat}, ${fromPosition.lng}');
      print('Координаты to: ${toPosition.lat}, ${toPosition.lng}');
      
      // Получаем маршрут через API Mapbox
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
      
      // Удаляем существующие слои маршрута и маркеров, если они есть
      try {
        for (final layerId in ['main-route-layer', 'main-markers-layer']) {
          if (await mapboxController.style.styleLayerExists(layerId)) {
            await mapboxController.style.removeStyleLayer(layerId);
            print('Удален слой $layerId');
          }
        }
        
        for (final sourceId in ['main-route-source', 'main-markers-source']) {
          if (await mapboxController.style.styleSourceExists(sourceId)) {
            await mapboxController.style.removeStyleSource(sourceId);
            print('Удален источник $sourceId');
          }
        }
      } catch (e) {
        print('Ошибка при удалении существующих слоев: $e');
      }
      
      // Создаем GeoJSON LineString из геометрии маршрута
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
      
      // Преобразуем в JSON
      final jsonData = json.encode({
        "type": "FeatureCollection",
        "features": [lineString]
      });
      
      // Добавляем источник данных для маршрута
      await mapboxController.style.addSource(GeoJsonSource(
        id: 'main-route-source',
        data: jsonData,
      ));
      print('Добавлен источник данных для маршрута');
      
      // Добавляем слой линии для маршрута
      await mapboxController.style.addLayer(LineLayer(
        id: 'main-route-layer',
        sourceId: 'main-route-source',
        lineColor: Colors.blue.value,
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ));
      print('Добавлен слой линии для маршрута');
      
      // Добавляем маркеры начальной и конечной точек
      try {
        // Добавляем геоJSON для маркеров
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
        
        // Добавляем источник данных для маркеров
        await mapboxController.style.addSource(GeoJsonSource(
          id: 'main-markers-source',
          data: json.encode(markersJson),
        ));
        print('Добавлен источник данных для маркеров');
        
        // Добавляем слой символов для маркеров
        await mapboxController.style.addLayer(SymbolLayer(
          id: 'main-markers-layer',
          sourceId: 'main-markers-source',
          iconImage: "{icon}",  // Используем шаблонную строку для получения свойства icon
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM, // Важно: закрепляем маркер внизу изображения
        ));
        print('Добавлен слой символов для маркеров');
      } catch (e) {
        print('Ошибка при добавлении маркеров: $e');
      }
      
      // Настраиваем камеру, чтобы отобразить весь маршрут
      final bounds = directions['routes'][0]['bounds'];
      if (bounds != null) {
        final southwest = bounds[0];
        final northeast = bounds[1];
        
        final camera = await mapboxController.cameraForCoordinateBounds(
          CoordinateBounds(
            southwest: Point(coordinates: geotypes.Position(southwest[0], southwest[1])),
            northeast: Point(coordinates: geotypes.Position(northeast[0], northeast[1])),
            infiniteBounds: false
          ),
          MbxEdgeInsets(top: 100, left: 100, bottom: 100, right: 100),
          null, // bearing
          null, // pitch
          null, // maxZoom
          null, // minZoom
        );
        
        await mapboxController.flyTo(
          camera,
          MapAnimationOptions(duration: 1000),
        );
        print('Камера карты обновлена для отображения всего маршрута');
      }
      
      // Блокируем взаимодействие с картой
      try {
        await mapboxController.gestures.updateSettings(
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
      
      print('Маршрут успешно отображен на главной карте');
    } catch (e) {
      print('Ошибка при отображении маршрута на главной карте: $e');
    }
  }
}
