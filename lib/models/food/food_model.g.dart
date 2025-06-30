// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodModel _$FoodModelFromJson(Map<String, dynamic> json) => FoodModel(
      id: (json['ID'] as num?)?.toInt(),
      parentId: (json['PID'] as num?)?.toInt(),
      name: json['NAME'] as String?,
      price: (json['MCENA'] as num?)?.toInt(),
      description: json['DESCR'] as String?,
      edizm: json['EDIZM'] as String?,
      useDisc: (json['USEDISC'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FoodModelToJson(FoodModel instance) => <String, dynamic>{
      'ID': instance.id,
      'PID': instance.parentId,
      'NAME': instance.name,
      'MCENA': instance.price,
      'DESCR': instance.description,
      'EDIZM': instance.edizm,
      'USEDISC': instance.useDisc,
    };
