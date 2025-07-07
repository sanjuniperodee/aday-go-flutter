// import 'package:action_slider/action_slider.dart'; // Removed - not used and causes compatibility issues
import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/ui/orders/widgets/order_request_card.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/ui/widgets/text_locale.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';

import 'package:elementary/elementary.dart';

import '../../domains/driver_registered_category/driver_registered_category_domain.dart';
import '../../router/router.dart';
import './orders_wm.dart';

class OrdersScreen extends ElementaryWidget<IOrdersWM> {
  OrdersScreen({
    Key? key,
  }) : super(
          (context) => defaultOrdersWMFactory(context),
        );

  @override
  Widget build(IOrdersWM wm) {
    return DoubleSourceBuilder(
        firstSource: wm.showNewOrders,
        secondSource: wm.orderType,
        builder: (
          context,
          bool? showNewOrders,
          DriverType? orderType,
        ) {
          return DoubleSourceBuilder(
              firstSource: wm.isWebsocketConnected,
              secondSource: wm.locationPermission,
              builder: (
                context,
                bool? isWebsocketConnected,
                LocationPermission? locationPermission,
              ) {
                return Scaffold(
                  appBar: AppBar(
                    title: SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Поиск заказов',
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
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: AdvancedSwitch(
                          controller: wm.statusController,
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey,
                          activeChild: Text('Онлайн'),
                          inactiveChild: Text('Оффлайн'),
                          enabled: [
                            LocationPermission.always,
                            LocationPermission.whileInUse
                          ].contains(locationPermission),
                          borderRadius:
                              BorderRadius.all(const Radius.circular(15)),
                          width: 100,
                          height: 30.0,
                          disabledOpacity: 0.5,
                        ),
                      )
                    ],
                  ),
                  body: DoubleSourceBuilder(
                      firstSource: wm.orderRequests,
                      secondSource: wm.driverRegisteredCategories,
                      builder: (
                        context,
                        List<OrderRequestDomain>? orderRequests,
                        List<DriverRegisteredCategoryDomain>?
                            driverRegisteredCategories,
                      ) {
                        return Stack(
                          children: [
                            RefreshIndicator(
                              onRefresh: wm.fetchOrderRequests,
                              child: ListView(
                                children: [
                                  const SizedBox(height: 24),
                                  DoubleSourceBuilder(
                                    firstSource: wm.isWebsocketConnected,
                                    secondSource: wm.locationPermission,
                                    builder: (
                                      context,
                                      bool? isWebsocketConnected,
                                      LocationPermission? locationPermission,
                                    ) {
                                      // Если нет разрешения на геолокацию
                                      if (![
                                        LocationPermission.always,
                                        LocationPermission.whileInUse,
                                      ].contains(locationPermission))
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            shadows: [
                                              BoxShadow(
                                                color: Color(0x26261619),
                                                blurRadius: 15,
                                                offset: Offset(0, 4),
                                                spreadRadius: 0,
                                              )
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Включите геолокацию',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: text400Size16Black,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      width: 12,
                                                      height: 12,
                                                      child: SvgPicture.asset(
                                                          'assets/icons/close.svg'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                width: double.infinity,
                                                child: Text(
                                                  'Это требуется для показа вашей локации на карте',
                                                  style:
                                                      text400Size12Greyscale50,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              PrimaryButton.primary(
                                                onPressed: wm
                                                    .requestLocationPermission,
                                                text: 'Включить',
                                                textStyle: text400Size16White,
                                              )
                                            ],
                                          ),
                                        );
                                      
                                      // Если есть разрешение, но WebSocket не подключен и переключатель включен
                                      else if ([
                                            LocationPermission.always,
                                            LocationPermission.whileInUse,
                                          ].contains(locationPermission) &&
                                          wm.statusController.value &&
                                          !(isWebsocketConnected ?? false)) {
                                        return DoubleSourceBuilder<bool?, String?>(
                                          firstSource: wm.isWebSocketConnecting,
                                          secondSource: wm.webSocketConnectionError,  
                                          builder: (context, bool? isConnecting, String? connectionError) {
                                            return Container(
                                              margin: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              decoration: ShapeDecoration(
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                shadows: [
                                                  BoxShadow(
                                                    color: Color(0x26261619),
                                                    blurRadius: 15,
                                                    offset: Offset(0, 4),
                                                    spreadRadius: 0,
                                                  )
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          isConnecting == true 
                                                            ? 'Подключение...' 
                                                            : connectionError != null 
                                                              ? 'Ошибка подключения'
                                                              : 'Подключение к серверу',
                                                          textAlign: TextAlign.center,
                                                          style: text400Size16Black,
                                                        ),
                                                        const SizedBox(width: 10),
                                                        if (isConnecting == true)
                                                          SizedBox(
                                                            width: 12,
                                                            height: 12,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                primaryColor,
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            width: 12,
                                                            height: 12,
                                                            child: SvgPicture.asset(
                                                              connectionError != null 
                                                                ? 'assets/icons/close.svg'
                                                                : 'assets/icons/close.svg'
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    width: double.infinity,
                                                    child: Text(
                                                      isConnecting == true 
                                                        ? 'Подключаемся к серверу заказов...'
                                                        : connectionError != null 
                                                          ? connectionError
                                                          : 'Инициализация подключения...',
                                                      style: text400Size12Greyscale50,
                                                    ),
                                                  ),
                                                  if (connectionError != null && isConnecting != true) ...[
                                                    const SizedBox(height: 12),
                                                    PrimaryButton.secondary(
                                                      onPressed: () {
                                                        wm.initializeSocket();
                                                      },
                                                      text: 'Повторить',
                                                      textStyle: text400Size16White,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }

                                      return SizedBox.shrink();
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Показываем заказы только если WebSocket подключен
                                  if (isWebsocketConnected == true)
                                    if ((driverRegisteredCategories ?? [])
                                        .any((category) =>
                                            category.categoryType == orderType))
                                                                             ...(orderRequests ?? []).map(
                                         (e) => OrderRequestCard(
                                           orderRequest: e,
                                           onAccept: () => wm.onOrderRequestTap(e),
                                         ),
                                       )
                                    else
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Text(
                                                  'Чтобы начать принимать заказы нужно зарегистрироваться на категорию',
                                                  style: text400Size16Greyscale90,
                                                ),
                                              ),
                                              PrimaryButton.primary(
                                                onPressed: wm.registerOrderType,
                                                text: 'Зарегестрироваться',
                                                textStyle: text400Size16White,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                            AnimatedPositioned(
                              top: showNewOrders == true ? 16 : -100,
                              left: 16,
                              right: 16,
                              duration: Duration(
                                seconds: 1,
                              ),
                              child: Center(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: wm.tapNewOrders,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x1E000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 0),
                                            spreadRadius: 5,
                                          ),
                                        ]),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Показать новые заказы',
                                          style: text400Size16Greyscale90,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        );
                      }),
                );
              });
        });
  }
}
