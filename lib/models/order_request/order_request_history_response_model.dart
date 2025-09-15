import 'package:json_annotation/json_annotation.dart';
import 'package:aktau_go/models/order_request/order_request_history_model.dart';
import 'package:aktau_go/models/user/user_model.dart';

part 'order_request_history_response_model.g.dart';

@JsonSerializable()
class OrderRequestHistoryResponseModel {
  final UserModel? whatsappUser;
  final UserModel? driver;
  final OrderRequestHistoryModel? orderRequest;

  const OrderRequestHistoryResponseModel({
    this.whatsappUser,
    this.driver,
    this.orderRequest,
  });

  factory OrderRequestHistoryResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestHistoryResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderRequestHistoryResponseModelToJson(this);
}