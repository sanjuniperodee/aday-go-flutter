// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_request_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderRequestHistoryModel _$OrderRequestHistoryModelFromJson(
        Map<String, dynamic> json) =>
    OrderRequestHistoryModel(
      id: json['id'] as String?,
      driverId: json['driverId'] as String?,
      clientId: json['clientId'] as String?,
      orderType: json['orderType'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      startTime: json['startTime'] as String?,
      arrivalTime: json['arrivalTime'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      deletedAt: json['deletedAt'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      orderStatus: json['orderStatus'] as String?,
      fromMapboxId: json['fromMapboxId'] as String?,
      toMapboxId: json['toMapboxId'] as String?,
    );

Map<String, dynamic> _$OrderRequestHistoryModelToJson(
        OrderRequestHistoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driverId': instance.driverId,
      'clientId': instance.clientId,
      'orderType': instance.orderType,
      'from': instance.from,
      'to': instance.to,
      'startTime': instance.startTime,
      'arrivalTime': instance.arrivalTime,
      'lat': instance.lat,
      'lng': instance.lng,
      'price': instance.price,
      'comment': instance.comment,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'deletedAt': instance.deletedAt,
      'rating': instance.rating,
      'orderStatus': instance.orderStatus,
      'fromMapboxId': instance.fromMapboxId,
      'toMapboxId': instance.toMapboxId,
    };
