import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/models/order_request/order_request_history_response_model.dart';
import 'package:aktau_go/models/order_request/mapper/order_request_history_mapper.dart';
import 'package:aktau_go/models/user/mapper/user_mapper.dart';

List<ActiveRequestDomain> orderRequestHistoryListMapper(
  List<OrderRequestHistoryResponseModel> models,
) =>
    models.map((model) => orderRequestHistoryMapper(
      model.orderRequest!,
      model.whatsappUser ?? model.driver,
    )).toList();
