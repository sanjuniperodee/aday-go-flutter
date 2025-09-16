import 'package:aktau_go/models/order_request/order_request_model.dart';
import 'package:aktau_go/models/user/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

import '../car/car_model.dart';
import '../order_request/order_request_client_model.dart';
import '../props/props_model.dart';

part 'active_client_request_model.g.dart';

@JsonSerializable()
class ActiveClientRequestModel {
  final OrderRequestClientModel? order;
  final UserModel? driver;
  final CarModel? car;

  const ActiveClientRequestModel({
    this.order,
    this.driver,
    this.car,
  });

  factory ActiveClientRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ActiveClientRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveClientRequestModelToJson(this);
}
