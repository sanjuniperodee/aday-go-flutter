import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/models/order_request/order_request_history_model.dart';
import 'package:aktau_go/models/user/mapper/user_mapper.dart';
import 'package:aktau_go/models/user/user_model.dart';

ActiveRequestDomain orderRequestClientHistoryMapper(
  OrderRequestHistoryModel model,
  UserModel? userModel,
) =>
    ActiveRequestDomain(
      whatsappUser: null, // Для истории клиента клиент не нужен
      driver: userModel != null ? userMapper(userModel) : null, // Для истории клиента это водитель
      orderRequest: OrderRequestDomain(
        id: model.id,
        createdAt: model.createdAt != null ? DateTime.parse(model.createdAt!) : null,
        updatedAt: model.updatedAt != null ? DateTime.parse(model.updatedAt!) : null,
        startTime: model.startTime != null ? DateTime.parse(model.startTime!) : null,
        arrivalTime: model.arrivalTime != null ? DateTime.parse(model.arrivalTime!) : null,
        driverId: model.driverId,
        user_phone: null,
        orderType: model.orderType,
        orderStatus: model.orderStatus,
        from: model.from,
        to: model.to,
        fromMapboxId: model.fromMapboxId,
        toMapboxId: model.toMapboxId,
        lat: model.lat,
        lng: model.lng,
        price: model.price,
        comment: model.comment,
        rating: model.rating,
        sessionid: null,
        user: userModel != null ? userMapper(userModel) : null,
      ),
    );
