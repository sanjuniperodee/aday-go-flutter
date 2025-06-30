// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarModel _$CarModelFromJson(Map<String, dynamic> json) => CarModel(
      id: json['id'] as String?,
      props: json['props'] == null
          ? null
          : CarPropsModel.fromJson(json['props'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CarModelToJson(CarModel instance) => <String, dynamic>{
      'id': instance.id,
      'props': instance.props,
    };

CarPropsModel _$CarPropsModelFromJson(Map<String, dynamic> json) =>
    CarPropsModel(
      SSN: json['SSN'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      number: json['number'] as String?,
    );

Map<String, dynamic> _$CarPropsModelToJson(CarPropsModel instance) =>
    <String, dynamic>{
      'SSN': instance.SSN,
      'brand': instance.brand,
      'model': instance.model,
      'color': instance.color,
      'number': instance.number,
    };
