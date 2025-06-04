import 'package:injectable/injectable.dart';

import './flavor_service.dart';
import './flavor.dart';

@singleton
class FlavorInteractor implements FlavorService {
  @override
  Flavor currentFlavor;

  FlavorInteractor(
    this.currentFlavor,
  );
}
