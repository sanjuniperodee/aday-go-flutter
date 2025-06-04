import 'package:aktau_go/domains/food/food_domain.dart';
import 'package:aktau_go/models/food/food_model.dart';

FoodDomain foodMapper(
  FoodModel model,
) =>
    FoodDomain(
      id: model.id,
      parentId: model.parentId,
      name: model.name,
      price: model.price,
      description: model.description,
      edizm: model.edizm,
      useDisc: model.useDisc,
    );

List<FoodDomain> foodListMapper(
  List<FoodModel> list,
) =>
    list.map((e) => foodMapper(e)).toList();
