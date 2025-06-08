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

  // Новый дизайн экрана поиска водителя
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
        const SizedBox(height: 24),
        
        // Анимация и текст
        Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(
                  'assets/lottie/location.json',
                  fit: BoxFit.contain,
                ),
              ),
              
              Text(
                'Поиск водителя',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Ожидайте, мы ищем подходящего водителя',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
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
        
        // Кнопка отмены
        PrimaryButton.secondary(
          onPressed: widget.onCancel,
          text: 'Отменить поиск',
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
        return 'Водитель уже едет к вам';
      case 'WAITING':
        return 'Водитель ожидает вас на месте посадки';
      case 'ONGOING':
        return 'Вы в пути к месту назначения';
      case 'COMPLETED':
        return 'Спасибо за поездку!';
      default:
        return 'Водитель скоро будет назначен';
    }
  }
  
  Color _getCarColor(String? colorString) {
    if (colorString == null) return Colors.grey;
    
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return Colors.grey;
    }
  }
}
