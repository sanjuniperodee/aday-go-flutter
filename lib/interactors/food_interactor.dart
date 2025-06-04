import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/models/food/mapper/foods_response_mapper.dart';

import '../domains/food/foods_response_domain.dart';

import 'package:injectable/injectable.dart';

abstract class IFoodInteractor {
  Future<FoodsResponseDomain> fetchFoods();
}

@singleton
class FoodInteractor extends IFoodInteractor {
  final RestClient _restClient;

  FoodInteractor(
    this._restClient,
  );

  @override
  Future<FoodsResponseDomain> fetchFoods() async =>
      foodsResponseMapper(await _restClient.fetchFoods());
}
