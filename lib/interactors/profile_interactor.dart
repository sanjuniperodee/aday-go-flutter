import 'package:aktau_go/domains/driver_registered_category/driver_registered_category_domain.dart';
import 'package:aktau_go/models/driver_registered_category/mapper/driver_registered_category_mapper.dart';
import 'package:injectable/injectable.dart';

import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/models/user/mapper/user_mapper.dart';

import '../domains/user/user_domain.dart';

abstract class IProfileInteractor {
  Future<UserDomain> fetchUserProfile();

  Future<List<DriverRegisteredCategoryDomain>>
      fetchDriverRegisteredCategories();
}

@singleton
class ProfileInteractor extends IProfileInteractor {
  final RestClient _restClient;

  ProfileInteractor(this._restClient);

  @override
  Future<UserDomain> fetchUserProfile() async =>
      userMapper(await _restClient.getUserProfile());

  @override
  Future<List<DriverRegisteredCategoryDomain>>
      fetchDriverRegisteredCategories() async =>
          driverRegisteredCategoryListMapper(
              await _restClient.driverRegisteredCategories());
}
