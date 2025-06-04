import 'package:json_annotation/json_annotation.dart';

part 'food_category_model.g.dart';

@JsonSerializable()
class FoodCategoryModel {
  @JsonKey(name: 'ID')
  final int? id;

  @JsonKey(name: 'NAME')
  final String? name;

  const FoodCategoryModel({
    this.id,
    this.name,
  });

  factory FoodCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$FoodCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$FoodCategoryModelToJson(this);
}
