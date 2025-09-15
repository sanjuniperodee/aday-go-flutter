import 'package:aktau_go/domains/driver_registered_category/driver_registered_category_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/forms/inputs/required_formz_input.dart';
import 'package:aktau_go/forms/inputs/ssn_formz_input.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:aktau_go/models/driver_registered_category/mapper/driver_registered_category_mapper.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';

import '../../core/colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/rounded_text_field.dart';
import 'driver_registration_wm.dart';

class AddEditCarScreen extends ElementaryWidget<IAddEditCarWM> {
  final DriverRegisteredCategoryDomain? carToEdit;

  AddEditCarScreen({
    Key? key,
    this.carToEdit,
  }) : super(
          (context) => defaultAddEditCarWMFactory(context, carToEdit),
        );

  @override
  Widget build(IAddEditCarWM wm) {
    final isEditMode = carToEdit != null;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          isEditMode ? 'Редактирование автомобиля' : 'Добавление автомобиля',
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[300]),
        ),
      ),
      body: SafeArea(
        child: StateNotifierBuilder<DriverRegistrationForm>(
          listenableState: wm.driverRegistrationForm,
          builder: (context, form) {
            if (form == null) {
              return Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEditMode ? Icons.edit : Icons.add_circle_outline,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditMode ? 'Редактирование' : 'Новый автомобиль',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                isEditMode 
                                  ? 'Обновите информацию об автомобиле'
                                  : 'Заполните информацию об автомобиле',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Тип автомобиля
                  _buildSectionTitle('Тип автомобиля'),
                  SizedBox(height: 12),
                  _buildCarTypeSelector(wm, form),
                  if (wm.showValidationErrors && form.type.error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Пожалуйста, выберите тип автомобиля',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 24),
                  
                  // Основная информация
                  _buildSectionTitle('Основная информация'),
                  SizedBox(height: 16),
                  
                  // Марка и модель
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: wm.brandTextEditingController,
                          label: 'Марка',
                          hint: 'Toyota',
                          errorText: wm.showValidationErrors ? form.brand.error?.value : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: wm.modelTextEditingController,
                          label: 'Модель',
                          hint: 'Camry',
                          errorText: wm.showValidationErrors ? form.model.error?.value : null,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Государственный номер
                  _buildTextField(
                    controller: wm.governmentNumberTextEditingController,
                    label: 'Государственный номер',
                    hint: '123ABC01',
                    errorText: wm.showValidationErrors ? form.governmentNumber.error?.value : null,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // SSN
                  _buildTextField(
                    controller: wm.ssnTextEditingController,
                    label: 'SSN',
                    hint: 'Введите SSN',
                    errorText: wm.showValidationErrors ? form.SSN.error?.value : null,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Выбор цвета
                  _buildSectionTitle('Цвет автомобиля'),
                  SizedBox(height: 12),
                  _buildColorSelector(wm, form),
                  if (wm.showValidationErrors && form.color.error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Пожалуйста, выберите цвет автомобиля',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 32),
                  
                  // Кнопка сохранения
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: PrimaryButton.primary(
                      text: isEditMode ? 'Сохранить изменения' : 'Добавить автомобиль',
                      onPressed: form.isValid ? () => wm.submitCar() : null,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 8),
          Text(
            errorText,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCarTypeSelector(IAddEditCarWM wm, DriverRegistrationForm form) {
    final carTypes = [
      {'type': DriverType.TAXI, 'label': 'Такси', 'icon': Icons.local_taxi, 'color': Colors.orange},
      {'type': DriverType.DELIVERY, 'label': 'Доставка', 'icon': Icons.delivery_dining, 'color': Colors.green},
      {'type': DriverType.INTERCITY_TAXI, 'label': 'Междугороднее такси', 'icon': Icons.directions_car, 'color': Colors.blue},
      {'type': DriverType.CARGO, 'label': 'Грузоперевозки', 'icon': Icons.local_shipping, 'color': Colors.purple},
    ];
    
    // Получаем существующие типы машин (исключаем текущую редактируемую машину)
    final existingTypes = wm.existingCars
        .where((car) => carToEdit == null || car.id != carToEdit!.id)
        .map((car) => car.categoryType)
        .toSet();
    
    // Добавляем отладочную информацию
    print('Existing cars count: ${wm.existingCars.length}');
    print('Existing types: $existingTypes');
    print('Car to edit ID: ${carToEdit?.id}');
    
    // Фильтруем доступные типы
    final availableTypes = carTypes.where((typeData) {
      final type = typeData['type'] as DriverType;
      final isAvailable = !existingTypes.contains(type);
      print('Type $type available: $isAvailable');
      return isAvailable;
    }).toList();
    
    print('Available types count: ${availableTypes.length}');
    
    if (availableTypes.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          'У вас уже есть машины всех доступных типов',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: availableTypes.map((typeData) {
          final isSelected = form.type.value == typeData['type'];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => wm.updateCarType(typeData['type'] as DriverType),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (typeData['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        typeData['icon'] as IconData,
                        color: typeData['color'] as Color,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        typeData['label'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildColorSelector(IAddEditCarWM wm, DriverRegistrationForm form) {
    final colors = [
      {'name': 'Красный', 'value': '#FF0000'},
      {'name': 'Зеленый', 'value': '#00FF00'},
      {'name': 'Синий', 'value': '#0000FF'},
      {'name': 'Желтый', 'value': '#FFFF00'},
      {'name': 'Оранжевый', 'value': '#FFA500'},
      {'name': 'Фиолетовый', 'value': '#800080'},
      {'name': 'Черный', 'value': '#000000'},
      {'name': 'Белый', 'value': '#FFFFFF'},
      {'name': 'Серый', 'value': '#808080'},
      {'name': 'Коричневый', 'value': '#A52A2A'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цвет автомобиля',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((colorData) {
              final selectedColorHex = form.color.value?.hexCode;
              final currentColorHex = colorData['value'] as String;
              final isSelected = selectedColorHex == currentColorHex;
              
              return GestureDetector(
                onTap: () => wm.updateColor(colorData['value'] as String),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    colorData['name'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// WidgetModel для новой страницы
abstract class IAddEditCarWM implements IWidgetModel {
  StateNotifier<DriverRegistrationForm> get driverRegistrationForm;
  TextEditingController get brandTextEditingController;
  TextEditingController get modelTextEditingController;
  TextEditingController get governmentNumberTextEditingController;
  TextEditingController get ssnTextEditingController;
  
  Future<void> submitCar();
  void updateCarType(DriverType type);
  void updateColor(String hexColor);
  BuildContext get context;
  bool get showValidationErrors;
  List<DriverRegisteredCategoryDomain> get existingCars;
}

defaultAddEditCarWMFactory(BuildContext context, DriverRegisteredCategoryDomain? carToEdit) =>
    AddEditCarWM(AddEditCarModel(), carToEdit);

class AddEditCarWM extends WidgetModel<AddEditCarScreen, AddEditCarModel> implements IAddEditCarWM {
  final DriverRegisteredCategoryDomain? carToEdit;
  
  AddEditCarWM(AddEditCarModel model, this.carToEdit) : super(model);
  
  @override
  StateNotifier<DriverRegistrationForm> driverRegistrationForm = StateNotifier(
    initValue: DriverRegistrationForm(),
  );
  
  @override
  late final TextEditingController brandTextEditingController = TextEditingController();
  @override
  late final TextEditingController modelTextEditingController = TextEditingController();
  @override
  late final TextEditingController governmentNumberTextEditingController = TextEditingController();
  @override
  late final TextEditingController ssnTextEditingController = TextEditingController();
  
  // Флаг для показа ошибок валидации
  bool _showValidationErrors = false;
  
  // Список существующих машин
  List<DriverRegisteredCategoryDomain> _existingCars = [];
  
  @override
  bool get showValidationErrors => _showValidationErrors;
  
  @override
  List<DriverRegisteredCategoryDomain> get existingCars => _existingCars;
  
  @override
  void initWidgetModel() {
    super.initWidgetModel();
    
    // Инициализируем форму с данными машины, если мы в режиме редактирования
    if (carToEdit != null) {
      _loadCarData();
    }
    
    // Загружаем существующие машины
    _loadExistingCars();
    
    // Слушаем изменения в контроллерах для обновления формы
    brandTextEditingController.addListener(_updateForm);
    modelTextEditingController.addListener(_updateForm);
    governmentNumberTextEditingController.addListener(_updateForm);
    ssnTextEditingController.addListener(_updateForm);
  }
  
  void _loadCarData() {
    final car = carToEdit!;
    print('Loading car data: ${car.brand} ${car.model}');
    print('Car color: ${car.color}');
    
    // Сначала устанавливаем значения в контроллеры
    brandTextEditingController.text = car.brand;
    modelTextEditingController.text = car.model;
    governmentNumberTextEditingController.text = car.number;
    ssnTextEditingController.text = car.sSN;
    
    // Пытаемся создать CarColor из hex
    CarColor? carColor;
    if (car.color.isNotEmpty) {
      carColor = CarColor.fromHex(car.color);
      print('Parsed car color: ${carColor?.hexCode}');
    }
    
    // Создаем новую форму с данными машины
    final newForm = DriverRegistrationForm().copyWith(
      id: Required.dirty(car.id),
      brand: Required.dirty(car.brand),
      model: Required.dirty(car.model),
      governmentNumber: Required.dirty(car.number),
      SSN: SSNFormzInput.dirty(car.sSN),
      type: Required.dirty(car.categoryType),
      color: carColor != null ? Required.dirty(carColor) : null,
    );
    
    // Устанавливаем форму
    driverRegistrationForm.accept(newForm);
    
    print('Form loaded successfully with ID: ${newForm.id.value}');
  }
  
  Future<void> _loadExistingCars() async {
    try {
      final cars = await GetIt.instance.get<RestClient>().driverRegisteredCategories();
      _existingCars = driverRegisteredCategoryListMapper(cars);
      
      // Уведомляем UI об обновлении данных только если мы не в режиме редактирования
      if (carToEdit == null) {
        driverRegistrationForm.accept(driverRegistrationForm.value);
      }
    } catch (e) {
      print('Error loading existing cars: $e');
    }
  }
  
  void _updateForm() {
    // Получаем текущую форму
    final currentForm = driverRegistrationForm.value;
    if (currentForm == null) return;
    
    // Обновляем только текстовые поля, сохраняя остальные данные
    final updatedForm = currentForm.copyWith(
      brand: Required.dirty(brandTextEditingController.text),
      model: Required.dirty(modelTextEditingController.text),
      governmentNumber: Required.dirty(governmentNumberTextEditingController.text),
      SSN: SSNFormzInput.dirty(ssnTextEditingController.text),
    );
    
    driverRegistrationForm.accept(updatedForm);
  }
  
  @override
  Future<void> submitCar() async {
    // Показываем ошибки валидации при попытке отправки
    _showValidationErrors = true;
    
    final form = driverRegistrationForm.value!;
    
    // Проверяем валидность формы
    if (!form.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, заполните все обязательные поля корректно'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    try {
      if (form.id.value == null) {
        // Создание нового автомобиля
        await GetIt.instance.get<RestClient>().createDriverCategory(
          governmentNumber: form.governmentNumber.value!,
          type: form.type.value!.key!,
          model: form.model.value!,
          brand: form.brand.value!,
          color: form.color.value!.hexCode,
          SSN: form.SSN.value,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Автомобиль успешно добавлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Редактирование существующего автомобиля
        await GetIt.instance.get<RestClient>().editDriverCategory(
          id: form.id.value!,
          governmentNumber: form.governmentNumber.value!,
          type: form.type.value!.key!,
          model: form.model.value!,
          brand: form.brand.value!,
          color: form.color.value!.hexCode,
          SSN: form.SSN.value,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Автомобиль успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      Navigator.of(context).pop(true); // Возвращаем true для обновления списка
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  void updateCarType(DriverType type) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        type: Required.dirty(type),
      ),
    );
  }
  
  @override
  void updateColor(String hexColor) {
    final carColor = CarColor.fromHex(hexColor);
    if (carColor != null) {
      driverRegistrationForm.accept(
        driverRegistrationForm.value?.copyWith(
          color: Required.dirty(carColor),
        ),
      );
      print('Color updated to: ${carColor.hexCode} (${carColor.label})');
    }
  }
}

class AddEditCarModel extends ElementaryModel {}
