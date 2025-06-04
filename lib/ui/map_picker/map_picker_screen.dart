import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';

import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/interactors/location_interactor.dart';
import 'package:aktau_go/models/open_street_map/open_street_map_place_model.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:collection/collection.dart';
import 'package:easy_autocomplete/easy_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:seafarer/seafarer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geotypes/geotypes.dart' as geotypes;

import '../../router/router.dart';
import '../../utils/text_editing_controller.dart';

class MapAddressPickerScreenArgs extends BaseArguments {
  final geotypes.Position? position;
  final String? placeName;
  final geotypes.Position? fromPosition;

  final Function(
    geotypes.Position position,
    String placeName,
  ) onSubmit;

  final Function(
    String prediction,
  )? onSubmit2;

  MapAddressPickerScreenArgs({
    this.position,
    this.placeName,
    this.fromPosition,
    required this.onSubmit,
    this.onSubmit2,
  });
}

class MapAddressPickerScreen extends StatefulWidget {
  final MapAddressPickerScreenArgs args;

  const MapAddressPickerScreen({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  MapboxMap? mapboxMapController;
  geotypes.Position? userLocation;
  geotypes.Position? currentPosition;
  Timer? timer;
  String _addressName = '';
  bool _showDeleteButton = false;
  String? _selectedGooglePredictions;
  List<OpenStreetMapPlaceModel> suggestions = [];
  bool _locationComponentEnabled = false;
  bool _isMapReady = false;
  bool _isAddressLoading = false;
  double _defaultZoom = 19.0;
  Map<String, dynamic> _route = {};
  bool _hasRoute = false;

  late TextEditingController _textFieldController;

  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController();
    
    if (widget.args.placeName != null) {
      _textFieldController.text = widget.args.placeName!;
      _addressName = widget.args.placeName!;
      _showDeleteButton = true;
    }
    
    initializeMap();
  }

  @override
  void dispose() {
    timer?.cancel();
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<geoLocator.Position?>(
          future: inject<LocationInteractor>().getCurrentLocation(),
          builder: (context, snapshot) {
            userLocation = snapshot.data != null 
                ? geotypes.Position(snapshot.data!.longitude, snapshot.data!.latitude)
                : null;

            currentPosition = widget.args.position ??
                userLocation ??
                geotypes.Position(76.893156, 43.239337);

            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: MapWidget(
                      key: ValueKey("mapWidget"),
                      cameraOptions: CameraOptions(
                        center: Point(coordinates: currentPosition!),
                        zoom: _defaultZoom,
                      ),
                      onMapCreated: (mapboxController) async {
                        setState(() {
                          mapboxMapController = mapboxController;
                        });
                        
                        try {
                          // Включаем отображение текущего местоположения пользователя
                          await mapboxMapController?.location.updateSettings(
                            LocationComponentSettings(
                              enabled: true,
                              pulsingEnabled: false,
                              showAccuracyRing: false,
                              puckBearingEnabled: false,
                            ),
                          );
                          setState(() {
                            _locationComponentEnabled = true;
                            _isMapReady = true;
                          });
                          
                          // Если есть начальная позиция, пробуем нарисовать маршрут
                          if (widget.args.fromPosition != null && currentPosition != null) {
                            _drawRouteBetweenPoints();
                          }
                          
                          // Запускаем таймер для периодического обновления адреса
                          _startMapInteractionListener();
                        } catch (e) {
                          print('Error enabling location component: $e');
                        }
                      },
                    ),
                  ),
                ),
                // Если компонент местоположения не работает, добавляем кастомный маркер в центре экрана
                if (!_locationComponentEnabled)
                  Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                // Крестик в центре карты для выбора точки
                Center(
                  child: GestureDetector(
                    onPanEnd: (_) => _fetchAddressFromCenter(),
                    child: Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.center_focus_weak_sharp,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                // Кнопка возврата
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // Поле ввода адреса
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 70,
                  right: 16,
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: EasyAutocomplete(
                            controller: _textFieldController,
                            asyncSuggestions: getSuggestions,
                            decoration: InputDecoration(
                              hintText: 'Введите адрес',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: _showDeleteButton
                                  ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        _textFieldController.clear();
                                        setState(() {
                                          _showDeleteButton = false;
                                          _addressName = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: onPlaceSearchChanged,
                            suggestionBuilder: (String json) {
                              return ListTile(
                                title: Text(json),
                              );
                            },
                            onSubmitted: (String json) async {
                              try {
                                // Проверяем, что список предложений не пустой
                                if (suggestions.isEmpty) {
                                  print('Список предложений пуст');
                                  return;
                                }
                                
                                // Находим элемент в списке suggestions, проверяя на null
                                OpenStreetMapPlaceModel? feature = suggestions.firstWhereOrNull(
                                  (element) => element.name == json
                                );
                                
                                if (feature == null) {
                                  print('Не найдено соответствующее предложение для: $json');
                                  return;
                                }

                                final newPosition = geotypes.Position(
                                  feature.lon?.toDouble() ?? 0, 
                                  feature.lat?.toDouble() ?? 0
                                );
                                
                                if (mapboxMapController != null) {
                                  await mapboxMapController?.flyTo(
                                    CameraOptions(
                                      center: Point(coordinates: newPosition),
                                      zoom: 16,
                                    ),
                                    MapAnimationOptions(duration: 1000),
                                  );
                                }
                                
                                setState(() {
                                  _addressName = feature.name ?? '';
                                  _selectedGooglePredictions = feature.name;
                                  currentPosition = newPosition;
                                });
                              } catch (e) {
                                print('Ошибка при обработке выбора адреса: $e');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Кнопка "Мое местоположение"
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.my_location),
                      onPressed: _goToMyLocation,
                    ),
                  ),
                ),
                // Панель с адресом и кнопкой подтверждения
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isAddressLoading)
                          Container(
                            height: 20,
                            width: 20,
                            margin: EdgeInsets.only(bottom: 8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        Container(
                          width: double.infinity,
                          child: Text(
                            _addressName.isNotEmpty ? _addressName : 'Выберите точку на карте',
                            style: text400Size16Black,
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton.primary(
                            onPressed: _addressName.isNotEmpty 
                                ? _onConfirmPressed
                                : null,
                            text: 'Подтвердить',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }

  // Функция для перехода к текущему местоположению пользователя
  Future<void> _goToMyLocation() async {
    if (userLocation != null && mapboxMapController != null) {
      await mapboxMapController!.flyTo(
        CameraOptions(
          center: Point(coordinates: userLocation!),
          zoom: 19.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } else {
      // Запрашиваем местоположение если оно не определено
      final location = await inject<LocationInteractor>().getCurrentLocation();
      if (location != null && mapboxMapController != null) {
        userLocation = geotypes.Position(location.longitude, location.latitude);
        await mapboxMapController!.flyTo(
          CameraOptions(
            center: Point(coordinates: userLocation!),
            zoom: 19.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      } else {
        // Показываем сообщение если не удалось получить местоположение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось получить текущее местоположение'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Запускаем таймер для периодического обновления адреса при взаимодействии с картой
  void _startMapInteractionListener() {
    // Запускаем таймер, который будет обновлять адрес при остановке взаимодействия
    timer = Timer.periodic(Duration(milliseconds: 2000), (_) {
      if (_isMapReady && mapboxMapController != null) {
        _fetchAddressFromCenter();
      }
    });
  }
  
  // Получение адреса по центру карты
  Future<void> _fetchAddressFromCenter() async {
    if (mapboxMapController == null) return;
    
    try {
      final center = await mapboxMapController!.getCameraState();
      final centerPoint = center.center;
      if (centerPoint != null) {
        final centerPos = centerPoint.coordinates as geotypes.Position;
        _updateAddressName(centerPos.lat.toDouble(), centerPos.lng.toDouble());
      }
    } catch (e) {
      print('Error fetching address from center: $e');
    }
  }

  Future<List<String>> getSuggestions(String query) async {
    try {
      final response = await inject<RestClient>().getPlacesQuery(
        query: query,
        latitude: inject<SharedPreferences>().getDouble('latitude') ?? 0,
        longitude: inject<SharedPreferences>().getDouble('longitude') ?? 0,
      );

      suggestions = response ?? [];
      return response?.map((e) => e.name ?? '').toList() ?? [];
    } on Exception catch (e) {}
    return [];
  }

  onPlaceSearchChanged(String searchValue) {
    setState(() {
      _showDeleteButton = _textFieldController.text.isNotEmpty;
    });
  }

  Future<void> initializeMap() async {
    await inject<LocationInteractor>().requestLocation();
    final location = await inject<LocationInteractor>().getCurrentLocation();
    if (location != null) {
      userLocation = geotypes.Position(location.longitude, location.latitude);
      await inject<SharedPreferences>().setDouble('latitude', location.latitude);
      await inject<SharedPreferences>().setDouble('longitude', location.longitude);
      
      if (widget.args.position == null) {
        currentPosition = userLocation;
        if (mapboxMapController != null) {
          await mapboxMapController!.flyTo(
            CameraOptions(
              center: Point(coordinates: currentPosition!),
              zoom: 19.0,
            ),
            MapAnimationOptions(duration: 1000),
          );
        }
      }
      
      _updateAddressName(currentPosition!.lat.toDouble(), currentPosition!.lng.toDouble());
    }
  }

  Future<void> _updateAddressName(double lat, double lng) async {
    // Обновляем текущую позицию
    setState(() {
      currentPosition = geotypes.Position(lng, lat);
      _isAddressLoading = true;
    });

    try {
      final response = await inject<RestClient>().getPlaceDetail(
        latitude: lat,
        longitude: lng,
      );

      if (response != null && response.isNotEmpty) {
        setState(() {
          _addressName = response;
          if (_textFieldController.text.isEmpty || _textFieldController.text != _addressName) {
            _textFieldController.text = _addressName;
          }
          _isAddressLoading = false;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _isAddressLoading = false;
      });
    }
  }

  Future<void> _drawRouteBetweenPoints() async {
    // Проверяем, есть ли начальная и конечная точки для построения маршрута
    if (widget.args.fromPosition != null && currentPosition != null) {
      try {
        print('Построение маршрута между точками...');
        print('From: ${widget.args.fromPosition!.lat}, ${widget.args.fromPosition!.lng}');
        print('To: ${currentPosition!.lat}, ${currentPosition!.lng}');
        
        final fromLat = widget.args.fromPosition!.lat.toDouble();
        final fromLng = widget.args.fromPosition!.lng.toDouble();
        final toLat = currentPosition!.lat.toDouble();
        final toLng = currentPosition!.lng.toDouble();
        
        // Запрашиваем маршрут через API Mapbox
        print('Вызываем API для построения маршрута...');
        final directions = await inject<MapboxApi>().getDirections(
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );
        
        print('Получен ответ от API: ${directions != null}');
        
        setState(() {
          _route = directions;
          _hasRoute = true;
        });
        
        // Добавляем маршрут на карту
        if (mapboxMapController != null && _route.isNotEmpty) {
          print('Добавляем маршрут на карту...');
          await _addRouteToMap();
          await _addRouteMarkersToMap();
          print('Маршрут успешно добавлен на карту');
        } else {
          print('Не удалось добавить маршрут: контроллер=${mapboxMapController != null}, route=${_route.isNotEmpty}');
        }
      } catch (e) {
        print('Ошибка при построении маршрута: $e');
      }
    } else {
      print('Невозможно построить маршрут: fromPosition=${widget.args.fromPosition != null}, currentPosition=${currentPosition != null}');
    }
  }
  
  Future<void> _addRouteToMap() async {
    if (mapboxMapController == null || _route.isEmpty) {
      print('Невозможно добавить маршрут: controller=${mapboxMapController != null}, route=${_route.isNotEmpty}');
      return;
    }

    try {
      print('Добавление маршрута на карту...');
      // Проверяем наличие маршрутов в ответе API
      if (!_route.containsKey('routes') || _route['routes'] == null || _route['routes'].isEmpty) {
        print('В ответе API нет маршрутов: ${_route.keys}');
        return;
      }

      // Проверяем наличие геометрии в первом маршруте
      if (!_route['routes'][0].containsKey('geometry') || _route['routes'][0]['geometry'] == null) {
        print('В маршруте нет геометрии: ${_route['routes'][0].keys}');
        return;
      }

      print('Геометрия маршрута найдена');

      // Удаляем существующие слои маршрута, если они есть
      try {
        if (await mapboxMapController!.style.styleLayerExists('route-layer')) {
          await mapboxMapController!.style.removeStyleLayer('route-layer');
          print('Существующий слой маршрута удален');
        }
        if (await mapboxMapController!.style.styleSourceExists('route-source')) {
          await mapboxMapController!.style.removeStyleSource('route-source');
          print('Существующий источник маршрута удален');
        }
      } catch (e) {
        print('Ошибка при удалении существующих слоев: $e');
      }

      // Создаем GeoJSON LineString из геометрии маршрута
      final routeGeometry = _route['routes'][0]['geometry'];
      print('Тип геометрии: ${routeGeometry.runtimeType}');
      
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
      
      print('Подготовлен JSON для маршрута');

      // Добавляем источник данных для маршрута
      await mapboxMapController!.style.addSource(GeoJsonSource(
        id: 'route-source',
        data: jsonData,
      ));
      
      print('Источник маршрута добавлен');

      // Добавляем слой линии для маршрута
      await mapboxMapController!.style.addLayer(LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: Colors.blue.value,
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ));
      
      print('Слой маршрута добавлен успешно');
    } catch (e) {
      print('Ошибка при добавлении линии маршрута: $e');
      print('Структура ответа API: ${_route.keys}');
      if (_route.containsKey('routes') && _route['routes'] != null && _route['routes'].isNotEmpty) {
        print('Структура routes[0]: ${_route['routes'][0].keys}');
      }
    }
  }

  Future<void> _addRouteMarkersToMap() async {
    if (mapboxMapController == null) return;

    try {
      // Удаляем существующие слои маркеров, если они есть
      if (await mapboxMapController!.style.styleLayerExists('markers-layer')) {
        await mapboxMapController!.style.removeStyleLayer('markers-layer');
      }
      if (await mapboxMapController!.style.styleSourceExists('markers-source')) {
        await mapboxMapController!.style.removeStyleSource('markers-source');
      }

      // Добавляем маркеры начальной и конечной точек
      await addImageFromAsset('point_a', 'assets/images/point_a.png');
      await addImageFromAsset('point_b', 'assets/images/point_b.png');
      
      // Код для добавления маркеров начальной и конечной точек
      // Будет реализован при необходимости
    } catch (e) {
      print('Ошибка при добавлении маркеров: $e');
    }
  }
  
  Future<void> addImageFromAsset(String name, String assetName) async {
    try {
      final ByteData bytes = await rootBundle.load(assetName);
      final Uint8List list = bytes.buffer.asUint8List();
      final image = await decodeImageFromList(list);
      
      // Используем правильный метод для добавления изображения
      await mapboxMapController!.style.addStyleImage(
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

  @override
  void didUpdateWidget(covariant MapAddressPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Обновляем маршрут при изменении параметров виджета
    if (widget.args.fromPosition != null && currentPosition != null && 
        mapboxMapController != null && _isMapReady) {
      _drawRouteBetweenPoints();
    }
  }
  
  // Обработка нажатия на кнопку "Подтвердить"
  void _onConfirmPressed() {
    if (currentPosition != null) {
      widget.args.onSubmit(currentPosition!, _addressName);
      Navigator.of(context).pop({
        'position': currentPosition,
        'placeName': _addressName
      });
    }
  }
} 