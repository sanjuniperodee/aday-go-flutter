import 'package:aktau_go/core/images.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/ui/widgets/primary_bottom_sheet.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/colors.dart';

class EarningAnalyticsBottomSheet extends StatelessWidget {
  final UserDomain? me;

  const EarningAnalyticsBottomSheet({
    super.key,
    this.me,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryBottomSheet(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: greyscale30,
                borderRadius: BorderRadius.circular(1.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Сегодня',
              style: text400Size16Greyscale90,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: ShapeDecoration(
              color: Color(0xFFF73C4E),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Заработано',
                            style: text600Size16White,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '${NumUtils.humanizeNumber(me?.today ?? 0)} ₸',
                            style: text700Size28White,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Ср. стоимость',
                          textAlign: TextAlign.center,
                          style: text400Size10Greyscale60,
                        ),
                        Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(icTenge),
                              const SizedBox(width: 4),
                              Text(
                                '${NumUtils.humanizeNumber((me?.today ?? 0) / (me?.ordersToday ?? 0))}',
                                textAlign: TextAlign.center,
                                style: text400Size16Greyscale90,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1, color: Color(0xFFE7E1E1)),
                              borderRadius: BorderRadius.circular(66),
                            ),
                          ),
                          child: Text(
                            '${NumUtils.humanizeNumber(me?.ordersToday ?? 0)} поездок',
                            textAlign: TextAlign.center,
                            style: text400Size12Greyscale90,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(
              'За неделю',
              style: text400Size16Greyscale90,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: ShapeDecoration(
              color: Color(0xFFF73C4E),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Заработано',
                            style: text600Size16White,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '${NumUtils.humanizeNumber(me?.thisWeek ?? 0)} ₸',
                            style: text700Size28White,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Ср. стоимость',
                          textAlign: TextAlign.center,
                          style: text400Size10Greyscale60,
                        ),
                        Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(icTenge),
                              const SizedBox(width: 4),
                              Text(
                                '${NumUtils.humanizeNumber((me?.thisWeek ?? 0) / (me?.ordersThisWeek ?? 0))}',
                                textAlign: TextAlign.center,
                                style: text400Size16Greyscale90,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1, color: Color(0xFFE7E1E1)),
                              borderRadius: BorderRadius.circular(66),
                            ),
                          ),
                          child: Text(
                            '${NumUtils.humanizeNumber(me?.ordersThisWeek ?? 0)} поездок',
                            textAlign: TextAlign.center,
                            style: text400Size12Greyscale90,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(
              'За месяц',
              style: text400Size16Greyscale90,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: ShapeDecoration(
              color: Color(0xFFF73C4E),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Заработано',
                            style: text600Size16White,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '${NumUtils.humanizeNumber(me?.thisMonth ?? 0)} ₸',
                            style: text700Size28White,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Ср. стоимость',
                          textAlign: TextAlign.center,
                          style: text400Size10Greyscale60,
                        ),
                        Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(icTenge),
                              const SizedBox(width: 4),
                              Text(
                                '${NumUtils.humanizeNumber((me?.thisMonth ?? 0) / (me?.ordersThisMonth ?? 0))}',
                                textAlign: TextAlign.center,
                                style: text400Size16Greyscale90,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1, color: Color(0xFFE7E1E1)),
                              borderRadius: BorderRadius.circular(66),
                            ),
                          ),
                          child: Text(
                            '${NumUtils.humanizeNumber(me?.ordersThisMonth ?? 0)} поездок',
                            textAlign: TextAlign.center,
                            style: text400Size12Greyscale90,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
