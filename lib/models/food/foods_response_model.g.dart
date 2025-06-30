// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foods_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodsResponseModel _$FoodsResponseModelFromJson(Map<String, dynamic> json) =>
    FoodsResponseModel(
      folders: (json['folders'] as List<dynamic>?)
          ?.map((e) => FoodCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FoodsResponseModelToJson(FoodsResponseModel instance) =>
    <String, dynamic>{
      'folders': instance.folders,
      'items': instance.items,
    };
