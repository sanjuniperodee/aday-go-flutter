import 'package:aktau_go/ui/about_application/about_application_screen.dart';
import 'package:aktau_go/ui/driver_registration/driver_registration_screen.dart';
import 'package:aktau_go/ui/history/history_screen.dart';
import 'package:aktau_go/ui/main/main_screen.dart';
import 'package:aktau_go/ui/map_picker/map_picker_screen.dart';
import 'package:aktau_go/ui/notifications/notifications_screen.dart';
import 'package:aktau_go/ui/onboarding/onboarding_screen.dart';
import 'package:aktau_go/ui/registration/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:seafarer/seafarer.dart';

import '../ui/login/login_screen.dart';
import '../ui/otp/otp_screen.dart';

// Добавляем экспорт для отладки ошибок
import 'dart:developer';

class Routes {
  Routes._();

  static final router = Seafarer(
    options: SeafarerOptions(
      defaultTransitionDuration: Duration(milliseconds: 500),
    ),
  );

  static initRoutes() {
    router.addRoutes([
      SeafarerRoute(
        name: mainScreen,
        builder: (context, args, params) => MainScreen(),
      ),
      SeafarerRoute(
        name: loginScreen,
        builder: (context, args, params) => LoginScreen(
            // popOnSuccess: (args as LoginScreenArgs?)?.popOnSuccess ?? false,
            ),
      ),
      SeafarerRoute(
        name: otpScreen,
        builder: (context, args, params) => OtpScreen(
          phoneNumber: (args as OtpScreenArgs).phoneNumber,
        ),
      ),
      SeafarerRoute(
        name: registrationScreen,
        builder: (context, args, params) => RegistrationScreen(
          phoneNumber: (args as RegistrationScreenArgs).phoneNumber,
        ),
      ),
      SeafarerRoute(
        name: driverRegistrationScreen,
        builder: (context, args, params) => DriverRegistrationScreen(),
      ),
      SeafarerRoute(
        name: onboardingScreen,
        builder: (context, args, params) => OnboardingScreen(),
      ),
      SeafarerRoute(
        name: selectMapPicker,
        builder: (context, args, params) {
          log('Router: selectMapPicker получил аргументы типа: ${args.runtimeType}');
          
          // Полностью переработанная логика обработки аргументов
          try {
            // Если пришел ArgumentsWrapper
            if (args is ArgumentsWrapper) {
              log('Аргументы в формате ArgumentsWrapper');
              final actualArgs = args.arguments;
              
              if (actualArgs is MapAddressPickerScreenArgs) {
                log('Внутри wrapper содержится MapAddressPickerScreenArgs');
                return MapAddressPickerScreen(args: actualArgs);
              } 
              
              if (actualArgs is Map<String, dynamic>) {
                log('Внутри wrapper содержится Map');
                return MapAddressPickerScreen(
                  args: MapAddressPickerScreenArgs(
                    placeName: actualArgs['placeName'],
                    position: actualArgs['position'],
                    fromPosition: actualArgs['fromPosition'],
                    onSubmit: (position, placeName) {
                      final callback = actualArgs['onSubmit'] ?? actualArgs['onSubmitCallback'];
                      if (callback != null) {
                        callback(position, placeName);
                      } else {
                        log('ВНИМАНИЕ: коллбэк отсутствует в аргументах');
                      }
                    },
                  ),
                );
              }
            }
            
            // Напрямую передан MapAddressPickerScreenArgs
            if (args is MapAddressPickerScreenArgs) {
              log('Аргументы напрямую в формате MapAddressPickerScreenArgs');
              return MapAddressPickerScreen(args: args);
            }
            
            // Напрямую передан Map
            if (args is Map<String, dynamic>) {
              log('Аргументы напрямую в формате Map');
              return MapAddressPickerScreen(
                args: MapAddressPickerScreenArgs(
                  placeName: args['placeName'],
                  position: args['position'],
                  fromPosition: args['fromPosition'],
                  onSubmit: (position, placeName) {
                    final callback = args['onSubmit'] ?? args['onSubmitCallback'];
                    if (callback != null) {
                      callback(position, placeName);
                    } else {
                      log('ВНИМАНИЕ: коллбэк отсутствует в аргументах');
                    }
                  },
                ),
              );
            }
            
            // Запасной вариант - использовать пустые аргументы
            log('Не удалось определить тип аргументов. Используем пустые аргументы.');
            return MapAddressPickerScreen(
              args: MapAddressPickerScreenArgs.empty()
            );
          } catch (e) {
            log('Ошибка при обработке аргументов: $e');
            return MapAddressPickerScreen(
              args: MapAddressPickerScreenArgs.empty()
            );
          }
        },
      ),
      SeafarerRoute(
        name: historyScreen,
        builder: (context, args, params) => HistoryScreen(),
      ),
      SeafarerRoute(
        name: notificationsScreen,
        builder: (context, args, params) => NotificationsScreen(),
      ),
      SeafarerRoute(
        name: editProfileScreen,
        builder: (context, args, params) => Scaffold(
          appBar: AppBar(title: Text('Редактирование профиля')),
          body: Center(child: Text('Экран редактирования профиля в разработке')),
        ),
      ),
    ]);
  }

  static const String mainScreen = '/main_screen';
  static const String loginScreen = '/login_screen';
  static const String otpScreen = '/otp_screen';
  static const String registrationScreen = '/registration_screen';
  static const String driverRegistrationScreen = '/driver_registration_screen';
  static const String onboardingScreen = '/onboarding_screen';
  static const String selectMapPicker = '/select_map_picker';
  static const String historyScreen = '/history_screen';
  static const String notificationsScreen = '/notifications_screen';
  static const String editProfileScreen = '/edit_profile_screen';
}

class MyCustomTransition extends CustomSeafarerTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = 0.0;
    const end = 1.0;
    var tween = Tween(begin: begin, end: end);
    var curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );

    return ScaleTransition(
      scale: tween.animate(curvedAnimation),
      child: child,
    );
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
}
