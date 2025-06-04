import 'package:json_annotation/json_annotation.dart';

import '../../forms/driver_registration_form.dart';

part 'driver_registered_category_model.g.dart';

@JsonSerializable()
class DriverRegisteredCategoryModel {
  final String? id;
  final String? driverId;
  @JsonKey(unknownEnumValue: DriverType.TAXI)
  final DriverType? categoryType;
  final String? brand;
  final String? model;
  final String? number;
  final String? color;
  final String? SSN;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const DriverRegisteredCategoryModel({
    this.id,
    this.driverId,
    this.categoryType,
    this.brand,
    this.model,
    this.number,
    this.color,
    this.SSN,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory DriverRegisteredCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$DriverRegisteredCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$DriverRegisteredCategoryModelToJson(this);
}
