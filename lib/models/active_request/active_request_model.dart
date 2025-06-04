import 'package:aktau_go/models/order_request/order_request_model.dart';
import 'package:aktau_go/models/user/user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'active_request_model.g.dart';

@JsonSerializable()
class ActiveRequestModel {
  final UserModel? whatsappUser;
  final UserModel? driver;
  final OrderRequestModel? orderRequest;

  const ActiveRequestModel({
    this.driver,
    this.whatsappUser,
    this.orderRequest,
  });

  factory ActiveRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ActiveRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveRequestModelToJson(this);
}
