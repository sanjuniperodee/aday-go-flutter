import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seafarer/seafarer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/common_strings.dart';
import '../../interactors/notification_interactor.dart';
import './onboarding_screen.dart';
import './onboarding_model.dart';

defaultOnboardingWMFactory(BuildContext context) =>
    OnboardingWM(OnboardingModel());

abstract class IOnboardingWM implements IWidgetModel {
  void skipNotificationPermission();

  void requestNotificationPermission();

  StateNotifier<int> get step;

  int get steps;

  void skipLocationPermission();

  void requestLocationPermission();
}

class OnboardingWM extends WidgetModel<OnboardingScreen, OnboardingModel>
    implements IOnboardingWM {
  OnboardingWM(
    OnboardingModel model,
  ) : super(model);

  @override
  void skipNotificationPermission() {
    inject<SharedPreferences>().setBool(NOTIFICATION_PERMISSION_GRANTED, false);
    step.accept(step.value! + 1);
  }

  @override
  Future<void> requestNotificationPermission() async {
    final rr = await FirebaseMessaging.instance.requestPermission();
    logger.w(rr);
    if (await Permission.notification.isGranted) {
      await inject<NotificationInteractor>().setupFirebaseConfig();
      step.accept(step.value! + 1);
    }
  }

  @override
  StateNotifier<int> step = StateNotifier(
    initValue: 0,
  );

  int steps = [
    if (inject<SharedPreferences>().getBool(NOTIFICATION_PERMISSION_GRANTED) ??
        true)
      true,
    if (inject<SharedPreferences>().getBool(LOCATION_PERMISSION_GRANTED) ??
        true)
      true,
  ].length;

  @override
  Future<void> requestLocationPermission() async {
    final permissionStatus = await Permission.location.request();
    final storage = inject<SharedPreferences>();
    if ([
      permissionStatus.isGranted,
      permissionStatus.isLimited,
    ].any((el) => el)) {
      if ((storage.getString(ACCESS_TOKEN) ?? '').isNotEmpty) {
        Routes.router.navigate(
          Routes.mainScreen,
          navigationType: NavigationType.pushReplace,
        );
      } else {
        Routes.router.navigate(
          Routes.loginScreen,
          navigationType: NavigationType.pushReplace,
        );
      }
    } else {}
  }

  @override
  void skipLocationPermission() {
    inject<SharedPreferences>().setBool(LOCATION_PERMISSION_GRANTED, false);
    final storage = inject<SharedPreferences>();
    if ((storage.getString(ACCESS_TOKEN) ?? '').isNotEmpty) {
      Routes.router.navigate(
        Routes.mainScreen,
        navigationType: NavigationType.pushReplace,
      );
    } else {
      Routes.router.navigate(
        Routes.loginScreen,
        navigationType: NavigationType.pushReplace,
      );
    }
  }
}
