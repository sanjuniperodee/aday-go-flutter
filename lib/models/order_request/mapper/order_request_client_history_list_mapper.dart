import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/models/order_request/order_request_history_response_model.dart';
import 'package:aktau_go/models/order_request/mapper/order_request_client_history_mapper.dart';

List<ActiveRequestDomain> orderRequestClientHistoryListMapper(
  List<OrderRequestHistoryResponseModel> models,
) =>
    models.map((model) => orderRequestClientHistoryMapper(
      model.orderRequest!,
      model.driver, // Для клиентской истории это водитель
    )).toList();
