import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/models/active_request/mapper/active_request_mapper.dart';
import 'package:injectable/injectable.dart';
import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/models/order_request/mapper/order_request_mapper.dart';

import '../forms/driver_registration_form.dart';
import '../models/active_client_request/active_client_request_model.dart';
import '../models/active_request/active_request_model.dart';

abstract class IOrderRequestsInteractor {
  Future<List<OrderRequestDomain>> getOrderRequests({
    required DriverType type,
  });

  Future<void> acceptOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  });

  Future<void> arrivedOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  });

  Future<void> startOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  });

  Future<void> endOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  });

  Future<void> rejectOrderRequest({
    required String orderRequestId,
  });

  Future<void> rejectOrderByClientRequest({
    required String orderRequestId,
  });

  Future<ActiveRequestDomain?> getActiveOrder();

  Future<ActiveClientRequestModel> getMyClientActiveOrder();

  Future<List<ActiveRequestDomain>> getHistoryOrders({
    required String type,
  });

  Future<List<ActiveRequestDomain>> getClientHistoryOrders({
    required String type,
  });

  Future<void> rateDriver({
    required String orderId,
    required int rating,
    String? comment,
  });
}

@singleton
class OrderRequestsInteractor extends IOrderRequestsInteractor {
  final RestClient _restClient;

  OrderRequestsInteractor(
    RestClient restClient,
  ) : _restClient = restClient;

  @override
  Future<List<OrderRequestDomain>> getOrderRequests({
    required DriverType type,
  }) async =>
      orderRequestListMapper(await _restClient.getPendingOrderRequestsByType(
        type: type.key!,
      ));

  @override
  Future<void> acceptOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  }) =>
      _restClient.acceptOrderRequest(
        driverId: driver.id,
        orderRequestId: orderRequest.id,
      );

  @override
  Future<ActiveRequestDomain?> getActiveOrder() async {
    try {
      final response = await _restClient.getMyActiveOrder();
      return activeRequestMapper(response);
    } catch (e) {
      // Если сервер возвращает ошибку или "You dont have active order", возвращаем null
      print('❌ Ошибка получения активного заказа: $e');
      return null;
    }
  }

  @override
  Future<void> arrivedOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  }) =>
      _restClient.arrivedOrderRequest(
        driverId: driver.id,
        orderRequestId: orderRequest.id,
      );

  @override
  Future<void> endOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  }) =>
      _restClient.endOrderRequest(
        driverId: driver.id,
        orderRequestId: orderRequest.id,
      );

  @override
  Future<void> startOrderRequest({
    required UserDomain driver,
    required OrderRequestDomain orderRequest,
  }) =>
      _restClient.startOrderRequest(
        driverId: driver.id,
        orderRequestId: orderRequest.id,
      );

  @override
  Future<List<ActiveRequestDomain>> getHistoryOrders({
    required String type,
  }) async =>
      activeRequestListMapper(await _restClient.getHistoryOrders(
        type: type,
      ));

  @override
  Future<void> rejectOrderRequest({
    required String orderRequestId,
  }) =>
      _restClient.rejectOrderRequest(
        orderRequestId: orderRequestId,
      );

  Future<void> rejectOrderByClientRequest({
    required String orderRequestId,
  }) =>
      _restClient.rejectOrderByClientRequest(
        orderRequestId: orderRequestId,
      );

  @override
  Future<ActiveClientRequestModel> getMyClientActiveOrder() async =>
      await _restClient.getMyClientActiveOrder();

  @override
  Future<List<ActiveRequestDomain>> getClientHistoryOrders({
    required String type,
  }) async =>
      activeRequestListMapper(await _restClient.getClientHistoryOrders(
        type: type,
      ));

  @override
  Future<void> rateDriver({
    required String orderId,
    required int rating,
    String? comment,
  }) {
    final body = {
      'orderRequestId': orderId,
      'rating': rating,
    };
    
    // Добавляем комментарий только если он не пустой
    if (comment != null && comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    
    return _restClient.makeReview(body: body);
  }
}
