import 'package:aktau_go/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import './router/router.dart';
import './app.dart';
import 'di/di_container.dart';
import 'interactors/notification_interactor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Set Mapbox access token
  MapboxOptions.setAccessToken('sk.eyJ1IjoidmFuZGVydmFpeiIsImEiOiJjbTA1azhkNjEwNDF2MmtzNHA0eWJ3eTR0In0.cSGmIeLW1Wc44gyBBWJsYA');

  await Firebase.initializeApp();

  Routes.initRoutes();
  await initDi(Environment.prod);

  runApp(
    EasyLocalization(
      child: MyApp(),
      supportedLocales: [
        Locale('kk'),
        Locale('ru'),
        Locale('en'),
      ],
      path: 'assets/localizations',
      // <-- change the path of the translation files
      fallbackLocale: Locale('en', 'US'),
    ),
  );
}
