import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math';

import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/interactors/common/mapbox_api/mapbox_api.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/interactors/location_interactor.dart';
import 'package:aktau_go/models/open_street_map/open_street_map_place_model.dart';
import 'package:aktau_go/ui/map_picker/dotted_line_painter.dart';
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

  // Regular constructor
  MapAddressPickerScreenArgs({
    this.position,
    this.placeName,
    this.fromPosition,
    required this.onSubmit,
  });
  
  // Default constructor with empty callback
  factory MapAddressPickerScreenArgs.empty() {
    return MapAddressPickerScreenArgs(
      placeName: '',
      onSubmit: (position, placeName) {
        print('Warning: Using empty MapAddressPickerScreenArgs callback');
      },
    );
  }
  
  @override
  String toString() {
    return 'MapAddressPickerScreenArgs{position: $position, placeName: $placeName, fromPosition: $fromPosition}';
  }
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
  Timer? _debounceTimer;
  String _addressName = '';
  bool _showDeleteButton = false;
  String? _selectedGooglePredictions;
  List<OpenStreetMapPlaceModel> suggestions = [];
  bool _locationComponentEnabled = false;
  bool _isMapReady = false;
  bool _isAddressLoading = false;
  double _defaultZoom = 16.0;
  Map<String, dynamic> _route = {};
  bool _hasRoute = false;
  bool _isRouteLoading = false;
  bool _isDragging = false;
  bool _isRouteNeedsUpdate = false;

  // Track last fetched position to avoid unnecessary updates
  geotypes.Position? _lastFetchedPosition;

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
    
    // Start a periodic timer to check map position changes
    _startPeriodicPositionCheck();
    
    // First initialize the map - use a flag to defer address lookups until map is ready
    initializeMap();
    
    // Check if this is destination selection with fromPosition available
    if (widget.args.fromPosition != null) {
      print('Destination selection mode detected with fromPosition: ${widget.args.fromPosition!.lat}, ${widget.args.fromPosition!.lng}');
      _isRouteNeedsUpdate = true;
      
      // Schedule drawing the route after the map is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use a delayed future to ensure the map is fully initialized
        Future.delayed(Duration(milliseconds: 1500), () {
          if (_isMapReady && currentPosition != null && mounted) {
            print('Map is ready, drawing route between points...');
            _drawRouteBetweenPoints();
          } else {
            print('Cannot draw route yet: mapReady=$_isMapReady, currentPosition=$currentPosition');
            // Set a flag to try again when the map becomes ready
            _isRouteNeedsUpdate = true;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _debounceTimer?.cancel();
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
            // Store user location separately from marker position
            userLocation = snapshot.data != null 
                ? geotypes.Position(snapshot.data!.longitude, snapshot.data!.latitude)
                : null;

            // Initialize marker position if not already set
            if (currentPosition == null) {
              // Приоритеты для начальной позиции:
              // 1. Используем ранее выбранную точку (widget.args.position), если она передана
              // 2. Используем текущее местоположение пользователя (userLocation)
              // 3. Только если ничего из этого недоступно, используем координаты по умолчанию
              currentPosition = widget.args.position ?? 
                  userLocation ?? 
                  geotypes.Position(76.893156, 43.239337);
              
              print('Setting initial marker position: ${currentPosition!.lat}, ${currentPosition!.lng}');
              
              // Если у нас уже есть текст для placeName, используем его
              if (widget.args.placeName != null && widget.args.placeName!.isNotEmpty) {
                _addressName = widget.args.placeName!;
                _textFieldController.text = widget.args.placeName!;
                _showDeleteButton = true;
              } else if (currentPosition != null) {
                // Если у нас есть позиция, но нет адреса, запросим его
                // Но делаем это через setState, чтобы точно сработало после построения виджета
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _isMapReady) {
                    _fetchAddress(currentPosition!);
                  }
                });
              }
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    onPointerUp: (_) {
                      // When user lifts finger from screen, update address and route
                      print('Pointer up detected, checking map position');
                      _handleMapMovementStopped();
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: MapWidget(
                        key: ValueKey("mapWidget"),
                        cameraOptions: CameraOptions(
                          center: Point(coordinates: currentPosition!),
                          zoom: _defaultZoom,
                        ),
                        onMapCreated: onMapCreated,
                      ),
                    ),
                  ),
                ),
                
                // Center marker - ALWAYS VISIBLE regardless of locationComponentEnabled
                  Center(
                    child: _buildCenterMarker(),
                  ),
                
                // Route indication line - vertical dotted line between origin and destination
                if (widget.args.fromPosition != null && !_hasRoute)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 50,
                          width: 4,
                          child: _buildDottedLine(),
                        ),
                      ],
                    ),
                  ),
                
                // Loading indicator during route calculation
                if (_isRouteLoading)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Строим маршрут...',
                            style: text400Size16Black,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Back button with improved shadow
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.white,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Address search field with improved UI
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
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: EasyAutocomplete(
                            controller: _textFieldController,
                            asyncSuggestions: getSuggestions,
                            decoration: InputDecoration(
                              hintText: 'Введите адрес',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: primaryColor,
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
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.place,
                                    color: primaryColor,
                                  ),
                                  title: Text(
                                    json,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                ),
                              );
                            },
                            onSubmitted: (String json) async {
                              try {
                                print('Place selected from autocomplete: $json');
                                if (json.isEmpty || suggestions.isEmpty) {
                                  print('JSON is empty or no suggestions available');
                                  return;
                                }
                                
                                // Найти соответствующее местоположение в списке подсказок
                                OpenStreetMapPlaceModel? feature = suggestions.firstWhereOrNull(
                                  (element) => element.name == json
                                );
                                
                                if (feature == null) {
                                  print('Выбранное место не найдено в подсказках: $json');
                                  return;
                                }

                                // Проверяем, что координаты не нулевые
                                if (feature.lat == null || feature.lon == null) {
                                  print('Для выбранного места нет координат: $json');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Не удалось определить координаты для этого места'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                print('Selected location coordinates: lat=${feature.lat}, lon=${feature.lon}');
                                
                                // Создаем позицию с координатами места
                                final newPosition = geotypes.Position(
                                  feature.lon!.toDouble(), 
                                  feature.lat!.toDouble()
                                );
                                
                                if (mapboxMapController != null) {
                                  // Animate camera with bouncing effect for better UX
                                  print('Flying to selected location');
                                  await mapboxMapController?.flyTo(
                                    CameraOptions(
                                      center: Point(coordinates: newPosition),
                                      zoom: 16,
                                    ),
                                    MapAnimationOptions(duration: 1000),
                                  );
                                  
                                  // Обновляем UI и переменные
                                  setState(() {
                                    _addressName = feature.name ?? '';
                                    _selectedGooglePredictions = feature.name;
                                    currentPosition = newPosition;
                                    _lastFetchedPosition = newPosition; // Обновляем последнюю полученную позицию
                                    
                                    // Обновляем текстовое поле
                                    if (_addressName.isNotEmpty && _textFieldController.text != _addressName) {
                                      _textFieldController.text = _addressName;
                                      _showDeleteButton = true;
                                    }
                                  });
                                  
                                  print('Updated address to: $_addressName');
                                  
                                  // Show bounce animation for pin
                                  _showPinDropAnimation();
                                
                                  // Draw route if fromPosition is available
                                  if (widget.args.fromPosition != null) {
                                    print('fromPosition is available, updating route...');
                                    _isRouteNeedsUpdate = true;
                                    _drawRouteBetweenPoints();
                                  }
                                }
                              } catch (e) {
                                print('Ошибка при обработке выбора адреса: $e');
                                // Показываем сообщение об ошибке
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка при выборе адреса: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Location button with improved UI
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.white,
                        child: IconButton(
                          icon: Icon(Icons.my_location, color: primaryColor),
                          onPressed: _goToMyLocation,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom panel with address and confirmation button
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Route details section (shown only when route is available)
                        if (_hasRoute && widget.args.fromPosition != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.navigation, color: primaryColor),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Маршрут построен',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                              SizedBox(height: 16),
                            ],
                          ),
                          
                        // Loading indicator or address display
                        if (_isAddressLoading)
                          Container(
                            height: 20,
                            width: 20,
                            margin: EdgeInsets.only(bottom: 16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          ),
                          
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.place,
                              color: primaryColor,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _addressName.isNotEmpty ? _addressName : 'Выберите точку на карте',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
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
                
                // Origin-destination indicator (when route is active)
                if (widget.args.fromPosition != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 80,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.trip_origin,
                              color: Colors.green,
                              size: 14,
                            ),
                          ),
                          Container(
                            height: 25,
                            width: 2,
                            color: Colors.grey[300],
                          ),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.place,
                              color: primaryColor,
                              size: 14,
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

  // Dotted line widget for route visualization
  Widget _buildDottedLine() {
    return CustomPaint(
      painter: DottedLinePainter(),
    );
  }
  
  // Show animation when pin drops on map
  void _showPinDropAnimation() {
    if (!_locationComponentEnabled) {
      // Animation will be handled by AnimatedContainer in the widget tree
      setState(() {});
    }
  }

  // Location button handler
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
      // Request location if not available
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
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось получить текущее местоположение'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fetch address data for a specific position (the marker position)
  Future<void> _fetchAddress(geotypes.Position position) async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isAddressLoading = true;
      });
      
      print('Fetching address for position: ${position.lat}, ${position.lng}');
      
      final client = inject<RestClient>();
      final placeName = await client.getPlaceDetail(
        latitude: position.lat.toDouble(),
        longitude: position.lng.toDouble(),
      );
      
      if (!mounted) return;
      
      final addressText = placeName ?? "Адрес не найден";
      print('Address fetched: $addressText');
      
      // Force UI update with the new address
      setState(() {
        _addressName = addressText;
        _textFieldController.text = addressText;
        _isAddressLoading = false;
        _showDeleteButton = addressText != "Адрес не найден" && addressText.isNotEmpty;
        _lastFetchedPosition = position;
      });
      
      // Verify the text update took effect
      print('UI updated with address: $_addressName, text field: ${_textFieldController.text}');
    } catch (e) {
      if (!mounted) return;
      
      print('Error fetching address: $e');
      setState(() {
        _isAddressLoading = false;
        _addressName = "Ошибка получения адреса";
        _textFieldController.text = "Ошибка получения адреса";
      });
    }
  }

  void onMapCreated(MapboxMap mapboxController) async {
    setState(() {
      mapboxMapController = mapboxController;
    });
    
    try {
      // Add markers for route points - make them smaller
      await addImageFromAsset('point_a', 'assets/images/point_a.png', scale: 0.3);
      await addImageFromAsset('point_b', 'assets/images/point_b.png', scale: 0.3);
      
      // Enable location display
      await mapboxMapController?.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
          puckBearingEnabled: false,
        ),
      );
      setState(() {
        _locationComponentEnabled = true;
        _isMapReady = true;
      });
      
      print('Map is ready, locationComponentEnabled: $_locationComponentEnabled');
      
      // Important: fetch address for the CURRENT MARKER POSITION (not user location)
      _fetchAddress(currentPosition!);
      
      // Draw route if fromPosition is available
      if (widget.args.fromPosition != null && currentPosition != null) {
        print('fromPosition is available, drawing route...');
        // Add a small delay to ensure the map is fully loaded
        Future.delayed(Duration(milliseconds: 500), () {
          _drawRouteBetweenPoints();
        });
      }
    } catch (e) {
      print('Error in onMapCreated: $e');
    }
  }

  // Called when the user stops moving the map
  Future<void> _handleMapMovementStopped() async {
    if (!_isMapReady || mapboxMapController == null) return;
    
    try {
      print('Map movement stopped, updating map state');
      
      // Get current map center position
      final cameraState = await mapboxMapController!.getCameraState();
      final newPosition = geotypes.Position(
        cameraState.center.coordinates.lng,
        cameraState.center.coordinates.lat
      );
      
      // Update marker position
      setState(() {
        currentPosition = newPosition;
        _isDragging = false;
      });
      
      // Immediately fetch address for the new position
      await _fetchAddress(newPosition);
      
      // Update route if needed
      if (widget.args.fromPosition != null) {
        print('Redrawing route after map movement stopped');
        await _drawRouteBetweenPoints();
      }
    } catch (e) {
      print('Error handling map movement: $e');
    }
  }
  
  // Draw route between two points with improved visualization and error handling
  Future<void> _drawRouteBetweenPoints() async {
    if (widget.args.fromPosition != null && currentPosition != null) {
      try {
        // Show loading indicator
        setState(() {
          _isRouteLoading = true;
          _hasRoute = false;
        });
        
        print('Drawing route in map picker...');
        print('From position: ${widget.args.fromPosition!.lat}, ${widget.args.fromPosition!.lng}');
        print('To position: ${currentPosition!.lat}, ${currentPosition!.lng}');
        
        final fromLat = widget.args.fromPosition!.lat.toDouble();
        final fromLng = widget.args.fromPosition!.lng.toDouble();
        final toLat = currentPosition!.lat.toDouble();
        final toLng = currentPosition!.lng.toDouble();
        
        // Skip route calculation if points are too close (less than 50 meters)
        if (_calculateDistance(
            geotypes.Position(fromLng, fromLat), 
            geotypes.Position(toLng, toLat)) < 50) {
          setState(() {
            _isRouteLoading = false;
          });
          return;
        }
        
        // Clear any existing routes first
        await _clearRouteFromMap();
        
        // Get route from Mapbox API
        final directions = await inject<MapboxApi>().getDirections(
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );
        
        if (!mounted) return;
        
        setState(() {
          _route = directions ?? {};
          _isRouteLoading = false;
          _hasRoute = directions != null && directions.isNotEmpty;
        });
        
        print('Route data received, hasRoute: $_hasRoute');
        
        // Add route to map
        if (mapboxMapController != null && _route.isNotEmpty) {
          await _addRouteToMap();
          await _addRouteMarkersToMap();
          
          // Zoom camera to show entire route with better padding
          if (_route.containsKey('routes') && 
              _route['routes'] != null && 
              _route['routes'].isNotEmpty &&
              _route['routes'][0].containsKey('bounds')) {
            _fitCameraToBounds(_route['routes'][0]['bounds']);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isRouteLoading = false;
          });
        }
        print('Error drawing route: $e');
      }
    } else {
      print('Cannot draw route: fromPosition or currentPosition is null');
      print('fromPosition: ${widget.args.fromPosition}');
      print('currentPosition: $currentPosition');
    }
  }
  
  // Clear any existing route from the map
  Future<void> _clearRouteFromMap() async {
    if (mapboxMapController == null) return;
    
    try {
      print('Очистка существующего маршрута...');
      
      // Remove existing route layers
      for (final layerId in ['route-layer', 'route-outline-layer', 'markers-layer']) {
        if (await mapboxMapController!.style.styleLayerExists(layerId)) {
          await mapboxMapController!.style.removeStyleLayer(layerId);
          print('Удален слой $layerId');
        }
      }
      
      // Remove existing sources
      for (final sourceId in ['route-source', 'markers-source']) {
        if (await mapboxMapController!.style.styleSourceExists(sourceId)) {
          await mapboxMapController!.style.removeStyleSource(sourceId);
          print('Удален источник $sourceId');
        }
      }
      
      print('Маршрут успешно очищен');
    } catch (e) {
      print('Ошибка при очистке маршрута: $e');
    }
  }
  
  // Fit camera to show entire route with proper padding
  Future<void> _fitCameraToBounds(List<List<double>> bounds) async {
    if (mapboxMapController == null) return;
    
    try {
      final southwest = bounds[0];
      final northeast = bounds[1];
      
      // Add some padding to ensure the entire route is visible
      final camera = await mapboxMapController!.cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: geotypes.Position(southwest[0], southwest[1])),
          northeast: Point(coordinates: geotypes.Position(northeast[0], northeast[1])),
          infiniteBounds: false
        ),
        // Adjust padding to ensure route is visible with markers
        MbxEdgeInsets(top: 150, left: 50, bottom: 200, right: 50),
        null, // bearing
        null, // pitch
        null, // maxZoom
        null, // minZoom - removed as it's causing errors
      );
      
      await mapboxMapController!.flyTo(
        camera,
        MapAnimationOptions(duration: 1000),
      );
      
      print('Камера настроена для отображения всего маршрута');
    } catch (e) {
      print('Error fitting camera to bounds: $e');
      
      // Fallback to simpler approach if the above fails
      try {
        final southwest = bounds[0];
        final northeast = bounds[1];
        
        // Calculate center point
        final centerLng = (southwest[0] + northeast[0]) / 2;
        final centerLat = (southwest[1] + northeast[1]) / 2;
        
        await mapboxMapController!.flyTo(
          CameraOptions(
            center: Point(coordinates: geotypes.Position(centerLng, centerLat)),
            zoom: 14.0, // Slightly zoomed out
          ),
          MapAnimationOptions(duration: 1000),
        );
        
        print('Камера настроена на центр маршрута (fallback)');
      } catch (e) {
        print('Error with fallback camera positioning: $e');
      }
    }
  }
  
  // Add route line to map
  Future<void> _addRouteToMap() async {
    if (mapboxMapController == null || _route.isEmpty) {
      print('Невозможно добавить маршрут: controller=${mapboxMapController != null}, route=${_route.isNotEmpty}');
      return;
    }

    try {
      print('Добавление маршрута на карту...');
      // Check route data
      if (!_route.containsKey('routes') || _route['routes'] == null || _route['routes'].isEmpty) {
        print('В ответе API нет маршрутов: ${_route.keys}');
        return;
      }

      // Check route geometry
      if (!_route['routes'][0].containsKey('geometry') || _route['routes'][0]['geometry'] == null) {
        print('В маршруте нет геометрии: ${_route['routes'][0].keys}');
        return;
      }

      print('Геометрия маршрута найдена');

      // Remove existing route layers
      try {
        for (final layerId in ['route-layer', 'route-outline-layer']) {
          if (await mapboxMapController!.style.styleLayerExists(layerId)) {
            await mapboxMapController!.style.removeStyleLayer(layerId);
          }
        }
        if (await mapboxMapController!.style.styleSourceExists('route-source')) {
          await mapboxMapController!.style.removeStyleSource('route-source');
        }
      } catch (e) {
        print('Ошибка при удалении существующих слоев: $e');
      }

      // Create GeoJSON LineString
      final routeGeometry = _route['routes'][0]['geometry'];
      print('Тип геометрии: ${routeGeometry.runtimeType}');
      
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
      
      print('Подготовлен JSON для маршрута');

      // Add data source for route
      await mapboxMapController!.style.addSource(GeoJsonSource(
        id: 'route-source',
        data: jsonData,
      ));
      
      print('Источник маршрута добавлен');

      // Add outline layer for route (wider, appears as border)
      await mapboxMapController!.style.addLayer(LineLayer(
        id: 'route-outline-layer',
        sourceId: 'route-source',
        lineColor: Colors.white.value,
        lineWidth: 7.0,
        lineOpacity: 0.9,
      ));

      // Add main route line layer
      await mapboxMapController!.style.addLayer(LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: primaryColor.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
      
      print('Слои маршрута добавлены успешно');
    } catch (e) {
      print('Ошибка при добавлении линии маршрута: $e');
    }
  }

  // Add route markers to map with improved styling
  Future<void> _addRouteMarkersToMap() async {
    if (mapboxMapController == null || widget.args.fromPosition == null || currentPosition == null) return;

    try {
      print('Adding route markers to map...');
      
      // Remove existing marker layers
      if (await mapboxMapController!.style.styleLayerExists('markers-layer')) {
        await mapboxMapController!.style.removeStyleLayer('markers-layer');
      }
      if (await mapboxMapController!.style.styleLayerExists('markers-layer-a')) {
        await mapboxMapController!.style.removeStyleLayer('markers-layer-a');
      }
      if (await mapboxMapController!.style.styleLayerExists('markers-layer-b')) {
        await mapboxMapController!.style.removeStyleLayer('markers-layer-b');
      }
      if (await mapboxMapController!.style.styleSourceExists('markers-source')) {
        await mapboxMapController!.style.removeStyleSource('markers-source');
      }
      if (await mapboxMapController!.style.styleSourceExists('markers-source-a')) {
        await mapboxMapController!.style.removeStyleSource('markers-source-a');
      }
      if (await mapboxMapController!.style.styleSourceExists('markers-source-b')) {
        await mapboxMapController!.style.removeStyleSource('markers-source-b');
      }

      // Create separate GeoJSON for point A (origin)
      final markersJsonA = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [widget.args.fromPosition!.lng, widget.args.fromPosition!.lat]
            },
            "properties": {
              "icon": "point_a",
              "title": "Откуда"
            }
          }
        ]
      };
      
      // Create separate GeoJSON for point B (destination)
      final markersJsonB = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [currentPosition!.lng, currentPosition!.lat]
            },
            "properties": {
              "icon": "point_b",
              "title": "Куда"
            }
          }
        ]
      };
      
      // Add data sources for markers
      await mapboxMapController!.style.addSource(GeoJsonSource(
        id: 'markers-source-a',
        data: json.encode(markersJsonA),
      ));
      
      await mapboxMapController!.style.addSource(GeoJsonSource(
        id: 'markers-source-b',
        data: json.encode(markersJsonB),
      ));
      
      // Add symbol layer for point A with smaller size
      await mapboxMapController!.style.addLayer(SymbolLayer(
        id: 'markers-layer-a',
        sourceId: 'markers-source-a',
        iconImage: "point_a",
        iconSize: 0.5, // Размер маркера А
        iconAnchor: IconAnchor.BOTTOM,
        minZoom: 0, // Видно на любом масштабе
        maxZoom: 22, // Максимальный зум
        iconAllowOverlap: true, // Разрешаем перекрытие иконок
      ));
      
      // Add symbol layer for point B with normal size
      await mapboxMapController!.style.addLayer(SymbolLayer(
        id: 'markers-layer-b',
        sourceId: 'markers-source-b',
        iconImage: "point_b",
        iconSize: 0.5, // Размер маркера В
        iconAnchor: IconAnchor.BOTTOM,
        minZoom: 0, // Видно на любом масштабе
        maxZoom: 22, // Максимальный зум
        iconAllowOverlap: true, // Разрешаем перекрытие иконок
      ));
      
      print('Route markers added successfully with different sizes');
    } catch (e) {
      print('Ошибка при добавлении маркеров: $e');
    }
  }
  
  // Add image to map style with proper scaling
  Future<void> addImageFromAsset(String name, String assetName, {double scale = 1.0}) async {
    try {
      print('Adding image $name from asset $assetName with scale $scale');
      
      final ByteData bytes = await rootBundle.load(assetName);
      final Uint8List list = bytes.buffer.asUint8List();
      
      final ui.Codec codec = await ui.instantiateImageCodec(list);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      // Apply same scaling for both markers for consistency
      double finalScale = scale;
      
      // Calculate the final dimensions
      int scaledWidth = (originalImage.width * finalScale).round();
      int scaledHeight = (originalImage.height * finalScale).round();
      
      // Ensure minimum size
      if (scaledWidth < 10) scaledWidth = 10;
      if (scaledHeight < 10) scaledHeight = 10;
      
      print('Creating scaled image: $name with dimensions $scaledWidth x $scaledHeight');
      
      // Create a scaled image
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
        
        await mapboxMapController!.style.addStyleImage(
          name,
          1.0, // Use scale factor of 1.0 since we've already pre-scaled the image
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
        
        print('Successfully added scaled image: $name');
      } else {
        print('Failed to get scaled image data, using original image as fallback');
        
        // Fallback to original image if scaling fails
        await mapboxMapController!.style.addStyleImage(
          name,
          scale * 0.5, // Use a smaller scale for fallback
          MbxImage(
            width: originalImage.width,
            height: originalImage.height,
            data: list,
          ),
          false,
          [],
          [],
          null,
        );
      }
    } catch (e) {
      print('Error adding image: $e');
    }
  }

  // Handle widget updates
  @override
  void didUpdateWidget(covariant MapAddressPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update route if parameters changed
    if (widget.args.fromPosition != null && currentPosition != null && 
        mapboxMapController != null && _isMapReady) {
      _drawRouteBetweenPoints();
    }
  }
  
  // Confirm button handler
  void _onConfirmPressed() {
    if (currentPosition != null) {
      try {
        print('Confirming location with address: $_addressName');
        
        // Check if we have a valid address
        if (_addressName.isEmpty || _addressName == "Адрес не найден") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось определить адрес, попробуйте переместить маркер')),
          );
          return;
        }
        
        // Get the final address to submit - prefer text field content if manually edited
        String finalAddress = _textFieldController.text.isNotEmpty ? 
            _textFieldController.text : _addressName;
            
        // Trim the address to avoid whitespace issues
        finalAddress = finalAddress.trim();
        
        // Make sure we don't pass empty addresses
        if (finalAddress.isEmpty) {
          finalAddress = "Выбранная точка";
        }
            
        print('Final address to submit: $finalAddress');
        
        // Make sure the widget args onSubmit handler is actually called
        try {
          widget.args.onSubmit(currentPosition!, finalAddress);
          print('Called onSubmit with position ${currentPosition!.lat},${currentPosition!.lng} and address: $finalAddress');
        } catch (e) {
          print('Error in onSubmit callback: $e');
        }
        
        // Navigate back with result
        Navigator.of(context).pop({
          'position': currentPosition,
          'placeName': finalAddress,
          'shouldShowRoute': widget.args.fromPosition != null
        });
      } catch (e) {
        print('Error in _onConfirmPressed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла ошибка: $e')),
        );
      }
    }
  }

  // New professional center marker that's always visible and properly styled
  Widget _buildCenterMarker() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // Pin shadow (improved for better visibility)
          Container(
          width: 10,
          height: 10,
            decoration: BoxDecoration(
            color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 3),
                spreadRadius: 0.5,
                ),
            ]
          ),
            ),
        // Pin itself with animation for better visibility
        TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300),
          tween: Tween<double>(begin: _isDragging ? 0.9 : 1.0, end: _isDragging ? 1.1 : 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Transform.translate(
                offset: Offset(0, _isDragging ? -5 : 0), // Lift up slightly when dragging
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pin shadow glow effect
                    Container(
                      width: 12,
                      height: 12,
                decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
            ),
          ),
                    // Pin main body - SMALLER SIZE
                    Icon(
                      Icons.location_on,
            color: primaryColor,
                      size: 30, // Reduced from 40
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Update address name based on the current position
  void _updateAddressName(geotypes.Position position) {
    if (_lastFetchedPosition != null &&
        _calculateDistance(_lastFetchedPosition!, position) < 10) {
      // Skip if the position hasn't changed significantly
      return;
    }
    
    // Call _fetchAddress instead of implementing the same logic twice
    _fetchAddress(position);
  }

  // Calculate distance between two positions in meters
  double _calculateDistance(geotypes.Position pos1, geotypes.Position pos2) {
    try {
      return geoLocator.Geolocator.distanceBetween(
        pos1.lat.toDouble(), 
        pos1.lng.toDouble(), 
        pos2.lat.toDouble(), 
        pos2.lng.toDouble()
      );
    } catch (e) {
      print('Error calculating distance: $e');
      // Fallback to approximate calculation
      const earthRadius = 6371000; // in meters
      final dLat = _toRadians(pos2.lat.toDouble() - pos1.lat.toDouble());
      final dLon = _toRadians(pos2.lng.toDouble() - pos1.lng.toDouble());
      final a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(pos1.lat.toDouble())) * 
        cos(_toRadians(pos2.lat.toDouble())) *
        sin(dLon / 2) * sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1-a));
      return earthRadius * c;
    }
  }
  
  // Convert degrees to radians
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  // Get location suggestions
  Future<List<String>> getSuggestions(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }
      
      // Получаем координаты для поиска ближайших мест
      final latitude = inject<SharedPreferences>().getDouble('latitude') ?? 
                      (currentPosition?.lat.toDouble() ?? 43.239337);
      final longitude = inject<SharedPreferences>().getDouble('longitude') ?? 
                       (currentPosition?.lng.toDouble() ?? 76.893156);
      
      final response = await inject<RestClient>().getPlacesQuery(
        query: query,
        latitude: latitude, 
        longitude: longitude,
      );

      // Безопасно присваиваем значение suggestions
      suggestions = response != null ? [...response] : [];
      
      // Преобразуем ответ в список строк
      final resultList = suggestions.map((e) => e.name ?? '').where((name) => name.isNotEmpty).toList();
      print('Found ${resultList.length} suggestions for query: $query');
      
      return resultList;
    } on Exception catch (e) {
      print('Error getting suggestions: $e');
      // Возвращаем пустой список в случае ошибки
    return [];
    }
  }

  // Search field change handler
  onPlaceSearchChanged(String searchValue) {
    if (searchValue.isEmpty) {
    setState(() {
        _showDeleteButton = false;
      });
    } else {
      setState(() {
        _showDeleteButton = true;
    });
    }
  }

  // Initialize map and load initial position
  Future<void> initializeMap() async {
    try {
      print('Initializing map...');
      
      // Request location permission if needed
      await inject<LocationInteractor>().requestLocation();
      
      // Get current location - IMPORTANT: We'll only use this for initializing the map view,
      // not for setting the marker position unless explicitly requested
      final location = await inject<LocationInteractor>().getCurrentLocation();
      if (location != null) {
        userLocation = geotypes.Position(location.longitude, location.latitude);
        await inject<SharedPreferences>().setDouble('latitude', location.latitude);
        await inject<SharedPreferences>().setDouble('longitude', location.longitude);
        
        print('Got user location: ${location.latitude}, ${location.longitude}');
        
        // Only set current position from user location if no position was provided
        if (widget.args.position == null) {
          currentPosition = userLocation;
          print('Setting initial marker position to user location');
        }
      }
    } catch (e) {
      print('Error initializing map: $e');
    }
  }

  // Start a periodic check for map position changes
  void _startPeriodicPositionCheck() {
    // Poll the camera position periodically as a backup to gesture detection
    timer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (mapboxMapController == null || !_isMapReady || !mounted) return;
      
      try {
        // Only check if we're not already in the middle of a drag operation
        if (!_isDragging) {
          // Get current camera position
          final cameraState = await mapboxMapController!.getCameraState();
          final mapCenter = geotypes.Position(
            cameraState.center.coordinates.lng,
            cameraState.center.coordinates.lat
          );
          
          // If position has changed significantly since last fetch
          if (_lastFetchedPosition != null &&
              _calculateDistance(_lastFetchedPosition!, mapCenter) > 10) {
            print('Detected significant position change from timer: ${mapCenter.lat}, ${mapCenter.lng}');
            _handleMapMovementStopped();
          }
        }
      } catch (e) {
        print('Error in periodic position check: $e');
      }
    });
  }
} 