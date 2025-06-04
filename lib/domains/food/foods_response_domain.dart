import './food_category_domain.dart';
import './food_domain.dart';

class FoodsResponseDomain {
  final List<FoodCategoryDomain> folders;
  final List<FoodDomain> items;

  const FoodsResponseDomain({
    List<FoodCategoryDomain>? folders,
    List<FoodDomain>? items,
  })  : folders = folders ?? const [],
        items = items ?? const [];
}
