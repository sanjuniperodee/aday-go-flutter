class FoodDomain {
  final int id;
  final int parentId;
  final String name;
  final int price;
  final String description;
  final String edizm;
  final int useDisc;

  FoodDomain({
    int? id,
    int? parentId,
    String? name,
    int? price,
    String? description,
    String? edizm,
    int? useDisc,
  })  : id = id ?? -1,
        parentId = parentId ?? -1,
        name = name ?? '',
        price = price ?? 0,
        description = description ?? '',
        edizm = edizm ?? '',
        useDisc = useDisc ?? -1;
}
