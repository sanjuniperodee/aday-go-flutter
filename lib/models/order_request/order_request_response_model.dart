import 'package:aktau_go/models/order_request/order_request_model.dart';
import 'package:aktau_go/models/user/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_request_response_model.g.dart';

@JsonSerializable()
class OrderRequestResponseModel {
  final UserModel? user;
  final OrderRequestModel? orderRequest;

  const OrderRequestResponseModel({
    this.user,
    this.orderRequest,
  });

  factory OrderRequestResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderRequestResponseModelToJson(this);
}
