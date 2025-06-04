import 'package:aktau_go/domains/food/foods_response_domain.dart';
import 'package:aktau_go/models/food/foods_response_model.dart';
import 'package:aktau_go/models/food/mapper/food_category_mapper.dart';
import 'package:aktau_go/models/food/mapper/food_mapper.dart';

FoodsResponseDomain foodsResponseMapper(
  FoodsResponseModel model,
) =>
    FoodsResponseDomain(
      items: foodListMapper(model.items ?? []),
      folders: foodCategoryListMapper(model.folders ?? []),
    );
