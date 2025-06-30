// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderRequestModel _$OrderRequestModelFromJson(Map<String, dynamic> json) =>
    OrderRequestModel(
      id: OrderRequestModel._propsToString(
          json['_id'] as Map<String, dynamic>?),
      props: json['props'] == null
          ? null
          : OrderRequestPropsModel.fromJson(
              json['props'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderRequestModelToJson(OrderRequestModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'props': instance.props,
    };
