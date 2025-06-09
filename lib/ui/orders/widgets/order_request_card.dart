import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/colors.dart';
import '../../../core/text_styles.dart';

class OrderRequestCard extends StatelessWidget {
  final OrderRequestDomain orderRequest;

  const OrderRequestCard({
    super.key,
    required this.orderRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            // Левая часть - аватар и информация о клиенте
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(
                Icons.person,
                color: primaryColor,
                size: 20,
              ),
            ),
            
            SizedBox(width: 10),
            
            // Средняя часть - маршрут и детали
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Имя клиента и время
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${orderRequest.user?.firstName ?? ''} ${orderRequest.user?.lastName ?? ''}'.trim(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(orderRequest.createdAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 6),
                  
                  // Компактный маршрут в одну строку
                  Row(
                    children: [
                      // Точка А
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                      ),
                      SizedBox(width: 5),
                      
                      // Откуда (сокращенно)
                      Flexible(
                        child: Text(
                          orderRequest.from,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 3),
                  
                  Row(
                    children: [
                      // Точка Б
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                      ),
                      SizedBox(width: 5),
                      
                      // Куда (сокращенно)
                      Flexible(
                        child: Text(
                          orderRequest.to,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Комментарий (если есть, но очень компактно)
                  if (orderRequest.comment.isNotEmpty) ...[
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.orange.shade600,
                          size: 10,
                        ),
                        SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            orderRequest.comment,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(width: 8),
            
            // Правая часть - стоимость и кнопка
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Стоимость
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200, width: 1),
                  ),
                  child: Text(
                    NumUtils.humanizeNumber(orderRequest.price, isCurrency: true) ?? '0 ₸',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                
                SizedBox(height: 6),
                
                // Кнопка принять
                Container(
                  width: 85,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      // Обработка нажатия происходит в orders_screen.dart
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Принять',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
