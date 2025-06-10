import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:elementary/elementary.dart';

import '../../domains/active_request/active_request_domain.dart';
import '../../domains/order_request/order_request_domain.dart';
import '../../domains/user/user_domain.dart';
import '../../forms/driver_registration_form.dart';
import '../../interactors/order_requests_interactor.dart';

class OrdersModel extends ElementaryModel {
  final OrderRequestsInteractor _orderRequestsInteractor;
  final ProfileInteractor _profileInteractor;

  OrdersModel(
    this._orderRequestsInteractor,
    this._profileInteractor,
  ) : super();

  Future<List<OrderRequestDomain>> getOrderRequests({
    required DriverType type,
  }) =>
      _orderRequestsInteractor.getOrderRequests(
        type: type,
      );

  Future<UserDomain> getUserProfile() => _profileInteractor.fetchUserProfile();

  Future<void> acceptOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  }) =>
      _orderRequestsInteractor.acceptOrderRequest(
        driver: driver,
        orderRequest: orderRequest,
      );

  Future<ActiveRequestDomain> getActiveOrder() =>
      _orderRequestsInteractor.getActiveOrder();
}
