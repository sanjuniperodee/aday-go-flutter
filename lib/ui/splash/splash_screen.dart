import 'package:aktau_go/core/images.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:seafarer/seafarer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/common_strings.dart';
import '../../di/di_container.dart';
import '../../interactors/session_interactor.dart';
import '../../router/router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    Key? key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 100,
              height: 100,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset('assets/images/launcher_icon.png'),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/lottie/splash.json'),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Загрузка',
                      style: text400Size16Greyscale90,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeApp() async {
    await Future.delayed(Duration(seconds: 4));
    SharedPreferences storage = await SharedPreferences.getInstance();
    await getIt<SessionInteractor>().checkAccessTokenExpired();

    bool showSplashScreen =
        !((storage.getBool(NOTIFICATION_PERMISSION_GRANTED) ?? true) ||
            (storage.getBool(LOCATION_PERMISSION_GRANTED) ?? true));

    if (showSplashScreen) {
      Routes.router.navigate(
        Routes.onboardingScreen,
        navigationType: NavigationType.pushReplace,
      );
    } else if ((storage.getString(ACCESS_TOKEN) ?? '').isNotEmpty) {
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
