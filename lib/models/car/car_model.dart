import 'package:json_annotation/json_annotation.dart';

part 'car_model.g.dart';

@JsonSerializable()
class CarModel {
  final String? id;
  final CarPropsModel? props;

  const CarModel({
    this.id,
    this.props,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) =>
      _$CarModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarModelToJson(this);
}

@JsonSerializable()
class CarPropsModel {
  final String? SSN;
  final String? brand;
  final String? model;
  final String? color;
  final String? number;

  const CarPropsModel({
    this.SSN,
    this.brand,
    this.model,
    this.color,
    this.number,
  });

  factory CarPropsModel.fromJson(Map<String, dynamic> json) =>
      _$CarPropsModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarPropsModelToJson(this);
}
