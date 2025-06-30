// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_request_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderRequestResponseModel _$OrderRequestResponseModelFromJson(
        Map<String, dynamic> json) =>
    OrderRequestResponseModel(
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      orderRequest: json['orderRequest'] == null
          ? null
          : OrderRequestModel.fromJson(
              json['orderRequest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderRequestResponseModelToJson(
        OrderRequestResponseModel instance) =>
    <String, dynamic>{
      'user': instance.user,
      'orderRequest': instance.orderRequest,
    };
