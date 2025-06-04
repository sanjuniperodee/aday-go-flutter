import 'package:aktau_go/domains/order_request/order_request_domain.dart';

class UserDomain {
  final String id;
  final String phone;
  final String name;
  final String session;
  final String firstName;
  final String lastName;
  final String middleName;
  final String fullName;

  final num rating;
  final num today;
  final num thisWeek;
  final num thisMonth;
  final num ordersToday;
  final num ordersThisWeek;
  final num ordersThisMonth;

  final List<OrderRequestDomain> ratedOrders;

  const UserDomain({
    String? id,
    String? phone,
    String? name,
    String? firstName,
    String? lastName,
    String? middleName,
    String? session,
    num? rating,
    num? today,
    num? thisWeek,
    num? thisMonth,
    num? ordersToday,
    num? ordersThisWeek,
    num? ordersThisMonth,
    List<OrderRequestDomain>? ratedOrders,
  })  : id = id ?? '',
        phone = phone ?? '',
        name = name ?? '',
        firstName = firstName ?? '',
        lastName = lastName ?? '',
        middleName = middleName ?? '',
        fullName = '${firstName ?? ''} ${lastName ?? ''} ${middleName ?? ''}',
        rating = rating ?? 0,
        today = today ?? 0,
        thisWeek = thisWeek ?? 0,
        thisMonth = thisMonth ?? 0,
        ordersToday = ordersToday ?? 0,
        ordersThisWeek = ordersThisWeek ?? 0,
        ordersThisMonth = ordersThisMonth ?? 0,
        session = session ?? '',
        ratedOrders = ratedOrders ?? const [];
}
