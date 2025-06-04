import 'package:json_annotation/json_annotation.dart';

import 'order_request_props_model.dart';

part 'order_request_model.g.dart';

@JsonSerializable()
class OrderRequestModel {
  @JsonKey(
    name: '_id',
    fromJson: _propsToString,
  )
  final String? id;
  final OrderRequestPropsModel? props;

  const OrderRequestModel({
    this.id,
    this.props,
  });

  factory OrderRequestModel.fromJson(Map<String, dynamic> json) =>
      _$OrderRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderRequestModelToJson(this);

  static _propsToString(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return json['props']['value'];
  }
}
