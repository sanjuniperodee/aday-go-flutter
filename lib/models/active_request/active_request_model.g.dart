// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveRequestModel _$ActiveRequestModelFromJson(Map<String, dynamic> json) =>
    ActiveRequestModel(
      driver: json['driver'] == null
          ? null
          : UserModel.fromJson(json['driver'] as Map<String, dynamic>),
      whatsappUser: json['whatsappUser'] == null
          ? null
          : UserModel.fromJson(json['whatsappUser'] as Map<String, dynamic>),
      orderRequest: json['orderRequest'] == null
          ? null
          : OrderRequestModel.fromJson(
              json['orderRequest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ActiveRequestModelToJson(ActiveRequestModel instance) =>
    <String, dynamic>{
      'whatsappUser': instance.whatsappUser,
      'driver': instance.driver,
      'orderRequest': instance.orderRequest,
    };
