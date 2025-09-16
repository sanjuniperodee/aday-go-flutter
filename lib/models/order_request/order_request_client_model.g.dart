// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_request_client_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderRequestClientModel _$OrderRequestClientModelFromJson(
        Map<String, dynamic> json) =>
    OrderRequestClientModel(
      id: json['id'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      driverId: json['driverId'] as String?,
      clientId: json['clientId'] as String?,
      user_phone: json['user_phone'] as String?,
      orderType: json['orderType'] as String?,
      orderStatus: json['orderStatus'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      fromMapboxId: json['fromMapboxId'] as String?,
      toMapboxId: json['toMapboxId'] as String?,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      arrivalTime: json['arrivalTime'] == null
          ? null
          : DateTime.parse(json['arrivalTime'] as String),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      sessionid: json['sessionid'] as String?,
    );

Map<String, dynamic> _$OrderRequestClientModelToJson(
        OrderRequestClientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'driverId': instance.driverId,
      'clientId': instance.clientId,
      'user_phone': instance.user_phone,
      'orderType': instance.orderType,
      'orderStatus': instance.orderStatus,
      'from': instance.from,
      'to': instance.to,
      'fromMapboxId': instance.fromMapboxId,
      'toMapboxId': instance.toMapboxId,
      'startTime': instance.startTime?.toIso8601String(),
      'arrivalTime': instance.arrivalTime?.toIso8601String(),
      'lat': instance.lat,
      'lng': instance.lng,
      'price': instance.price,
      'comment': instance.comment,
      'rating': instance.rating,
      'sessionid': instance.sessionid,
    };
