import 'package:json_annotation/json_annotation.dart';

part 'food_model.g.dart';

@JsonSerializable()
class FoodModel {
  @JsonKey(name: 'ID')
  int? id;
  @JsonKey(name: 'PID')
  int? parentId;
  @JsonKey(name: 'NAME')
  String? name;
  @JsonKey(name: 'MCENA')
  int? price;
  @JsonKey(name: 'DESCR')
  String? description;
  @JsonKey(name: 'EDIZM')
  String? edizm;
  @JsonKey(name: 'USEDISC')
  int? useDisc;

  FoodModel({
    this.id,
    this.parentId,
    this.name,
    this.price,
    this.description,
    this.edizm,
    this.useDisc,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) =>
      _$FoodModelFromJson(json);

  Map<String, dynamic> toJson() => _$FoodModelToJson(this);
}
