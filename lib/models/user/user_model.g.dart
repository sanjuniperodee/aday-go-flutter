// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: UserModel._propsToString(json['_id'] as Map<String, dynamic>?),
      props: json['props'] == null
          ? null
          : UserPropsModel.fromJson(json['props'] as Map<String, dynamic>),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      rating: json['rating'] as num?,
      earnings: json['earnings'] == null
          ? null
          : EarningsModel.fromJson(json['earnings'] as Map<String, dynamic>),
      orders: json['orders'] == null
          ? null
          : EarningsModel.fromJson(json['orders'] as Map<String, dynamic>),
      ratedOrders: (json['ratedOrders'] as List<dynamic>?)
          ?.map((e) => OrderRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      '_id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phone': instance.phone,
      'props': instance.props,
      'rating': instance.rating,
      'earnings': instance.earnings,
      'orders': instance.orders,
      'ratedOrders': instance.ratedOrders,
    };
