import 'package:aktau_go/models/order_request/order_request_model.dart';
import 'package:json_annotation/json_annotation.dart';

import '../earnings/earnings_model.dart';
import './user_props_model.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(
    name: '_id',
    fromJson: _propsToString,
  )
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final UserPropsModel? props;
  final num? rating;
  final EarningsModel? earnings;
  final EarningsModel? orders;
  final List<OrderRequestModel>? ratedOrders;

  const UserModel({
    this.id,
    this.props,
    this.firstName,
    this.lastName,
    this.phone,
    this.rating,
    this.earnings,
    this.orders,
    this.ratedOrders,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  static _propsToString(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return json['props']['value'];
  }
}
