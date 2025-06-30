// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_registered_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverRegisteredCategoryModel _$DriverRegisteredCategoryModelFromJson(
        Map<String, dynamic> json) =>
    DriverRegisteredCategoryModel(
      id: json['id'] as String?,
      driverId: json['driverId'] as String?,
      categoryType: $enumDecodeNullable(
          _$DriverTypeEnumMap, json['categoryType'],
          unknownValue: DriverType.TAXI),
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      number: json['number'] as String?,
      color: json['color'] as String?,
      SSN: json['SSN'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$DriverRegisteredCategoryModelToJson(
        DriverRegisteredCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driverId': instance.driverId,
      'categoryType': _$DriverTypeEnumMap[instance.categoryType],
      'brand': instance.brand,
      'model': instance.model,
      'number': instance.number,
      'color': instance.color,
      'SSN': instance.SSN,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

const _$DriverTypeEnumMap = {
  DriverType.TAXI: 'TAXI',
  DriverType.DELIVERY: 'DELIVERY',
  DriverType.INTERCITY_TAXI: 'INTERCITY_TAXI',
  DriverType.CARGO: 'CARGO',
};
