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
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 28),
            onPressed: () => wm.resetForm(),
            tooltip: 'Добавить автомобиль',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: greyscale10),
        ),
      ),
      body: SafeArea(
        child: DoubleSourceBuilder(
          firstSource: wm.driverRegistrationForm,
          secondSource: wm.driverRegisteredCategories,
          builder: (
            context,
            DriverRegistrationForm? driverRegistrationForm,
            List<DriverRegisteredCategoryDomain>? driverRegisteredCategories,
          ) {
            return Column(
              children: [
                // Основной контент
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Секция с зарегистрированными автомобилями
                        if (driverRegisteredCategories != null && driverRegisteredCategories.isNotEmpty)
                          _buildRegisteredCarsSection(context, wm, driverRegisteredCategories),
                        
                        // Форма добавления/редактирования автомобиля
                        if (driverRegistrationForm != null)
                          _buildCarRegistrationForm(context, wm, driverRegistrationForm, driverRegisteredCategories),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  // Секция с зарегистрированными автомобилями
  Widget _buildRegisteredCarsSection(
    BuildContext context, 
    IDriverRegistrationWM wm,
    List<DriverRegisteredCategoryDomain> categories
  ) {
    return Column(
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
                '${categories.length}',
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
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final car = categories[index];
            return _buildCarCard(context, wm, car);
          },
        ),
        
        SizedBox(height: 24),
      ],
    );
  }
  
  // Карточка автомобиля
  Widget _buildCarCard(
    BuildContext context,
    IDriverRegistrationWM wm,
    DriverRegisteredCategoryDomain car
  ) {
    final isActive = car.deletedAt == null;
    
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
          onTap: () => wm.editCar(car),
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
                        color: _getCarColor(car.color),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
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
                    // SSN
                    if (car.sSN.isNotEmpty)
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.badge,
                          label: 'SSN',
                          value: car.sSN,
                        ),
                      ),
                    
                    // Цвет автомобиля
                    if (car.color.isNotEmpty)
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.palette,
                          label: 'Цвет',
                          value: car.color,
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
                        onPressed: () => wm.editCar(car),
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
  
  // Форма добавления/редактирования автомобиля
  Widget _buildCarRegistrationForm(
    BuildContext context,
    IDriverRegistrationWM wm,
    DriverRegistrationForm form,
    List<DriverRegisteredCategoryDomain>? existingCars,
  ) {
    final isEditMode = form.id.value != null;
    
    return Container(
      margin: EdgeInsets.only(top: 16),
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
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок формы
            Row(
              children: [
                Icon(
                  isEditMode ? Icons.edit : Icons.add_circle_outline,
                  color: primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  isEditMode ? 'Редактирование автомобиля' : 'Добавление нового автомобиля',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                // Кнопка закрытия формы
                IconButton(
                  onPressed: () => wm.resetForm(),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Поля формы
            Column(
              children: [
                // Марка автомобиля
                RoundedTextField(
                  controller: wm.brandTextEditingController,
                  labelText: 'Марка автомобиля *',
                  hintText: 'Например: Toyota',
                ),
                
                SizedBox(height: 16),
                
                // Модель автомобиля
                RoundedTextField(
                  controller: wm.modelTextEditingController,
                  labelText: 'Модель автомобиля *',
                  hintText: 'Например: Camry',
                ),
                
                SizedBox(height: 16),
                
                // Государственный номер
                RoundedTextField(
                  controller: wm.governmentNumberTextEditingController,
                  labelText: 'Государственный номер *',
                  hintText: 'Например: 123ABC01',
                ),
                
                SizedBox(height: 16),
                
                // SSN
                RoundedTextField(
                  controller: wm.ssnTextEditingController,
                  labelText: 'SSN *',
                  hintText: 'Введите SSN',
                ),
                
                SizedBox(height: 16),
                
                // Выбор цвета
                _buildColorSelector(context, wm, form),
                
                SizedBox(height: 24),
                
                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: PrimaryButton.primary(
                    text: isEditMode ? 'Сохранить изменения' : 'Добавить автомобиль',
                    onPressed: form.isValid ? () => wm.submitProfileRegistration() : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Селектор цвета
  Widget _buildColorSelector(
    BuildContext context,
    IDriverRegistrationWM wm,
    DriverRegistrationForm form,
  ) {
    final colors = [
      {'name': 'Красный', 'value': 'red', 'color': Colors.red},
      {'name': 'Синий', 'value': 'blue', 'color': Colors.blue},
      {'name': 'Зеленый', 'value': 'green', 'color': Colors.green},
      {'name': 'Желтый', 'value': 'yellow', 'color': Colors.yellow},
      {'name': 'Оранжевый', 'value': 'orange', 'color': Colors.orange},
      {'name': 'Фиолетовый', 'value': 'purple', 'color': Colors.purple},
      {'name': 'Черный', 'value': 'black', 'color': Colors.black},
      {'name': 'Белый', 'value': 'white', 'color': Colors.white},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Цвет автомобиля',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((colorData) {
            final isSelected = form.color.value == colorData['value'];
            return GestureDetector(
              onTap: () => wm.updateColor(colorData['value'] as String),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorData['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
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
    switch (colorName?.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }
}

