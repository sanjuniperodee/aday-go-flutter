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
            appBar: AppBar(
              title: SizedBox(
                width: double.infinity,
                child: Text(
                  'История заказов',
                  style: text500Size24Black,
                ),
              ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  color: greyscale10,
                ),
              ),
            ),
            body: ListView(
              children: [
                const SizedBox(height: 24),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      const SizedBox(width: 16),
                      ...DriverType.values.asMap().entries.map(
                            (e) => InkWell(
                              onTap: () => wm.tabIndexChanged(e.key),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: ShapeDecoration(
                                  color: tabIndex == e.key
                                      ? Color(0xFFF73C4E)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: tabIndex != e.key
                                        ? BorderSide(
                                            width: 1, color: Color(0xFFB4AAA9))
                                        : BorderSide.none,
                                    borderRadius: BorderRadius.circular(102),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      e.value.asset!,
                                      color: tabIndex == e.key
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    TextLocale(
                                      e.value.value!,
                                      style: tabIndex == e.key
                                          ? text400Size16White
                                          : text400Size16Greyscale30,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (ActiveRequestDomain order in (orderHistoryRequests ?? []))
                  HistoryOrderCard(orderRequest: order)
              ],
            ),
          );
        });
  }
}
