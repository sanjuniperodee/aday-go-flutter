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
              ? _buildSearchingForDriverView()
              : _buildActiveOrderView(),
        ),
      ),
    );
  }

  // Обновленный современный дизайн экрана поиска водителя
  Widget _buildSearchingForDriverView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Полоска для перетаскивания
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
        const SizedBox(height: 20),
        
        // Заголовок с градиентом
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.1),
                primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Пульсирующая анимация поиска
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Внешний круг с пульсацией
                    AnimatedContainer(
                      duration: Duration(seconds: 2),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Средний круг
                    AnimatedContainer(
                      duration: Duration(milliseconds: 1500),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    // Внутренний круг с иконкой
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Заголовок
              Text(
                'Поиск водителя',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              SizedBox(height: 8),
              
              // Подзаголовок с анимированными точками
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ищем ближайшего водителя',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(width: 4),
                  // Анимированные точки
                  _buildAnimatedDots(),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Карточка с информацией о поездке
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок карточки
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Детали поездки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Маршрут
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Иконки маршрута
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Адреса
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Откуда
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Откуда:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeRequest.order?.from ?? 'Не указано',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Куда
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Куда:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeRequest.order?.to ?? 'Не указано',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
              
              SizedBox(height: 16),
              
              // Разделитель
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              
              SizedBox(height: 16),
              
              // Цена с выделением
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.attach_money,
                          color: Colors.amber.shade700,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Стоимость поездки',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${activeRequest.order?.price} ₸',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Информационная подсказка
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Обычно поиск водителя занимает 1-3 минуты',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Кнопка отмены с улучшенным дизайном
        Container(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.red.shade300,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red.withOpacity(0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.close,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Отменить поиск',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
      ],
    );
  }

  // Виджет анимированных точек
  Widget _buildAnimatedDots() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 600 + (index * 200)),
          margin: EdgeInsets.only(left: 2),
          child: Text(
            '.',
            style: TextStyle(
              fontSize: 20,
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  // Обновленный дизайн для активного заказа
  Widget _buildActiveOrderView() {
    final orderStatus = activeRequest.order?.orderStatus;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Полоска для перетаскивания
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
        
        // Статус заказа с иконкой
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(orderStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStatusColor(orderStatus).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(orderStatus).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(orderStatus),
                  color: _getStatusColor(orderStatus),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(orderStatus),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getStatusDescription(orderStatus),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Информация о поездке
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Откуда
              Row(
                children: [
                  Icon(Icons.radio_button_checked, color: Colors.green, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activeRequest.order?.from ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Вертикальная линия
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Container(
                  height: 20,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
              ),
              
              // Куда
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activeRequest.order?.to ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              Divider(height: 24),
              
              // Цена
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Стоимость',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${activeRequest.order?.price} ₸',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Информация о водителе
        if (activeRequest.driver != null)
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: primaryColor,
                        size: 30,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activeRequest.driver?.firstName ?? ''} ${activeRequest.driver?.lastName ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${activeRequest.driver?.rating?.toStringAsFixed(1) ?? '0.0'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Кнопка звонка
                  if (activeRequest.driver?.phone != null)
                  InkWell(
                    onTap: () => _callDriver(activeRequest.driver?.phone),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.phone,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (activeRequest.car != null)
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.grey.shade700,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activeRequest.car?.props?.brand ?? ''} ${activeRequest.car?.props?.model ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          activeRequest.car?.props?.number ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getCarColor(activeRequest.car?.props?.color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Кнопка отмены
        if (activeRequest.order?.orderStatus != 'ONGOING' && !isOrderFinished)
        PrimaryButton.secondary(
          onPressed: widget.onCancel,
          text: 'Отменить поездку',
          textStyle: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        
        SizedBox(height: 16),
      ],
    );
  }

  Future<void> _callDriver(String? phoneNumber) async {
    if (phoneNumber == null) return;
    
    final url = 'tel:$phoneNumber';
    try {
      await launchUrlString(url);
    } catch (e) {
      print('Ошибка при попытке позвонить: $e');
    }
  }
  
  // Вспомогательные методы для стилизации статусов
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'STARTED':
        return Colors.blue;
      case 'WAITING':
        return Colors.orange;
      case 'ONGOING':
        return Colors.green;
      default:
        return primaryColor;
    }
  }
  
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'STARTED':
        return Icons.directions_car;
      case 'WAITING':
        return Icons.timer;
      case 'ONGOING':
        return Icons.directions;
      default:
        return Icons.check_circle;
    }
  }
  
  String _getStatusTitle(String? status) {
    switch (status) {
      case 'STARTED':
        return 'Водитель в пути';
      case 'WAITING':
        return 'Водитель на месте';
      case 'ONGOING':
        return 'Поездка началась';
      case 'COMPLETED':
        return 'Поездка завершена';
      default:
        return 'Заказ принят';
    }
  }
  
  String _getStatusDescription(String? status) {
    switch (status) {
      case 'STARTED':
        return 'Водитель едет к вам';
      case 'WAITING':
        return 'Водитель ждет вас на месте';
      case 'ONGOING':
        return 'Поездка в процессе';
      case 'COMPLETED':
        return 'Поездка завершена';
      default:
        return 'Водитель принял заказ';
    }
  }
  
  Color _getCarColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'белый':
      case 'white':
        return Colors.grey.shade100;
      case 'черный':
      case 'black':
        return Colors.grey.shade800;
      case 'красный':
      case 'red':
        return Colors.red;
      case 'синий':
      case 'blue':
        return Colors.blue;
      case 'зеленый':
      case 'green':
        return Colors.green;
      case 'желтый':
      case 'yellow':
        return Colors.yellow.shade600;
      case 'серый':
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'коричневый':
      case 'brown':
        return Colors.brown;
      case 'оранжевый':
      case 'orange':
        return Colors.orange;
      case 'фиолетовый':
      case 'purple':
        return Colors.purple;
      case 'розовый':
      case 'pink':
        return Colors.pink;
      case 'серебряный':
      case 'silver':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade400;
    }
  }
}
