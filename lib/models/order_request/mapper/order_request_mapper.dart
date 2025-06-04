import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/models/order_request/order_request_model.dart';
import 'package:aktau_go/models/user/mapper/user_mapper.dart';
import 'package:aktau_go/models/user/user_model.dart';

import '../order_request_response_model.dart';

OrderRequestDomain orderRequestMapper(
  OrderRequestModel model,
  UserModel? userModel,
) =>
    OrderRequestDomain(
      id: model.id,
      createdAt: model.props?.createdAt,
      updatedAt: model.props?.updatedAt,
      startTime: model.props?.startTime,
      arrivalTime: model.props?.arrivalTime,
      driverId: model.props?.driverId,
      user_phone: model.props?.user_phone,
      orderType: model.props?.orderType,
      orderStatus: model.props?.orderStatus,
      from: model.props?.from,
      to: model.props?.to,
      fromMapboxId: model.props?.fromMapboxId,
      toMapboxId: model.props?.toMapboxId,
      lat: model.props?.lat,
      lng: model.props?.lng,
      price: model.props?.price,
      comment: model.props?.comment,
      rating: model.props?.rating,
      sessionid: model.props?.sessionid,
      user: userModel != null ? userMapper(userModel) : null,
    );

List<OrderRequestDomain> orderRequestListMapper(
  List<OrderRequestResponseModel> list,
) =>
    list
        .map(
          (e) => orderRequestMapper(
            e.orderRequest!,
            e.user,
          ),
        )
        .toList();
