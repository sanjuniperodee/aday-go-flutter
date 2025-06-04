import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/models/order_request/mapper/order_request_mapper.dart';
import 'package:aktau_go/models/user/user_model.dart';

UserDomain userMapper(
  UserModel model,
) =>
    UserDomain(
      id: model.id,
      phone: model.props?.phone,
      name: model.props?.name,
      firstName: model.props?.firstName,
      lastName: model.props?.lastName,
      middleName: model.props?.middleName,
      session: model.props?.session,
      rating: model.rating,
      today: model.earnings?.today,
      thisWeek: model.earnings?.thisWeek,
      thisMonth: model.earnings?.thisMonth,
      ordersToday: model.orders?.today,
      ordersThisWeek: model.orders?.thisWeek,
      ordersThisMonth: model.orders?.thisMonth,
      ratedOrders: (model.ratedOrders ?? [])
          .map((e) => orderRequestMapper(
                e,
                UserModel(),
              ))
          .toList(),
    );
