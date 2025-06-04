import 'package:aktau_go/models/food/food_category_model.dart';
import 'package:aktau_go/models/food/food_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foods_response_model.g.dart';

@JsonSerializable()
class FoodsResponseModel {
  final List<FoodCategoryModel>? folders;
  final List<FoodModel>? items;

  const FoodsResponseModel({
    this.folders,
    this.items,
  });

  factory FoodsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FoodsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$FoodsResponseModelToJson(this);
}
