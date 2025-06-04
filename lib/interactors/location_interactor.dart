import 'dart:async';
import 'dart:io';

import 'package:elementary_helper/elementary_helper.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;

abstract class ILocationInteractor {
  StateNotifier<geoLocator.LocationPermission> get locationStatus;

  StateNotifier<bool> get locationServiceEnabled;

  StateNotifier<LatLng> get userLocation;

  Future<void> requestLocation();
  
  Future<geoLocator.Position?> getCurrentLocation();
}

@singleton
class LocationInteractor extends ILocationInteractor {
  final SharedPreferences sharedPreferences;

  LocationInteractor(
    this.sharedPreferences,
  );

  late StreamSubscription<LocationData> onUserLocationChanged;

  @override
  final StateNotifier<geoLocator.LocationPermission> locationStatus =
      StateNotifier();

  @override
  StateNotifier<bool> locationServiceEnabled = StateNotifier(
    initValue: false,
  );

  @override
  late final StateNotifier<LatLng> userLocation = StateNotifier(
      initValue: LatLng(
    sharedPreferences.getDouble('latitude') ?? 0,
    sharedPreferences.getDouble('longitude') ?? 0,
  ));

  @override
  Future<geoLocator.LocationPermission?> requestLocation() async {
    try {
      print('🔍 Проверяем текущий статус разрешений...');
      
      // Проверяем включен ли сервис геолокации
      bool serviceEnabled = await geoLocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Сервис геолокации отключен');
        // Показываем диалог пользователю
        return null;
      }
      print('✅ Сервис геолокации включен');

      // Проверяем текущие разрешения
      geoLocator.LocationPermission permission = await geoLocator.Geolocator.checkPermission();
      print('📍 Текущие разрешения: $permission');

      // Если разрешения отклонены, запрашиваем их
      if (permission == geoLocator.LocationPermission.denied) {
        print('🔄 Запрашиваем разрешения...');
        permission = await geoLocator.Geolocator.requestPermission();
        print('📝 Получен ответ: $permission');
        
        if (permission == geoLocator.LocationPermission.denied) {
          print('❌ Разрешения отклонены пользователем');
          return null;
        }
      }

      // Если разрешения навсегда отклонены
      if (permission == geoLocator.LocationPermission.deniedForever) {
        print('❌ Разрешения навсегда отклонены');
        // Показываем диалог для перехода в настройки
        return null;
      }

      print('✅ Разрешения получены: $permission');
      locationStatus.accept(permission);
      
      return permission;
    } catch (e) {
      print('❌ Ошибка при запросе разрешений: $e');
      return null;
    }
  }

  @override
  Future<geoLocator.Position?> getCurrentLocation() async {
    try {
      print('🎯 Начинаем получение текущего местоположения...');
      
      // Сначала проверяем разрешения
      geoLocator.LocationPermission permission = await geoLocator.Geolocator.checkPermission();
      
      if (permission == geoLocator.LocationPermission.denied) {
        print('🔄 Разрешения отсутствуют, запрашиваем...');
        permission = await geoLocator.Geolocator.requestPermission();
        if (permission == geoLocator.LocationPermission.denied) {
          print('❌ Не удалось получить разрешения');
          return null;
        }
      }
      
      if (permission == geoLocator.LocationPermission.deniedForever) {
        print('❌ Разрешения навсегда отклонены');
        return null;
      }
      
      // Проверяем что сервис включен
      bool serviceEnabled = await geoLocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Сервис геолокации отключен');
        return null;
      }
      
      print('✅ Разрешения и сервисы в порядке, получаем позицию...');
      
      // Получаем текущую позицию
      if (Platform.isAndroid) {
        final position = await geoLocator.Geolocator.getCurrentPosition(
          locationSettings: geoLocator.LocationSettings(
            accuracy: geoLocator.LocationAccuracy.high,
            timeLimit: Duration(seconds: 15), // Таймаут 15 секунд
          ),
        );
        
        print('📍 Позиция получена: ${position.latitude}, ${position.longitude}');
        
        // Сохраняем в SharedPreferences
        await sharedPreferences.setDouble('latitude', position.latitude);
        await sharedPreferences.setDouble('longitude', position.longitude);
        
        // Обновляем состояние
        userLocation.accept(LatLng(position.latitude, position.longitude));
        
        return position;
      } else {
        // Для iOS пробуем сначала последнюю известную позицию
        var position = await geoLocator.Geolocator.getLastKnownPosition();
        
        if (position == null) {
          // Если нет последней позиции, получаем текущую
          position = await geoLocator.Geolocator.getCurrentPosition(
            locationSettings: geoLocator.LocationSettings(
              accuracy: geoLocator.LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            ),
          );
        }
        
        if (position != null) {
          print('📍 Позиция получена: ${position.latitude}, ${position.longitude}');
          
          // Сохраняем в SharedPreferences
          await sharedPreferences.setDouble('latitude', position.latitude);
          await sharedPreferences.setDouble('longitude', position.longitude);
          
          // Обновляем состояние
          userLocation.accept(LatLng(position.latitude, position.longitude));
        }
        
        return position;
      }
    } catch (e) {
      print('❌ Ошибка получения местоположения: $e');
      
      // В случае ошибки пробуем получить последнюю известную позицию
      try {
        final lastPosition = await geoLocator.Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print('📍 Используем последнюю известную позицию: ${lastPosition.latitude}, ${lastPosition.longitude}');
          userLocation.accept(LatLng(lastPosition.latitude, lastPosition.longitude));
          return lastPosition;
        }
      } catch (e2) {
        print('❌ Не удалось получить последнюю позицию: $e2');
      }
      
      return null;
    }
  }
}
