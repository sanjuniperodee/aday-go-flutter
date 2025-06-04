import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';

import '../../forms/driver_registration_form.dart';
import '../../interactors/order_requests_interactor.dart';
import '../../utils/logger.dart';
import 'client_history_model.dart';
import 'client_history_screen.dart';

defaultClientHistoryWMFactory(BuildContext context) =>
    ClientHistoryWM(ClientHistoryModel(
      inject<OrderRequestsInteractor>(),
    ));

abstract class IClientHistoryWM implements IWidgetModel {
  StateNotifier<int> get tabIndex;

  StateNotifier<DriverType> get orderType;

  StateNotifier<List<ActiveRequestDomain>> get orderHistoryRequests;

  void tabIndexChanged(int tabIndex);

  Future<void> fetchOrderClientHistoryRequests();
}

class ClientHistoryWM
    extends WidgetModel<ClientHistoryScreen, ClientHistoryModel>
    implements IClientHistoryWM {
  ClientHistoryWM(
    ClientHistoryModel model,
  ) : super(model);

  @override
  final StateNotifier<int> tabIndex = StateNotifier(initValue: 0);

  @override
  final StateNotifier<DriverType> orderType = StateNotifier(
    initValue: DriverType.TAXI,
  );

  @override
  final StateNotifier<List<ActiveRequestDomain>> orderHistoryRequests =
      StateNotifier(
    initValue: const [],
  );

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    fetchOrderClientHistoryRequests();
  }

  @override
  void tabIndexChanged(int tabIndex) {
    this.tabIndex.accept(tabIndex);
    orderType.accept(DriverType.values[tabIndex]);
    fetchOrderClientHistoryRequests();
  }

  @override
  Future<void> fetchOrderClientHistoryRequests() async {
    try {
      final response = await model.getClientHistoryOrders(
        type: orderType.value!.key!,
      );
      orderHistoryRequests.accept(response);
    } on Exception catch (e) {
      logger.e(e);
    }
  }
}
