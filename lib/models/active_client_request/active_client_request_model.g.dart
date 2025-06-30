// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_client_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveClientRequestModel _$ActiveClientRequestModelFromJson(
        Map<String, dynamic> json) =>
    ActiveClientRequestModel(
      order: json['order'] == null
          ? null
          : OrderRequestPropsModel.fromJson(
              json['order'] as Map<String, dynamic>),
      driver: json['driver'] == null
          ? null
          : UserModel.fromJson(json['driver'] as Map<String, dynamic>),
      car: json['car'] == null
          ? null
          : CarModel.fromJson(json['car'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ActiveClientRequestModelToJson(
        ActiveClientRequestModel instance) =>
    <String, dynamic>{
      'order': instance.order,
      'driver': instance.driver,
      'car': instance.car,
    };
