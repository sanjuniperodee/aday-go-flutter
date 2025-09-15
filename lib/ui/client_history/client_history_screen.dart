import 'package:aktau_go/ui/history/widgets/history_order_card.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter_svg/svg.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../domains/active_request/active_request_domain.dart';
import '../../forms/driver_registration_form.dart';
import '../widgets/text_locale.dart';
import 'client_history_wm.dart';

class ClientHistoryScreen extends ElementaryWidget<IClientHistoryWM> {
  ClientHistoryScreen({
    Key? key,
  }) : super(
          (context) => defaultClientHistoryWMFactory(context),
        );

  @override
  Widget build(IClientHistoryWM wm) {
    return StateNotifierBuilder(
        listenableState: wm.orderHistoryRequests,
        builder: (
          context,
          List<ActiveRequestDomain>? orderHistoryRequests,
        ) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'История поездок',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: wm.fetchOrderClientHistoryRequests,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Убираем выбор категорий - автоматически показываем только такси
                  
                  // Список заказов
                  if ((orderHistoryRequests ?? []).isEmpty)
                    Container(
                      padding: EdgeInsets.all(40),
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
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'История пуста',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Завершенные и отмененные поездки появятся здесь',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...orderHistoryRequests!.map(
                      (order) => Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: HistoryOrderCard(orderRequest: order),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
  }
}
