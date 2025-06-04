import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';

import '../../forms/driver_registration_form.dart';
import '../../interactors/order_requests_interactor.dart';
import '../../utils/logger.dart';
import 'history_model.dart';
import 'history_screen.dart';

defaultHistoryWMFactory(BuildContext context) => HistoryWM(HistoryModel(
      inject<OrderRequestsInteractor>(),
    ));

abstract class IHistoryWM implements IWidgetModel {
  StateNotifier<int> get tabIndex;

  StateNotifier<DriverType> get orderType;

  StateNotifier<List<ActiveRequestDomain>> get orderHistoryRequests;

  void tabIndexChanged(int tabIndex);

  Future<void> fetchOrderHistoryRequests();
}

class HistoryWM extends WidgetModel<HistoryScreen, HistoryModel>
    implements IHistoryWM {
  HistoryWM(
    HistoryModel model,
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
    fetchOrderHistoryRequests();
  }

  @override
  void tabIndexChanged(int tabIndex) {
    this.tabIndex.accept(tabIndex);
    orderType.accept(DriverType.values[tabIndex]);
    fetchOrderHistoryRequests();
  }

  @override
  Future<void> fetchOrderHistoryRequests() async {
    try {
      final response = await model.getHistoryOrders(
        type: orderType.value!.key!,
      );
      orderHistoryRequests.accept(response);
    } on Exception catch (e) {
      logger.e(e);
    }
  }
}
