import 'package:aktau_go/models/props/props_model.dart';
import 'package:aktau_go/models/user/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_request_props_model.g.dart';

@JsonSerializable()
class OrderRequestPropsModel {
  @JsonKey(name: 'id', fromJson: _propsToString)
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  @JsonKey(name: 'driverId', fromJson: _propsToString)
  final String? driverId;
  @JsonKey(name: 'clientId', fromJson: _propsToString)
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
  final num? lat;
  final num? lng;
  final num? price;
  final String comment;
  final num? rating;
  final String? sessionid;

  OrderRequestPropsModel({
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
    String? comment,
    this.rating,
    this.sessionid,
  }) : comment = (comment ?? '').split(';')[0];

  factory OrderRequestPropsModel.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestPropsModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderRequestPropsModelToJson(this);

  static _propsToString(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return json['props']['value'];
  }
}
