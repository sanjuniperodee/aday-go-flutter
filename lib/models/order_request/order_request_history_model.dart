import 'package:json_annotation/json_annotation.dart';

part 'order_request_history_model.g.dart';

@JsonSerializable()
class OrderRequestHistoryModel {
  final String? id;
  final String? driverId;
  final String? clientId;
  final String? orderType;
  final String? from;
  final String? to;
  final String? startTime;
  final String? arrivalTime;
  final double? lat;
  final double? lng;
  final double? price;
  final String? comment;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int? rating;
  final String? orderStatus;
  final String? fromMapboxId;
  final String? toMapboxId;

  const OrderRequestHistoryModel({
    this.id,
    this.driverId,
    this.clientId,
    this.orderType,
    this.from,
    this.to,
    this.startTime,
    this.arrivalTime,
    this.lat,
    this.lng,
    this.price,
    this.comment,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.rating,
    this.orderStatus,
    this.fromMapboxId,
    this.toMapboxId,
  });

  factory OrderRequestHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderRequestHistoryModelToJson(this);
}
