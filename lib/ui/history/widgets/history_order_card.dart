import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/text_styles.dart';

class HistoryOrderCard extends StatelessWidget {
  final ActiveRequestDomain orderRequest;

  const HistoryOrderCard({
    super.key,
    required this.orderRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: ShapeDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                                "https://via.placeholder.com/40x40"),
                            fit: BoxFit.cover,
                          ),
                          shape: OvalBorder(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(orderRequest.driver?.id ?? '').isNotEmpty ?  '${orderRequest.driver?.firstName} ${orderRequest.driver?.lastName}' : orderRequest.whatsappUser?.fullName ?? ''}',
                              textAlign: TextAlign.center,
                              style: text400Size16Black,
                            ),
                            Text(
                              (orderRequest.driver?.id ?? '').isNotEmpty ? 'Водитель' :'Клиент',
                              textAlign: TextAlign.center,
                              style: text400Size12Greyscale50,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${DateFormat('dd MMMM yyyy').format(orderRequest.orderRequest!.createdAt!)}',
                          textAlign: TextAlign.center,
                          style: text400Size16Black,
                        ),
                        Text(
                          NumUtils.humanizeNumber(
                                orderRequest.orderRequest?.price,
                                isCurrency: true,
                              ) ??
                              '',
                          textAlign: TextAlign.center,
                          style: text400Size12Greyscale50,
                        ),
                        Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                [
                                  if (orderRequest.orderRequest!.differenceInMinutes / 60 > 0)
                                  '${orderRequest.orderRequest!.differenceInMinutes ~/ 60} часов ',
                                  if (orderRequest.orderRequest!.differenceInMinutes % 60 > 0)
                                  '${orderRequest.orderRequest!.differenceInMinutes % 60}',
                            'минут в пути'
                                ].join(' '),

                                textAlign: TextAlign.center,
                                style: text400Size10Greyscale60,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Откуда',
                          textAlign: TextAlign.center,
                          style: text400Size12Greyscale60,
                        ),
                        Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                child: SvgPicture.asset(
                                    'assets/icons/placemark.svg'),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${orderRequest.orderRequest?.from ?? ''}',
                                  textAlign: TextAlign.center,
                                  style: text500Size12Greyscale90,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: SvgPicture.asset('assets/icons/dashed.svg'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Куда',
                          textAlign: TextAlign.center,
                          style: text400Size12Greyscale60,
                        ),
                        Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                child: SvgPicture.asset(
                                    'assets/icons/placemark.svg'),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${orderRequest.orderRequest?.to ?? ''}',
                                  textAlign: TextAlign.center,
                                  style: text500Size12Greyscale90,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '№ заказа',
                        textAlign: TextAlign.center,
                        style: text400Size10Greyscale60,
                      ),
                      Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${orderRequest.orderRequest?.id.split('-').first}',
                              textAlign: TextAlign.center,
                              style: text400Size16Black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Статус',
                        textAlign: TextAlign.center,
                        style: text400Size10Greyscale60,
                      ),
                      Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Завершён',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF44BC50),
                                fontSize: 10,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
