import 'package:aktau_go/domains/food/food_category_domain.dart';
import 'package:aktau_go/models/food/food_category_model.dart';

FoodCategoryDomain foodCategoryMapper(
  FoodCategoryModel model,
) =>
    FoodCategoryDomain(
      id: model.id,
      name: model.name,
    );

List<FoodCategoryDomain> foodCategoryListMapper(
  List<FoodCategoryModel> list,
) =>
    list.map((e) => foodCategoryMapper(e)).toList();
