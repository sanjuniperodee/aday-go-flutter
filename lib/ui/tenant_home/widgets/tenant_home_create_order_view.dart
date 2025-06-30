import 'dart:convert';
import 'dart:async';

import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/ui/map_picker/map_picker_screen.dart';
import 'package:aktau_go/ui/tenant_home/forms/driver_order_form.dart';
import 'package:aktau_go/ui/tenant_home/tenant_home_screen.dart';
import 'package:aktau_go/ui/tenant_home/tenant_home_wm.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/ui/widgets/primary_dropdown.dart';
import 'package:aktau_go/ui/widgets/rounded_text_field.dart';
import 'package:aktau_go/utils/text_editing_controller.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:aktau_go/utils/network_utils.dart';
import 'package:easy_autocomplete/easy_autocomplete.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geotypes/geotypes.dart' as geotypes;

import '../../../core/images.dart';
import '../../../forms/inputs/required_formz_input.dart';
import '../../../interactors/location_interactor.dart';

class TenantHomeCreateOrderView extends StatefulWidget {
  final ScrollController scrollController;
  final Function(DriverOrderForm) onSubmit;
  final String? isFromMapboxId;
  final String? isToMapboxId;
  final Function(geotypes.Position? fromPosition, geotypes.Position? toPosition)? onFieldsUpdated;

  const TenantHomeCreateOrderView({
    super.key,
    required this.scrollController,
    required this.onSubmit,
    this.isFromMapboxId,
    this.isToMapboxId,
    this.onFieldsUpdated,
  });

  @override
  State<TenantHomeCreateOrderView> createState() =>
      _TenantHomeCreateOrderViewState();
}

class _TenantHomeCreateOrderViewState extends State<TenantHomeCreateOrderView> {
  bool isLoading = false;
  late DriverOrderForm driverOrderForm;
  List<String> _suggestions = [];
  
  geotypes.Position? fromPosition;
  geotypes.Position? toPosition;

  List<String> cities = [
    'Актау',
    'Кызылтобе',
    'Акшукур',
    'Батыр',
    'Курык',
    'Жынгылды',
    'Жетыбай',
    'Таушик',
    'Шетпе',
    'Жанаозен',
    'Бейнеу',
    'Форт-Шевчкенко',
  ];

  late final TextEditingController fromAddressTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (fromAddress) {
      setState(() {
        driverOrderForm = driverOrderForm.copyWith(
          fromAddress: Required.dirty(fromAddress),
        );
      });
    },
  );
  late final TextEditingController toAddressTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (toAddress) {
      setState(() {
        driverOrderForm = driverOrderForm.copyWith(
          toAddress: Required.dirty(toAddress),
        );
      });
    },
  );
  late final TextEditingController costTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (cost) {
      setState(() {
        driverOrderForm = driverOrderForm.copyWith(
          cost: Required.dirty(num.tryParse(cost)),
        );
      });
    },
  );
  late final TextEditingController commentTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (comment) {
      setState(() {
        driverOrderForm = driverOrderForm.copyWith(
          comment: comment,
        );
      });
    },
  );

  @override
  void initState() {
    super.initState();
    driverOrderForm = DriverOrderForm();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromMapboxId != null && widget.isFromMapboxId!.isNotEmpty) {
        fromAddressTextController.text = widget.isFromMapboxId!;
        driverOrderForm = driverOrderForm.copyWith(
          fromAddress: Required.dirty(widget.isFromMapboxId!),
        );
      }
      
      if (widget.isToMapboxId != null && widget.isToMapboxId!.isNotEmpty) {
        toAddressTextController.text = widget.isToMapboxId!;
        driverOrderForm = driverOrderForm.copyWith(
          toAddress: Required.dirty(widget.isToMapboxId!),
        );
      }
      
      // Автоматически загружаем текущее местоположение, если fromAddress пустой
      if (fromAddressTextController.text.isEmpty) {
      _loadCurrentLocationAddress();
      }
    });
  }
  
  Future<void> _loadCurrentLocationAddress() async {
    try {
      print('Начинаем загрузку адреса местоположения...');
      
      // Show loading indicator in the from address field
      setState(() {
        isLoading = true;
      });
      
      // Request location permissions
      final locationInteractor = inject<LocationInteractor>();
      final permission = await locationInteractor.requestLocation();
      
      if (permission == null || permission == geoLocator.LocationPermission.denied || 
          permission == geoLocator.LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Для определения местоположения необходимо предоставить разрешение'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red[700],
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Get current location
      final currentLocation = await locationInteractor.getCurrentLocation();
      
      if (currentLocation != null) {
        print('Получены координаты: ${currentLocation.latitude}, ${currentLocation.longitude}');
        
        // Сохраняем координаты для последующего использования
        await inject<SharedPreferences>().setDouble('latitude', currentLocation.latitude);
        await inject<SharedPreferences>().setDouble('longitude', currentLocation.longitude);
        
        // Store position
        fromPosition = geotypes.Position(currentLocation.longitude, currentLocation.latitude);
        
        // Get address from coordinates
        final addressName = await inject<RestClient>().getPlaceDetail(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        );
        
        if (mounted && addressName != null && addressName.isNotEmpty) {
          setState(() {
            fromAddressTextController.text = addressName;
            driverOrderForm = driverOrderForm.copyWith(
              fromAddress: Required.dirty(addressName),
              fromMapboxId: Required.dirty('${currentLocation.latitude};${currentLocation.longitude}'),
            );
            isLoading = false;
          });
          
          // Notify parent about the update
          _notifyFieldsUpdate();
          
          print('Адрес установлен: $addressName');
        } else {
          print('Не удалось получить адрес по координатам');
          if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось получить адрес'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            isLoading = false;
          });
          }
        }
      } else {
        print('Не удалось получить координаты');
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось определить местоположение'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          isLoading = false;
        });
        }
      }
    } catch (e) {
      print('Ошибка при загрузке адреса: $e');
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка при получении местоположения'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        isLoading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Location selection card
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Origin location field
              GestureDetector(
                onTap: () {
                  print("FROM ADDRESS FIELD TAPPED - Opening map picker");
                  _openFromMapPicker();
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.my_location,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Откуда',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                isLoading
                                  ? Container(
                                      height: 20,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryColor,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Определение адреса...',
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      fromAddressTextController.text.isEmpty
                                        ? 'Выберите точку отправления'
                                        : fromAddressTextController.text,
                                      style: TextStyle(
                                        color: fromAddressTextController.text.isEmpty
                                          ? Colors.grey.shade400
                                          : Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
              // Destination location field
              GestureDetector(
                onTap: () {
                  print("TO ADDRESS FIELD TAPPED - Opening map picker");
                  _openToMapPicker();
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 1),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.place,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Куда',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  toAddressTextController.text.isEmpty
                                    ? 'Выберите пункт назначения'
                                    : toAddressTextController.text,
                                  style: TextStyle(
                                    color: toAddressTextController.text.isEmpty
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Price and comment section
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Price field
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: TextField(
                  controller: costTextController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Укажите цену',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // Dismiss keyboard
                      },
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              // Comment field
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: commentTextController,
                  maxLines: 2,
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'Комментарий (необязательно)',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.comment,
                      color: Colors.grey[600],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // Dismiss keyboard
                      },
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Order button
        Container(
          height: 50,
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: driverOrderForm.isValid ? handleOrderSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: primaryColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: isLoading
              ? CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                )
              : Text(
                  'Заказать такси',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Future<void> handleOrderSubmit() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      print('Отправка заказа...');
      
      // Используем новую систему обработки ошибок
      await NetworkUtils.executeWithErrorHandling<void>(
        () => widget.onSubmit(driverOrderForm),
        customErrorMessage: 'Не удалось создать заказ. Проверьте подключение к интернету.',
      );
      
      // Delay before closing form to allow for request processing
      await Future.delayed(Duration(milliseconds: 300));
      
      // Check if widget is still mounted
      if (mounted) {
        // Close form and return to main screen
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Заказ успешно создан, поиск водителя...',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      // Reset loading state only if widget is still mounted
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<String>> autocompletePlaces(String value) async {
    if (value.length <= 2) return [];

    final result = await NetworkUtils.executeWithErrorHandling<List<String>>(
      () async {
        // Get coordinates from SharedPreferences or use Aktau coordinates as default
        final latitude = inject<SharedPreferences>().getDouble('latitude') ?? 43.693695; // Aktau coordinates
        final longitude = inject<SharedPreferences>().getDouble('longitude') ?? 51.260834; // Aktau coordinates
        
        print('Поиск адресов для "$value" в районе координат: $latitude, $longitude');
        
        final request = await inject<RestClient>().getPlacesQuery(
          query: value,
          latitude: latitude,
          longitude: longitude,
        );
        
        if (request != null && request.isNotEmpty) {
          final suggestions = request.map((e) => e.name ?? '').toList();
          setState(() {
            _suggestions = suggestions;
          });
          return suggestions;
        }
        return <String>[];
      },
      showErrorMessages: false, // Не показываем ошибки для автокомплита
    );
    
    return result ?? [];
  }

  _onFromSubmitted(String json) {
    fromAddressTextController.text = (jsonDecode(json))['label'];
    setState(() {
      driverOrderForm = driverOrderForm.copyWith(
          fromAddress: Required.dirty((jsonDecode(json))['label']),
          fromMapboxId: Required.dirty((jsonDecode(json))['mapbox_id']));
    });
  }

  _onToSubmitted(String json) {
    toAddressTextController.text = (jsonDecode(json))['label'];
    setState(() {
      driverOrderForm = driverOrderForm.copyWith(
          toAddress: Required.dirty((jsonDecode(json))['label']),
          toMapboxId: Required.dirty((jsonDecode(json))['mapbox_id']));
    });
  }

  geotypes.Position? _parseCoordinatesFromMapboxId(String? mapboxId) {
    if (mapboxId == null || mapboxId.isEmpty) return null;
    
    try {
      print('Разбор строки координат: "$mapboxId"');
      
      // Format: "lat;lng" 
      final parts = mapboxId.split(';');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        
        if (lat != null && lng != null) {
          print('Успешно разобраны координаты: lat=$lat, lng=$lng');
          
          // In Mapbox coordinates are passed as [longitude, latitude]
          // Create Position with correct order (lng, lat)
          return geotypes.Position(lng, lat);
        } else {
          print('Ошибка: не удалось преобразовать строки в числа: "${parts[0]}", "${parts[1]}"');
        }
      } else {
        print('Ошибка: неверный формат строки координат, ожидался формат "lat;lng"');
      }
    } catch (e) {
      print('Ошибка при разборе координат: $e');
    }
    
    return null;
  }

  void _notifyFieldsUpdate() {
    if (widget.onFieldsUpdated != null) {
      widget.onFieldsUpdated!(fromPosition, toPosition);
    }
  }

  void _openFromMapPicker() async {
    try {
      FocusScope.of(context).unfocus(); // Dismiss keyboard
      
      print('Opening map picker for FROM address selection');
      
      final result = await Navigator.of(context).pushNamed(
        Routes.selectMapPicker,
        arguments: MapAddressPickerScreenArgs(
          position: fromPosition,
          placeName: fromAddressTextController.text,
          onSubmit: (position, placeName) {
            print('Selected FROM address: $placeName at position ${position.lat}, ${position.lng}');
            
            fromAddressTextController.text = placeName;
            
            setState(() {
              driverOrderForm = driverOrderForm.copyWith(
                fromAddress: Required.dirty(placeName),
                fromMapboxId: Required.dirty('${position.lat};${position.lng}'),
              );
              
              // Store position
              fromPosition = position;
            });
            
            // Notify parent about the update
            _notifyFieldsUpdate();
          },
        ),
      );
      
      if (result != null) {
        print('Map picker returned result: $result');
      }
    } catch (e) {
      print('Error opening map picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при открытии карты: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openToMapPicker() async {
    try {
      FocusScope.of(context).unfocus(); // Dismiss keyboard
      
      print('Opening map picker for TO address selection');
      
      final result = await Navigator.of(context).pushNamed(
        Routes.selectMapPicker,
        arguments: MapAddressPickerScreenArgs(
          position: toPosition,
          fromPosition: fromPosition, // Send FROM position to show route
          placeName: toAddressTextController.text,
          onSubmit: (position, placeName) {
            print('Selected TO address: $placeName at position ${position.lat}, ${position.lng}');
            
            toAddressTextController.text = placeName;
            
            setState(() {
              driverOrderForm = driverOrderForm.copyWith(
                toAddress: Required.dirty(placeName),
                toMapboxId: Required.dirty('${position.lat};${position.lng}'),
              );
              
              // Store position
              toPosition = position;
            });
            
            // Notify parent about the update
            _notifyFieldsUpdate();
          },
        ),
      );
      
      if (result != null) {
        print('Map picker returned result: $result');
      }
    } catch (e) {
      print('Error opening map picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при открытии карты: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
