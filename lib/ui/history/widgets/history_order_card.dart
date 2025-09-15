import 'package:aktau_go/domains/active_request/active_request_domain.dart';
import 'package:aktau_go/domains/order_request/order_request_domain.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/colors.dart';
import '../../../core/text_styles.dart';
import '../../widgets/text_locale.dart';

class HistoryOrderCard extends StatelessWidget {
  final ActiveRequestDomain orderRequest;

  const HistoryOrderCard({
    super.key,
    required this.orderRequest,
  });

  @override
  Widget build(BuildContext context) {
    final date = orderRequest.orderRequest?.createdAt;
    final formattedDate = date != null 
        ? DateFormat('dd MMMM yyyy, HH:mm').format(date)
        : 'Нет даты';
        
    final price = NumUtils.humanizeNumber(
      orderRequest.orderRequest?.price,
      isCurrency: true,
    ) ?? 'Нет данных';
    
    final duration = orderRequest.orderRequest?.differenceInMinutes ?? 0;
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    final durationText = [
      if (hours > 0) '$hours ч',
      if (minutes > 0) '$minutes мин',
    ].join(' ');
    
    final fromAddress = orderRequest.orderRequest?.from ?? 'Не указано';
    final toAddress = orderRequest.orderRequest?.to ?? 'Не указано';
    
    final userName = (orderRequest.driver?.id ?? '').isNotEmpty
        ? '${orderRequest.driver?.firstName ?? ''} ${orderRequest.driver?.lastName ?? ''}'
        : orderRequest.whatsappUser?.fullName ?? 'Неизвестно';
    
    final userRole = (orderRequest.driver?.id ?? '').isNotEmpty ? 'Водитель' : 'Клиент';
    
    final orderStatus = _getOrderStatus(orderRequest);
    final statusColor = _getStatusColor(orderStatus);

    // Определяем, является ли заказ отмененным
    final isCancelled = orderStatus.contains('Отменен');
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: isCancelled ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCancelled ? Colors.grey.shade300 : Colors.grey.shade200,
          width: isCancelled ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Показать детали заказа при нажатии
          _showOrderDetails(context);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя часть с датой, ценой и статусом
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Дата
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // Статус
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Иконка для отмененных заказов
                        if (orderStatus.contains('Отменен'))
                          Icon(
                            Icons.cancel_outlined,
                            size: 14,
                            color: statusColor,
                          ),
                        if (orderStatus.contains('Отменен'))
                          SizedBox(width: 4),
                        Text(
                          orderStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Маршрут - улучшенное отображение адресов
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Откуда
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 14),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fromAddress,
                          style: TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Куда
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place, color: primaryColor, size: 14),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          toAddress,
                          style: TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Нижняя часть с ценой, временем и водителем
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Цена и время
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCancelled ? Colors.grey.shade600 : primaryColor,
                        ),
                      ),
                      if (durationText.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              durationText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  // Информация о водителе/клиенте
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          userRole == 'Водитель' ? Icons.drive_eta : Icons.person,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            userRole,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Получение статуса заказа
  String _getOrderStatus(ActiveRequestDomain order) {
    if (order.orderRequest?.orderStatus == null) return 'Неизвестно';
    
    final status = order.orderRequest!.orderStatus;
    
    if (status == 'COMPLETED') {
      return 'Завершен';
    } else if (status == 'REJECTED_BY_CLIENT') {
      return 'Отменен клиентом';
    } else if (status == 'REJECTED_BY_DRIVER') {
      return 'Отменен водителем';
    } else if (status == 'REJECTED') {
      return 'Отменен';
    } else if (status == 'CANCELLED') {
      return 'Отменен';
    } else if (status == 'ACTIVE') {
      return 'Активен';
    } else if (status == 'PENDING') {
      return 'В ожидании';
    } else {
      return 'Неизвестно';
    }
  }
  
  // Получение цвета статуса
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Завершен':
        return Colors.green;
      case 'Отменен клиентом':
        return Colors.red.shade600;
      case 'Отменен водителем':
        return Colors.red.shade700;
      case 'Отменен':
        return Colors.red;
      case 'Активен':
        return Colors.blue;
      case 'В ожидании':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  // Показать детали заказа
  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Ручка для закрытия
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Заголовок
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Детали поездки',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              Divider(),
              
              // Содержимое
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Детали поездки
                      _buildDetailSection('Информация о поездке'),
                      _buildDetailRow('Дата и время', DateFormat('dd MMMM yyyy, HH:mm').format(orderRequest.orderRequest?.createdAt ?? DateTime.now())),
                      _buildDetailRow('Статус', _getOrderStatus(orderRequest)),
                      _buildDetailRow('Номер заказа', orderRequest.orderRequest?.id ?? 'Нет данных'),
                      
                      SizedBox(height: 24),
                      
                      // Маршрут
                      _buildDetailSection('Маршрут'),
                      _buildAddressRow('Откуда', orderRequest.orderRequest?.from ?? 'Не указано', Icons.circle, Colors.green),
                      SizedBox(height: 8),
                      _buildAddressRow('Куда', orderRequest.orderRequest?.to ?? 'Не указано', Icons.place, primaryColor),
                      
                      SizedBox(height: 24),
                      
                      // Оплата
                      _buildDetailSection('Оплата'),
                      _buildDetailRow('Сумма', NumUtils.humanizeNumber(orderRequest.orderRequest?.price, isCurrency: true) ?? 'Нет данных'),
                      _buildDetailRow('Способ оплаты', 'Наличные'),
                      
                      SizedBox(height: 24),
                      
                      // Информация о водителе/клиенте
                      _buildDetailSection((orderRequest.driver?.id ?? '').isNotEmpty ? 'Информация о водителе' : 'Информация о клиенте'),
                      _buildDetailRow('Имя', (orderRequest.driver?.id ?? '').isNotEmpty
                          ? '${orderRequest.driver?.firstName ?? ''} ${orderRequest.driver?.lastName ?? ''}'
                          : orderRequest.whatsappUser?.fullName ?? 'Неизвестно'),
                      if ((orderRequest.driver?.id ?? '').isNotEmpty)
                        _buildDetailRow('Автомобиль', 'Нет данных'),
                      if ((orderRequest.driver?.id ?? '').isNotEmpty)
                        _buildDetailRow('Гос. номер', 'Нет данных'),
                      
                      // Кнопка WhatsApp для связи с водителем/клиентом
                      if ((orderRequest.driver?.phone ?? '').isNotEmpty || (orderRequest.whatsappUser?.phone ?? '').isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 16),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.message, color: Colors.white),
                            label: Text(
                              'Написать в WhatsApp',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF25D366), // WhatsApp green
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _openWhatsApp(
                                (orderRequest.driver?.id ?? '').isNotEmpty 
                                    ? orderRequest.driver?.phone ?? ''
                                    : orderRequest.whatsappUser?.phone ?? ''
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Вспомогательные методы для построения деталей
  Widget _buildDetailSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddressRow(String label, String address, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Открыть WhatsApp с указанным номером телефона
  void _openWhatsApp(String phone) {
    try {
      // Удаляем все нецифровые символы из номера
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      if (cleanPhone.isEmpty) {
        print('Ошибка: номер телефона пуст');
        return;
      }
      
      // Формируем URL для открытия WhatsApp
      final whatsappUrl = 'https://wa.me/$cleanPhone';
      
      // Открываем URL
      launchUrlString(whatsappUrl);
    } catch (e) {
      print('Ошибка при открытии WhatsApp: $e');
    }
  }
}
