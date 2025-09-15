import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/text_styles.dart';
import '../../../core/colors.dart';

class OrderRequestCard extends StatelessWidget {
  final OrderRequestDomain orderRequest;
  final VoidCallback? onAccept;

  const OrderRequestCard({
    super.key,
    required this.orderRequest,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with price and client info
                Row(
                  children: [
                    // Client avatar
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Client name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${orderRequest.user?.firstName ?? ''} ${orderRequest.user?.lastName ?? ''}',
                            style: text400Size16Black,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('HH:mm, dd MMM').format(orderRequest.createdAt!),
                            style: text400Size12Greyscale50,
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        NumUtils.humanizeNumber(orderRequest.price, isCurrency: true) ?? '',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Comment (if exists)
                if (orderRequest.comment.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      orderRequest.comment,
                      style: text400Size12Greyscale60,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                if (orderRequest.comment.isNotEmpty)
                  const SizedBox(height: 12),
                
                // Route information - вертикальный layout для лучшего отображения адресов
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Откуда',
                                style: text400Size10Greyscale60,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orderRequest.from,
                                style: text400Size12Greyscale90,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // To location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Куда',
                                style: text400Size10Greyscale60,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orderRequest.to,
                                style: text400Size12Greyscale90,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Accept button
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onAccept,
                      child: Center(
                        child: Text(
                          'Принять заказ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
