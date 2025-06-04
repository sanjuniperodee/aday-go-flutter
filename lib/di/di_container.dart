import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../interactors/common/aktau_go_rest_client.dart';
import 'di_container.config.dart';

final getIt = GetIt.instance;

@InjectableInit(asExtension: false)
Future<void> initDi(String flavor) async {
  await init(
    getIt,
    environmentFilter: NoEnvOrContains(flavor),
  );

  getIt.registerSingleton<AktauGoRestClient>(
    AktauGoRestClient(
      getIt<Dio>(),
    ),
  );

  return getIt.allReady();
}
