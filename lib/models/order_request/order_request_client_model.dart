import 'package:json_annotation/json_annotation.dart';

part 'order_request_client_model.g.dart';

@JsonSerializable()
class OrderRequestClientModel {
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? driverId;
  final String? clientId;
  final String? user_phone;
  final String? orderType;
  final String? orderStatus;
  final String? from;
  final String? to;
  final String? fromMapboxId;
  final String? toMapboxId;
  final DateTime? startTime;
  final DateTime? arrivalTime;
  final double? lat;
  final double? lng;
  final int? price;
  final String? comment;
  final double? rating;
  final String? sessionid;

  const OrderRequestClientModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.driverId,
    this.clientId,
    this.user_phone,
    this.orderType,
    this.orderStatus,
    this.from,
    this.to,
    this.fromMapboxId,
    this.toMapboxId,
    this.startTime,
    this.arrivalTime,
    this.lat,
    this.lng,
    this.price,
    this.comment,
    this.rating,
    this.sessionid,
  });

  factory OrderRequestClientModel.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestClientModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderRequestClientModelToJson(this);
}
