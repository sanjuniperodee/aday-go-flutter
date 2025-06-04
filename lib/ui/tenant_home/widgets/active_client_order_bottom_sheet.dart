import 'dart:async';

import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/interactors/order_requests_interactor.dart';
import 'package:aktau_go/models/active_client_request/active_client_request_model.dart';
import 'package:aktau_go/ui/driver_registration/driver_registration_wm.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/colors.dart';
import '../../../core/images.dart';
import '../../../core/text_styles.dart';
import '../../widgets/primary_bottom_sheet.dart';

class ActiveClientOrderBottomSheet extends StatefulWidget {
  final UserDomain me;
  final ActiveClientRequestModel activeOrder;
  final VoidCallback onCancel;
  final StateNotifier<ActiveClientRequestModel> activeOrderListener;

  const ActiveClientOrderBottomSheet({
    super.key,
    required this.me,
    required this.activeOrder,
    required this.onCancel,
    required this.activeOrderListener,
  });

  @override
  State<ActiveClientOrderBottomSheet> createState() =>
      _ActiveClientOrderBottomSheetState();
}

class _ActiveClientOrderBottomSheetState
    extends State<ActiveClientOrderBottomSheet> {
  late ActiveClientRequestModel activeRequest = widget.activeOrder;

  int waitingTimerLeft = 180;

  Timer? waitingTimer;

  bool isOrderFinished = false;

  @override
  void initState() {
    super.initState();
    widget.activeOrderListener.addListener(() {
      fetchActiveOrder();
    });
  }

  Future<void> fetchActiveOrder() async {
    try {
      final response =
          await inject<OrderRequestsInteractor>().getMyClientActiveOrder();

      activeRequest = response;

      setState(() {});
    } on Exception catch (e) {
      setState(() {
        isOrderFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: PrimaryBottomSheet(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        child: SizedBox(
          child: activeRequest.order?.orderStatus == 'CREATED'
              ? Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Заказ размещён, ищем водителя',
                            style: text400Size24Greyscale60,
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            children: [
                              Lottie.asset(
                                'assets/lottie/location.json',
                                fit: BoxFit.cover,
                              ),
                              // Center(child: SvgPicture.asset('assets/icons/placemark.svg', color: Color(0xFFDC3545),),)
                            ],
                          ),
                        ),
                      ],
                    ),
                    PrimaryButton.secondary(
                      onPressed: widget.onCancel,
                      text: 'Остановить поиск',
                      textStyle: text400Size16Greyscale60,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
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
                        if (!isOrderFinished &&
                            activeRequest.order?.orderStatus == 'CREATED')
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Ваш заказ принят, ожидайте.',
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 20,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        else if (!isOrderFinished &&
                            activeRequest.order?.orderStatus == 'STARTED')
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Водитель в пути, ожидайте',
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 20,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        else if (!isOrderFinished &&
                            activeRequest.order?.orderStatus == 'WAITING')
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Водитель на месте',
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 20,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        else if (!isOrderFinished &&
                            activeRequest.order?.orderStatus == 'ONGOING')
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Поездка началась',
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 20,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        else if (isOrderFinished &&
                            activeRequest.order?.orderStatus == 'REJECTED')
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Заказ отменен',
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 20,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        else if (isOrderFinished)
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Заказ завершен',
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 20,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        if (activeRequest.driver != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1, color: Color(0xFFE7E1E1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          "https://via.placeholder.com/48x48"),
                                      fit: BoxFit.cover,
                                    ),
                                    shape: OvalBorder(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Водитель',
                                          textAlign: TextAlign.center,
                                          style: text400Size12Greyscale60,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${activeRequest.driver?.lastName ?? ''} ${activeRequest.driver?.firstName ?? ''}',
                                          textAlign: TextAlign.center,
                                          style: text400Size16Greyscale90,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Машина',
                                          textAlign: TextAlign.center,
                                          style: text400Size12Greyscale60,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: Image.asset(
                                                'assets/images/car.png',
                                                color: CarColor.fromHex(
                                                        activeRequest
                                                            .car!.props!.color!)
                                                    ?.color,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${activeRequest.car?.props?.brand ?? ''} ${activeRequest.car?.props?.model ?? ''}',
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      text400Size16Greyscale90,
                                                ),
                                                Text(
                                                  '${activeRequest.car?.props?.number ?? ''}',
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      text400Size16Greyscale90,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
                                    launchUrlString(
                                        'https://wa.me/${(widget.activeOrder.driver?.phone ?? '').replaceAll('+', '')}');
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    child: SvgPicture.asset(icWhatsapp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Откуда',
                                                textAlign: TextAlign.center,
                                                style: text400Size10Greyscale60,
                                              ),
                                              Container(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/icons/placemark.svg',
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        widget.activeOrder.order
                                                                ?.from ??
                                                            '',
                                                        textAlign:
                                                            TextAlign.left,
                                                        style:
                                                            text400Size16Black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Куда',
                                                textAlign: TextAlign.center,
                                                style: text400Size10Greyscale60,
                                              ),
                                              Container(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/icons/placemark.svg',
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        widget.activeOrder.order
                                                                ?.to ??
                                                            '',
                                                        textAlign:
                                                            TextAlign.left,
                                                        style:
                                                            text400Size16Black,
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
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 36,
                          padding: const EdgeInsets.all(8),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1, color: Color(0xFFE7E1E1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  child: Text(
                                    'Цена поездки: ${NumUtils.humanizeNumber(activeRequest.order?.price)} ₸ ',
                                    style: text400Size16Greyscale90,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((widget.activeOrder.order?.comment ?? '')
                            .isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 24),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1, color: Color(0xFFE7E1E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text('Комментарии'),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        child: Text(
                                          widget.activeOrder.order?.comment ??
                                              '',
                                          style: text400Size12Greyscale90,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        if (activeRequest.order?.orderStatus == 'WAITING')
                          Container(
                            width: double.infinity,
                            height: 36,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(top: 24),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    width: 1, color: Color(0xFFE7E1E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    child: Text(
                                      'Ожидание: ${waitingTimerLeft ~/ 60}:${waitingTimerLeft % 60}',
                                      style: text400Size16Greyscale90,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: PrimaryButton.secondary(
                              onPressed: widget.onCancel,
                              text: 'Отменить заказ',
                              textStyle: text400Size16Greyscale60,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PrimaryButton.primary(
                              onPressed: () {
                                launchUrlString(
                                    'tel://${(widget.activeOrder.driver?.phone ?? '')}');
                              },
                              text: 'Отказаться',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Позвонить',
                                    style: text400Size16White,
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
        ),
      ),
    );
  }
}
