import 'package:aktau_go/interactors/order_requests_interactor.dart';
import 'package:elementary/elementary.dart';

import '../../domains/active_request/active_request_domain.dart';

class ClientHistoryModel extends ElementaryModel {
  final OrderRequestsInteractor _orderRequsetInteractor;

  ClientHistoryModel(
    this._orderRequsetInteractor,
  ) : super();

  Future<List<ActiveRequestDomain>> getClientHistoryOrders({
    required String type,
  }) =>
      _orderRequsetInteractor.getClientHistoryOrders(
        type: type,
      );
}
