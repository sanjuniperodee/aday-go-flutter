import 'package:aktau_go/forms/driver_registration_form.dart';

class DriverRegisteredCategoryDomain {
  final String id;
  final String driverId;
  final DriverType categoryType;
  final String brand;
  final String model;
  final String number;
  final String color;
  final String sSN;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const DriverRegisteredCategoryDomain({
    String? id,
    String? driverId,
    DriverType? categoryType,
    String? brand,
    String? model,
    String? number,
    String? color,
    String? SSN,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  })  : id = id ?? '',
        driverId = driverId ?? '',
        categoryType = categoryType ?? DriverType.TAXI,
        brand = brand ?? '',
        model = model ?? '',
        number = number ?? '',
        color = color ?? '',
        sSN = SSN ?? '';
}
