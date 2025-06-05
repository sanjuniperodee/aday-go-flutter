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
import 'history_wm.dart';

class HistoryScreen extends ElementaryWidget<IHistoryWM> {
  HistoryScreen({
    Key? key,
  }) : super(
          (context) => defaultHistoryWMFactory(context),
        );

  @override
  Widget build(IHistoryWM wm) {
    return DoubleSourceBuilder(
        firstSource: wm.tabIndex,
        secondSource: wm.orderHistoryRequests,
        builder: (
          context,
          int? tabIndex,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  color: greyscale10,
                ),
              ),
            ),
            body: Column(
              children: [
                // Фильтры по типу поездки
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                    children: [
                      ...DriverType.values.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: FilterChip(
                              selected: tabIndex == e.key,
                              showCheckmark: false,
                              backgroundColor: Colors.white,
                              selectedColor: primaryColor,
                              side: BorderSide(
                                color: tabIndex == e.key ? primaryColor : Colors.grey.shade300,
                                width: 1,
                              ),
                                  shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                  ),
                              label: Row(
                                  children: [
                                    SvgPicture.asset(
                                      e.value.asset!,
                                    color: tabIndex == e.key ? Colors.white : Colors.grey,
                                    width: 16,
                                    height: 16,
                                  ),
                                  SizedBox(width: 8),
                                    TextLocale(
                                      e.value.value!,
                                    style: TextStyle(
                                      color: tabIndex == e.key ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              onSelected: (_) => wm.tabIndexChanged(e.key),
                            ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                
                // Список заказов
                Expanded(
                  child: orderHistoryRequests == null || orderHistoryRequests.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            await wm.fetchOrderHistoryRequests();
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            itemCount: orderHistoryRequests.length,
                            itemBuilder: (context, index) {
                              return HistoryOrderCard(
                                orderRequest: orderHistoryRequests[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        });
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'История поездок пуста',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Здесь будут отображаться ваши поездки',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
