import 'package:aktau_go/interactors/order_requests_interactor.dart';
import 'package:elementary/elementary.dart';

import '../../domains/active_request/active_request_domain.dart';

class HistoryModel extends ElementaryModel {
  final OrderRequestsInteractor _orderRequsetInteractor;

  HistoryModel(
    this._orderRequsetInteractor,
  ) : super();

  Future<List<ActiveRequestDomain>> getHistoryOrders({
    required String type,
  }) =>
      _orderRequsetInteractor.getHistoryOrders(
        type: type,
      );
}
