import 'package:aktau_go/domains/driver_registered_category/driver_registered_category_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/ui/widgets/primary_dropdown.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Управление автомобилями',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: greyscale10,
          ),
        ),
      ),
      body: DoubleSourceBuilder(
          firstSource: wm.driverRegistrationForm,
          secondSource: wm.driverRegisteredCategories,
          builder: (
            context,
            DriverRegistrationForm? driverRegistrationForm,
            List<DriverRegisteredCategoryDomain>? driverRegisteredCategories,
          ) {
            return ListView(
              padding: EdgeInsets.symmetric(vertical: 16),
              children: [
                if (driverRegisteredCategories!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ваши автомобили',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  '${driverRegisteredCategories.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 180,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            itemCount: driverRegisteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = driverRegisteredCategories[index];
                              final carColor = CarColor.fromHex(category.color);
                              
                              return GestureDetector(
                                onTap: () => wm.selectCategory(category),
                                child: Container(
                                  width: 280,
                                  margin: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Верхняя часть карточки с цветом авто
                                      Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: carColor?.color ?? Colors.grey,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.directions_car,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      // Информация об авто
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${category.brand} ${category.model}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      category.categoryType.value,
                                                      style: TextStyle(
                                                        color: primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.confirmation_number_outlined, 
                                                    size: 16, 
                                                    color: Colors.grey[600],
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    category.number,
                                                    style: TextStyle(
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          color: carColor?.color ?? Colors.grey,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        carColor?.label ?? 'Цвет',
                                                        style: TextStyle(
                                                          color: Colors.grey[800],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.edit, color: primaryColor),
                                                    onPressed: () => wm.selectCategory(category),
                                                    iconSize: 20,
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Форма добавления/редактирования автомобиля
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок формы
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              driverRegistrationForm?.id.value == null ? 'Добавить новый автомобиль' : 'Редактировать автомобиль',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Содержимое формы
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Категория автомобиля
                            _buildFormLabel('Категория автомобиля'),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: PrimaryDropdown<DriverType>(
                                initialOption: driverRegistrationForm?.type.value,
                                options: DriverType.values
                                    .where((e) => driverRegistrationForm?.id.value == null
                                          ? !driverRegisteredCategories.any((category) => category.categoryType == e)
                                          : true)
                                    .map((e) => SelectOption(
                                          value: e,
                                          label: e.value,
                                        ))
                                    .toList(),
                                onChanged: (option) => wm.handleDriverTypeChanged(option!.value),
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // Бренд и модель в одной строке
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFormLabel('Марка автомобиля'),
                                      RoundedTextField(
                                        backgroundColor: Colors.grey[100]!,
                                        hintText: 'Toyota',
                                        hintStyle: text400Size16Greyscale30,
                                        controller: wm.brandTextEditingController,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFormLabel('Модель'),
                                      RoundedTextField(
                                        backgroundColor: Colors.grey[100]!,
                                        hintText: 'Camry',
                                        hintStyle: text400Size16Greyscale30,
                                        controller: wm.modelTextEditingController,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            // Гос номер
                            _buildFormLabel('Гос. номер автомобиля'),
                            RoundedTextField(
                              backgroundColor: Colors.grey[100]!,
                              hintText: 'A 123 BC',
                              hintStyle: text400Size16Greyscale30,
                              controller: wm.governmentNumberTextEditingController,
                            ),
                            SizedBox(height: 16),
                            
                            // ИИН
                            _buildFormLabel('ИИН'),
                            RoundedTextField(
                              backgroundColor: Colors.grey[100]!,
                              hintText: '123456789012',
                              hintStyle: text400Size16Greyscale30,
                              controller: wm.ssnTextEditingController,
                            ),
                            SizedBox(height: 16),
                            
                            // Выбор цвета с визуализацией
                            _buildFormLabel('Цвет автомобиля'),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _buildColorSelector(wm, driverRegistrationForm),
                            ),
                            SizedBox(height: 24),
                            
                            // Кнопка действия
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: PrimaryButton.primary(
                                onPressed: driverRegistrationForm!.isValid
                                    ? wm.submitProfileRegistration
                                    : null,
                                text: driverRegistrationForm.id.value == null ? 'Добавить автомобиль' : 'Сохранить изменения',
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
  
  // Вспомогательный метод для создания заголовков полей
  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }
  
  // Селектор цветов автомобиля
  Widget _buildColorSelector(IDriverRegistrationWM wm, DriverRegistrationForm? form) {
    final selectedColor = form?.color.value;
    
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: wm.carColors.map((color) {
        final isSelected = selectedColor?.color.value == color.color.value;
        
        return GestureDetector(
          onTap: () => wm.handleColorChanged(color),
          child: Container(
            width: 44,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: isSelected
                ? Center(
                    child: Icon(
                      Icons.check,
                      color: _contrastColor(color.color),
                      size: 20,
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
  
  // Определение контрастного цвета для иконки чекбокса 
  Color _contrastColor(Color backgroundColor) {
    // Вычисляем яркость по формуле: 0.299*R + 0.587*G + 0.114*B
    final brightness = (backgroundColor.red * 0.299 + 
                        backgroundColor.green * 0.587 + 
                        backgroundColor.blue * 0.114) / 255;
    
    // Если яркость больше 0.5, используем черный цвет, иначе - белый
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
}
