import 'package:aktau_go/domains/driver_registered_category/driver_registered_category_domain.dart';
import 'package:aktau_go/models/driver_registered_category/driver_registered_category_model.dart';

DriverRegisteredCategoryDomain driverRegisteredCategoryMapper(
  DriverRegisteredCategoryModel model,
) =>
    DriverRegisteredCategoryDomain(
      id: model.id,
      driverId: model.driverId,
      categoryType: model.categoryType,
      brand: model.brand,
      model: model.model,
      number: model.number,
      color: model.color,
      SSN: model.SSN,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
    );

List<DriverRegisteredCategoryDomain> driverRegisteredCategoryListMapper(
  List<DriverRegisteredCategoryModel> list,
) =>
    list.map((e) => driverRegisteredCategoryMapper(e)).toList();
