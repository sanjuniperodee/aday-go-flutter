class FoodCategoryDomain {
  final int id;
  final String name;

  const FoodCategoryDomain({
    int? id,
    String? name,
  })  : id = id ?? -1,
        name = name ?? '';
}
