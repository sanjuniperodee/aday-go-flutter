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
import 'package:flutter_rating_stars/flutter_rating_stars.dart';

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
  bool isRated = false;
  double driverRating = 0.0;
  String ratingComment = '';
  bool isSubmittingRating = false;

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
              : activeRequest.order?.orderStatus == 'COMPLETED' && !isRated
                  ? _buildRatingView()
              : _buildActiveOrderView(),
        ),
      ),
    );
  }

  // Упрощенный минималистичный дизайн экрана поиска водителя
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
        
        // Компактный заголовок с анимацией
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Container(
              width: 40,
              height: 40,
          decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
          ),
              child: Icon(
                Icons.search,
                color: primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Поиск водителя',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                ),
              ),
                Row(
                  children: [
              Text(
                      'Ищем ближайшего',
                style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                ),
                    ),
                    SizedBox(width: 4),
                    _buildSimpleAnimatedDots(),
                  ],
              ),
            ],
          ),
          ],
        ),
        
        SizedBox(height: 24),
        
        // Компактная информация о поездке
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Маршрут
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 20,
                        color: Colors.grey.shade300,
                      ),
                      Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 12,
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeRequest.order?.from ?? 'Не указано',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                            fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                        SizedBox(height: 8),
                        Text(
                          activeRequest.order?.to ?? 'Не указано',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                            fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
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
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Информационная подсказка
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
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
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Обычно поиск занимает 1-3 минуты',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Кнопка отмены
        Container(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
          onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.red.shade300,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Отменить поиск',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 16),
      ],
    );
  }

  // Упрощенные анимированные точки
  Widget _buildSimpleAnimatedDots() {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(left: 1),
          child: Text(
            '.',
            style: TextStyle(
              fontSize: 16,
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

  // Экран оценки поездки (редизайн)
  Widget _buildRatingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем элементы по ширине
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

        // Заголовок
        Text(
          'Как вам поездка?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Пожалуйста, оцените водителя',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: greyscale60,
          ),
        ),
        const SizedBox(height: 24),

        // Информация о водителе (опционально, с более компактным дизайном)
        if (activeRequest.driver != null) ...[
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24, // Чуть меньше радиус
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 24, // Меньше иконка
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Водитель',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: greyscale60,
                        ),
                      ),
                      Text(
                        '${activeRequest.driver?.firstName ?? ''} ${activeRequest.driver?.lastName ?? ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Звездочки для оценки (увеличенный размер и улучшенный вид)
        Center(
          child: RatingStars(
            value: driverRating,
            onValueChanged: (value) {
              setState(() {
                driverRating = value;
              });
            },
            starBuilder: (index, color) => Icon(
              Icons.star_rounded,
              color: color,
              size: 48, // Больше размер звезд
            ),
            starCount: 5,
            starSize: 48,
            valueLabelColor: Colors.transparent, // Скрываем числовое значение
            valueLabelTextStyle: TextStyle(), // Пустой стиль
            valueLabelRadius: 0,
            maxValue: 5,
            starSpacing: 8, // Увеличиваем расстояние между звездами
            maxValueVisibility: false, // Скрываем максимальное значение
            valueLabelVisibility: false, // Скрываем текстовое значение
            animationDuration: Duration(milliseconds: 300),
          ),
        ),
        const SizedBox(height: 24),

        // Поле для комментария
        TextField(
          onChanged: (value) {
            setState(() {
              ratingComment = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Ваши впечатления о поездке...',
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: greyscale50,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Без рамки
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2), // Активная рамка
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 4,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),

        // Кнопка "Отправить оценку"
        PrimaryButton.primary(
          onPressed: isSubmittingRating || driverRating == 0.0
               ? null
               : () async {
                   setState(() {
                     isSubmittingRating = true;
                   });
                   await _submitRating();
                   setState(() {
                     isSubmittingRating = false;
                   });
                 },
          text: isSubmittingRating
              ? 'Отправка...'
              : 'Отправить оценку',
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Кнопка "Закрыть" (если оценка уже отправлена или пропущена)
        PrimaryButton.secondary(
          onPressed: () {
            setState(() {
              isRated = true; // Считаем, что пропущено - больше не показываем
            });
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              widget.activeOrderListener.accept(null);
            }
          },
          text: 'Не сейчас', // Менее обязывающий текст
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: greyscale60,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Метод для отправки оценки
  Future<void> _submitRating() async {
    try {
      final orderId = activeRequest.order?.id;

      print('🔍 Данные для отправки отзыва:');
      print('   orderId: $orderId');
      print('   rating: $driverRating');
      print('   comment: "${ratingComment.trim()}"');

      if (orderId != null && driverRating > 0) {
        await inject<OrderRequestsInteractor>().rateDriver(
          orderId: orderId,
          rating: driverRating.toInt(), // Оценка от 1 до 5
          comment: ratingComment.trim().isEmpty ? null : ratingComment.trim(),
        );
        print('✅ Оценка отправлена успешно: $driverRating звезд, комментарий: "${ratingComment.trim()}"');
        
        setState(() {
          isRated = true; // Устанавливаем флаг, что оценка отправлена
        });
        
        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Спасибо за отзыв!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Закрываем окно через небольшую задержку
        await Future.delayed(Duration(milliseconds: 500));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          widget.activeOrderListener.accept(null);
        }
      } else {
        print('⚠️ Не удалось отправить оценку: orderId=$orderId, rating=$driverRating');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Пожалуйста, поставьте оценку от 1 до 5 звезд'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Ошибка при отправке оценки: $e');
      // Показываем сообщение об ошибке пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось отправить оценку. Попробуйте еще раз.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
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
