import 'package:aktau_go/domains/driver_registered_category/driver_registered_category_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/ui/widgets/primary_dropdown.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/rounded_text_field.dart';
import 'driver_registration_wm.dart';
import 'add_edit_car_screen.dart';

class DriverRegistrationScreen extends ElementaryWidget<IDriverRegistrationWM> {
  DriverRegistrationScreen({
    Key? key,
  }) : super(
          (context) => defaultDriverRegistrationWMFactory(context),
        );

  @override
  Widget build(IDriverRegistrationWM wm) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Мои автомобили',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(wm.context).pop(),
        ),
        actions: [
          // Показываем кнопку добавления только если есть доступные типы
          StateNotifierBuilder<List<DriverRegisteredCategoryDomain>>(
            listenableState: wm.driverRegisteredCategories,
            builder: (context, driverRegisteredCategories) {
              if (driverRegisteredCategories == null || driverRegisteredCategories.isEmpty) {
                return IconButton(
                  icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 28),
                  onPressed: () => _navigateToAddEditCar(wm.context),
                  tooltip: 'Добавить автомобиль',
                );
              }
              
              // Проверяем, есть ли доступные типы машин
              final existingTypes = driverRegisteredCategories
                  .map((car) => car.categoryType)
                  .toSet();
              
              final allTypes = [
                DriverType.TAXI,
                DriverType.DELIVERY,
                DriverType.INTERCITY_TAXI,
                DriverType.CARGO,
              ];
              
              final availableTypes = allTypes.where((type) => !existingTypes.contains(type)).toList();
              
              if (availableTypes.isEmpty) {
                return SizedBox.shrink(); // Скрываем кнопку
              }
              
              return IconButton(
                icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 28),
                onPressed: () => _navigateToAddEditCar(wm.context),
                tooltip: 'Добавить автомобиль',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: greyscale10),
        ),
      ),
      body: SafeArea(
        child: StateNotifierBuilder<List<DriverRegisteredCategoryDomain>>(
          listenableState: wm.driverRegisteredCategories,
          builder: (context, driverRegisteredCategories) {
            if (driverRegisteredCategories == null) {
              return Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок секции
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car, color: primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Зарегистрированные автомобили',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${driverRegisteredCategories.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Список автомобилей
                  if (driverRegisteredCategories.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: driverRegisteredCategories.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final car = driverRegisteredCategories[index];
                        return _buildCarCard(context, wm, car);
                      },
                    )
                  else
                    _buildEmptyState(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Карточка автомобиля
  Widget _buildCarCard(
    BuildContext context,
    IDriverRegistrationWM wm,
    DriverRegisteredCategoryDomain car
  ) {
    final isActive = car.deletedAt == null;
    final carColor = _getCarColor(car.color);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToAddEditCar(context, car),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок карточки
                Row(
                  children: [
                    // Иконка автомобиля с цветом
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: carColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCarTypeIcon(car.categoryType),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    
                    // Информация об автомобиле
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${car.brand} ${car.model}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            car.number,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Статус активности
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? Colors.green : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isActive ? 'Активен' : 'Неактивен',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Дополнительная информация
                Row(
                  children: [
                    // Тип автомобиля
                    Expanded(
                      child: _buildInfoItem(
                        icon: _getCarTypeIcon(car.categoryType),
                        label: 'Тип',
                        value: _getCarTypeLabel(car.categoryType),
                      ),
                    ),
                    
                    // SSN
                    if (car.sSN.isNotEmpty)
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.badge,
                          label: 'SSN',
                          value: car.sSN,
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Кнопки действий
                Row(
                  children: [
                    // Кнопка редактирования
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToAddEditCar(context, car),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Редактировать'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 8),
                    
                    // Кнопка удаления
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, wm, car),
                        icon: Icon(Icons.delete_outline, size: 16),
                        label: Text('Удалить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Пустое состояние
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'У вас пока нет автомобилей',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте свой первый автомобиль для начала работы',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  // Элемент информации
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Навигация к странице добавления/редактирования
  void _navigateToAddEditCar(BuildContext context, [DriverRegisteredCategoryDomain? car]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditCarScreen(carToEdit: car),
      ),
    );
    
    // Обновляем список если вернулись с результатом
    if (result == true) {
      // Обновляем список автомобилей
      // Это будет обработано в WidgetModel
    }
  }
  
  // Диалог подтверждения удаления
  void _showDeleteConfirmation(
    BuildContext context,
    IDriverRegistrationWM wm,
    DriverRegisteredCategoryDomain car,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удаление автомобиля'),
        content: Text(
          'Вы уверены, что хотите удалить автомобиль "${car.brand} ${car.model}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              wm.deleteCar(car);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }
  
  // Получение цвета автомобиля
  Color _getCarColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) {
      return Colors.grey;
    }
    
    try {
      // Remove the '#' if present
      String cleanHex = colorName.replaceFirst('#', '');
      
      // Handle different hex formats
      if (cleanHex.length == 6) {
        // RGB format, add alpha
        cleanHex = 'FF$cleanHex';
      } else if (cleanHex.length == 8) {
        // ARGB format
        cleanHex = cleanHex;
      } else {
        return Colors.grey;
      }
      
      // Parse hex to int
      int colorValue = int.parse(cleanHex, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return Colors.grey;
    }
  }
  
  // Получение иконки типа автомобиля
  IconData _getCarTypeIcon(DriverType categoryType) {
    switch (categoryType) {
      case DriverType.TAXI:
        return Icons.local_taxi;
      case DriverType.DELIVERY:
        return Icons.delivery_dining;
      case DriverType.INTERCITY_TAXI:
        return Icons.directions_car;
      case DriverType.CARGO:
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }
  
  // Получение названия типа автомобиля
  String _getCarTypeLabel(DriverType categoryType) {
    switch (categoryType) {
      case DriverType.TAXI:
        return 'Такси';
      case DriverType.DELIVERY:
        return 'Доставка';
      case DriverType.INTERCITY_TAXI:
        return 'Междугороднее такси';
      case DriverType.CARGO:
        return 'Грузоперевозки';
      default:
        return 'Неизвестно';
    }
  }
}

