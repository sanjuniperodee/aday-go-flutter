// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_request_history_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderRequestHistoryResponseModel _$OrderRequestHistoryResponseModelFromJson(
        Map<String, dynamic> json) =>
    OrderRequestHistoryResponseModel(
      whatsappUser: json['whatsappUser'] == null
          ? null
          : UserModel.fromJson(json['whatsappUser'] as Map<String, dynamic>),
      driver: json['driver'] == null
          ? null
          : UserModel.fromJson(json['driver'] as Map<String, dynamic>),
      orderRequest: json['orderRequest'] == null
          ? null
          : OrderRequestHistoryModel.fromJson(
              json['orderRequest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderRequestHistoryResponseModelToJson(
        OrderRequestHistoryResponseModel instance) =>
    <String, dynamic>{
      'whatsappUser': instance.whatsappUser,
      'driver': instance.driver,
      'orderRequest': instance.orderRequest,
    };
