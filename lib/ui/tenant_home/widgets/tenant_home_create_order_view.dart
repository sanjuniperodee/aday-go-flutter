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
  final bool isIntercity;
  final ScrollController scrollController;
  final Function(DriverOrderForm) onSubmit;
  final String? isFromMapboxId;
  final String? isToMapboxId;

  const TenantHomeCreateOrderView({
    super.key,
    required this.scrollController,
    required this.onSubmit,
    this.isIntercity = false,
    this.isFromMapboxId,
    this.isToMapboxId,
  });

  @override
  State<TenantHomeCreateOrderView> createState() =>
      _TenantHomeCreateOrderViewState();
}

class _TenantHomeCreateOrderViewState extends State<TenantHomeCreateOrderView> {
  bool isLoading = false;
  late DriverOrderForm driverOrderForm;
  List<String> _suggestions = [];

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
      }
      
      if (widget.isToMapboxId != null && widget.isToMapboxId!.isNotEmpty) {
        toAddressTextController.text = widget.isToMapboxId!;
      }
      
      _loadCurrentLocationAddress();
    });
  }
  
  Future<void> _loadCurrentLocationAddress() async {
    try {
      print('Начинаем загрузку адреса местоположения...');
      
      // Показываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Получение текущего местоположения...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Запрашиваем разрешения на геолокацию
      final locationInteractor = inject<LocationInteractor>();
      final permission = await locationInteractor.requestLocation();
      
      if (permission == null || permission == geoLocator.LocationPermission.denied || 
          permission == geoLocator.LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Для определения местоположения необходимо предоставить разрешение'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Получаем текущее местоположение
      final currentLocation = await locationInteractor.getCurrentLocation();
      
      if (currentLocation != null) {
        print('Получены координаты: ${currentLocation.latitude}, ${currentLocation.longitude}');
        
        // Получаем адрес по координатам
        final addressName = await inject<RestClient>().getPlaceDetail(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        );
        
        if (addressName != null && addressName.isNotEmpty) {
          setState(() {
            fromAddressTextController.text = addressName;
            driverOrderForm = driverOrderForm.copyWith(
              fromAddress: Required.dirty(addressName),
              fromMapboxId: Required.dirty('${currentLocation.latitude};${currentLocation.longitude}'),
            );
          });
          
          print('Адрес установлен: $addressName');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Адрес обновлен'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('Не удалось получить адрес по координатам');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось получить адрес'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('Не удалось получить координаты');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось определить местоположение'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Ошибка при загрузке адреса: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка при получении местоположения'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (widget.isIntercity)
            Container(
              height: 48,
              margin: const EdgeInsets.only(bottom: 16),
              child: PrimaryDropdown(
                  initialOption: driverOrderForm.fromAddress.value,
                  options: [
                    ...cities
                        .map((city) => SelectOption(
                              value: city,
                              label: city,
                            ))
                        .toList()
                  ],
                  hintText: 'Выберите город',
                  onChanged: (option) {
                    setState(() {
                      driverOrderForm = driverOrderForm.copyWith(
                        fromAddress: Required.dirty(option?.value),
                      );
                    });
                  }),
            )
          else
            InkWell(
              onTap: () async {
                // Открываем экран выбора адреса на карте
                print('Переход к выбору адреса "откуда"');
                var fromPosition = driverOrderForm.fromMapboxId.value?.isNotEmpty == true
                    ? _parseCoordinatesFromMapboxId(driverOrderForm.fromMapboxId.value)
                    : null;
                print('fromPosition: $fromPosition');
                
                final result = await Routes.router.navigate(
                  Routes.selectMapPicker,
                  args: MapAddressPickerScreenArgs(
                    placeName: fromAddressTextController.text,
                    position: fromAddressTextController.text.isNotEmpty 
                        ? _parseCoordinatesFromMapboxId(driverOrderForm.fromMapboxId.value)
                        : null,
                    onSubmit: (position, placeName) {
                      print('Выбран адрес "откуда": $placeName, координаты: $position');
                      // Обработка будет в асинхронном блоке ниже
                    },
                  ),
                );
                
                // Обрабатываем возвращаемые данные
                if (result != null && result is Map) {
                  setState(() {
                    final position = result['position'] as geotypes.Position?;
                    final placeName = result['placeName'] as String?;
                    
                    if (position != null && placeName != null) {
                      fromAddressTextController.text = placeName;
                      driverOrderForm = driverOrderForm.copyWith(
                        fromAddress: Required.dirty(placeName),
                        fromMapboxId: Required.dirty('${position.lat};${position.lng}'),
                      );
                    }
                  });
                }
              },
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: greyscale30,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: EasyAutocomplete(
                    controller: fromAddressTextController,
                    asyncSuggestions: autocompletePlaces,
                    progressIndicatorBuilder: Center(
                      child: CircularProgressIndicator(
                        color: greyscale30,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Откуда*',
                      border: InputBorder.none,
                      prefixIcon: SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: SvgPicture.asset(
                            icPlacemark,
                          ),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.refresh, color: primaryColor),
                        onPressed: () {
                          _loadCurrentLocationAddress();
                        },
                        tooltip: 'Обновить адрес',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    suggestionBuilder: (String json) {
                      return ListTile(
                        title: Text(jsonDecode(json)['label']),
                      );
                    },
                    onSubmitted: _onFromSubmitted,
                    onChanged: (String json) async {
                      // widget.onSubmit(
                      //   LatLng(
                      //     response.result?.geometry?.location?.lat ?? 0,
                      //     response.result?.geometry?.location?.lng ?? 0,
                      //   ),
                      //   feature.description ?? '',
                      // );
                    },
                  ),
                ),
              ),
            ),
          if (widget.isIntercity)
            Container(
              height: 48,
              margin: const EdgeInsets.only(bottom: 16),
              child: PrimaryDropdown(
                initialOption: driverOrderForm.toAddress.value,
                options: [
                  ...cities
                      .map((city) => SelectOption(
                            value: city,
                            label: city,
                          ))
                      .toList()
                ],
                hintText: 'Выберите город',
                onChanged: (option) {
                  setState(
                    () {
                      driverOrderForm = driverOrderForm.copyWith(
                        toAddress: Required.dirty(option?.value),
                      );
                    },
                  );
                },
              ),
            )
          else
            InkWell(
              onTap: () async {
                // Открываем экран выбора адреса на карте
                print('Переход к выбору адреса "куда"');
                var fromPosition = driverOrderForm.fromMapboxId.value?.isNotEmpty == true
                    ? _parseCoordinatesFromMapboxId(driverOrderForm.fromMapboxId.value)
                    : null;
                print('fromPosition для маршрута: $fromPosition');
                
                final result = await Routes.router.navigate(
                  Routes.selectMapPicker,
                  args: MapAddressPickerScreenArgs(
                    placeName: toAddressTextController.text,
                    position: toAddressTextController.text.isNotEmpty 
                        ? _parseCoordinatesFromMapboxId(driverOrderForm.toMapboxId.value)
                        : null,
                    fromPosition: driverOrderForm.fromMapboxId.value?.isNotEmpty == true
                        ? _parseCoordinatesFromMapboxId(driverOrderForm.fromMapboxId.value)
                        : null,
                    onSubmit: (position, placeName) {
                      print('Выбран адрес "куда": $placeName, координаты: $position');
                      // Обработка будет в асинхронном блоке ниже
                    },
                  ),
                );
                
                // Обрабатываем возвращаемые данные
                if (result != null && result is Map) {
                  setState(() {
                    final position = result['position'] as geotypes.Position?;
                    final placeName = result['placeName'] as String?;
                    
                    if (position != null && placeName != null) {
                      toAddressTextController.text = placeName;
                      driverOrderForm = driverOrderForm.copyWith(
                        toAddress: Required.dirty(placeName),
                        toMapboxId: Required.dirty('${position.lat};${position.lng}'),
                      );
                      
                      // Если есть адрес "откуда", отображаем маршрут на главной карте
                      if (driverOrderForm.fromMapboxId.value?.isNotEmpty == true) {
                        final fromPosition = _parseCoordinatesFromMapboxId(driverOrderForm.fromMapboxId.value);
                        if (fromPosition != null) {
                          try {
                            // Используем более прямой подход для доступа к главному экрану
                            final navigator = Navigator.of(context);
                            if (navigator.canPop()) {
                              // Передаем координаты обратно для отображения маршрута
                              navigator.pop({
                                'fromPosition': fromPosition,
                                'toPosition': position,
                                'fromAddress': driverOrderForm.fromAddress.value,
                                'toAddress': driverOrderForm.toAddress.value,
                                'shouldShowRoute': true,
                                'timestamp': DateTime.now().millisecondsSinceEpoch // Добавляем временную метку для уникальности события
                              });
                              
                              print('Передали координаты маршрута на главный экран: from=${fromPosition.lat},${fromPosition.lng} to=${position.lat},${position.lng}');
                            }
                          } catch (e) {
                            print('Ошибка при попытке отобразить маршрут: $e');
                          }
                        }
                      }
                    }
                  });
                }
              },
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: greyscale30,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: EasyAutocomplete(
                    controller: toAddressTextController,
                    asyncSuggestions: autocompletePlaces,
                    progressIndicatorBuilder: Center(
                      child: CircularProgressIndicator(
                        color: greyscale30,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Куда*',
                      border: InputBorder.none,
                      prefixIcon: SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: SvgPicture.asset(
                            icPlacemark,
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    suggestionBuilder: (String json) {
                      return ListTile(
                        title: Text(jsonDecode(json)['label']),
                      );
                    },
                    onSubmitted: _onToSubmitted,
                    onChanged: (String json) async {
                      // widget.onSubmit(
                      //   LatLng(
                      //     response.result?.geometry?.location?.lat ?? 0,
                      //     response.result?.geometry?.location?.lng ?? 0,
                      //   ),
                      //   feature.description ?? '',
                      // );
                    },
                  ),
                ),
              ),
            ),
          Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            child: RoundedTextField(
              backgroundColor: Colors.white,
              controller: costTextController,
              hintText: 'Укажите цену*',
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: RoundedTextField(
              backgroundColor: Colors.white,
              controller: commentTextController,
              hintText: 'Комментарий',
              maxLines: 2,
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton.primary(
              isLoading: isLoading,
              onPressed: driverOrderForm.isValid ? handleOrderSubmit : null,
              text: 'Заказать',
              textStyle: text400Size16White,
            ),
          )
        ],
      ),
    );
  }

  Future<void> handleOrderSubmit() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      print('Отправка заказа...');
      await widget.onSubmit(driverOrderForm);
      
      // Задержка перед закрытием формы, чтобы дать время для обработки запроса
      await Future.delayed(Duration(milliseconds: 300));
      
      // Проверяем, что виджет все еще смонтирован
      if (mounted) {
        // Закрываем форму и возвращаемся на главный экран
        Navigator.of(context).pop();
        
        // Показываем сообщение об успешном создании заказа
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заказ успешно создан'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      print('Ошибка при создании заказа: $e');
      // Обработка ошибки только если виджет все еще смонтирован
      if (mounted) {
        final snackBar = SnackBar(
          content: Text('Не удалось создать заказ: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      // Сбрасываем состояние загрузки только если виджет все еще смонтирован
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<String>> autocompletePlaces(String value) async {
    if (value.length <= 2) return [];

    try {
      // Получаем координаты из SharedPreferences или используем координаты Актау по умолчанию
      final latitude = inject<SharedPreferences>().getDouble('latitude') ?? 43.693695; // координаты Актау вместо Алматы
      final longitude = inject<SharedPreferences>().getDouble('longitude') ?? 51.260834; // координаты Актау вместо Алматы
      
      print('Поиск адресов для "$value" в районе координат: $latitude, $longitude');
      
      final request = await inject<RestClient>().getPlacesQuery(
        query: value,
        latitude: latitude,
        longitude: longitude,
      );
      
      if (request != null && request.isNotEmpty) {
        setState(() {
          _suggestions = request.map((e) => e.name ?? '').toList();
        });
        return request.map((e) => e.name ?? '').toList();
      }
    } catch (e) {
      print('Error in autocompletePlaces: $e');
    }
    return [];
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
      
      // Формат координат: "lat;lng" 
      final parts = mapboxId.split(';');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        
        if (lat != null && lng != null) {
          print('Успешно разобраны координаты: lat=$lat, lng=$lng');
          
          // В Mapbox координаты передаются в формате [longitude, latitude]
          // Создаем Position с правильным порядком (lng, lat)
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
}
