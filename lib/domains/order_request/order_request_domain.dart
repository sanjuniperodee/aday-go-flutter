import 'package:aktau_go/domains/user/user_domain.dart';

class OrderRequestDomain {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? startTime;
  final DateTime? arrivalTime;

  final String driverId;
  final String userPhone;
  final String orderType;
  final String orderStatus;
  final String from;
  final String to;
  final String fromMapboxId;
  final String toMapboxId;
  final num lat;
  final num lng;
  final num price;
  final String comment;
  final num rating;
  final String sessionid;
  final UserDomain? user;
  final int differenceInMinutes;

  OrderRequestDomain({
    String? id,
    this.createdAt,
    this.updatedAt,
    this.startTime,
    this.arrivalTime,
    String? driverId,
    String? user_phone,
    String? orderType,
    String? orderStatus,
    String? from,
    String? to,
    String? fromMapboxId,
    String? toMapboxId,
    num? lat,
    num? lng,
    num? price,
    String? comment,
    num? rating,
    String? sessionid,
    UserDomain? user,
  })  : id = id ?? '',
        driverId = driverId ?? '',
        userPhone = user_phone ?? '',
        orderType = orderType ?? '',
        orderStatus = orderStatus ?? '',
        from = from ?? '',
        to = to ?? '',
        fromMapboxId = (comment ?? '').split(';').length > 1
            ? '${(comment ?? '').split(';')[1]};${(comment ?? '').split(';')[2]}'
            : fromMapboxId ?? '',
        toMapboxId = (comment ?? '').split(';').length > 1
            ? '${(comment ?? '').split(';')[3]};${(comment ?? '').split(';')[4]}'
            : toMapboxId ?? '',
        lat = lat ?? 0,
        lng = lng ?? 0,
        price = price ?? 0,
        comment = (comment ?? '').split(';')[0],
        rating = rating ?? 0,
        sessionid = sessionid ?? '',
        differenceInMinutes = updatedAt?.difference(createdAt!).inMinutes ?? 0,
        user = user ?? const UserDomain();
}
