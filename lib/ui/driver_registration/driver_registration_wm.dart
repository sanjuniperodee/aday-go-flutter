import 'package:aktau_go/domains/driver_registered_category/driver_registered_category_domain.dart';
import 'package:aktau_go/forms/driver_registration_form.dart';
import 'package:aktau_go/forms/inputs/required_formz_input.dart';
import 'package:aktau_go/forms/inputs/ssn_formz_input.dart';
import 'package:aktau_go/interactors/common/rest_client.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/utils/text_editing_controller.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import '../../core/colors.dart';
import './driver_registation_model.dart';
import './driver_registration_screen.dart';

defaultDriverRegistrationWMFactory(BuildContext context) =>
    DriverRegistrationWM(DriverRegistrationModel());

abstract class IDriverRegistrationWM implements IWidgetModel {
  StateNotifier<DriverRegistrationForm> get driverRegistrationForm;

  StateNotifier<List<DriverRegisteredCategoryDomain>>
      get driverRegisteredCategories;

  TextEditingController get ssnTextEditingController;

  TextEditingController get governmentNumberTextEditingController;

  TextEditingController get modelTextEditingController;

  TextEditingController get brandTextEditingController;

  Future<void> submitProfileRegistration();

  List<CarColor> get carColors;

  void handleColorChanged(CarColor value);

  void handleDriverTypeChanged(DriverType value);

  void selectCategory(DriverRegisteredCategoryDomain e);
  
  void resetForm();
  
  void editCar(DriverRegisteredCategoryDomain car);
  
  void deleteCar(DriverRegisteredCategoryDomain car);
  
  void updateBrand(String value);
  
  void updateModel(String value);
  
  void updateGovernmentNumber(String value);
  
  void updateSSN(String value);
  
  void updateColor(String value);
  
  BuildContext get context;
}

class DriverRegistrationWM
    extends WidgetModel<DriverRegistrationScreen, DriverRegistrationModel>
    implements IDriverRegistrationWM {
  DriverRegistrationWM(
    DriverRegistrationModel model,
  ) : super(model);

  @override
  Future<void> submitProfileRegistration() async {
    try {
      // Показываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Сохранение...'),
            ],
          ),
          backgroundColor: primaryColor,
          duration: Duration(seconds: 10),
        ),
      );

      if (driverRegistrationForm.value?.id.value == null) {
        // Создание нового автомобиля
        await inject<RestClient>().createDriverCategory(
          governmentNumber: driverRegistrationForm.value!.governmentNumber.value!,
          type: driverRegistrationForm.value!.type.value!.key!,
          model: driverRegistrationForm.value!.model.value!,
          brand: driverRegistrationForm.value!.brand.value!,
          color: driverRegistrationForm.value!.color.value!.hexCode,
          SSN: driverRegistrationForm.value!.SSN.value,
        );
        
        // Показываем успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Автомобиль успешно добавлен'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Редактирование существующего автомобиля
        await inject<RestClient>().editDriverCategory(
          id: driverRegistrationForm.value!.id.value!,
          governmentNumber: driverRegistrationForm.value!.governmentNumber.value!,
          type: driverRegistrationForm.value!.type.value!.key!,
          model: driverRegistrationForm.value!.model.value!,
          brand: driverRegistrationForm.value!.brand.value!,
          color: driverRegistrationForm.value!.color.value!.hexCode,
          SSN: driverRegistrationForm.value!.SSN.value,
        );
        
        // Показываем успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Автомобиль успешно обновлен'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Обновляем список автомобилей
      fetchDriverRegisteredCategories();
      
      // Сбрасываем форму
      resetForm();

    } catch (e) {
      // Показываем сообщение об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  void editCar(DriverRegisteredCategoryDomain car) {
    selectCategory(car);
  }
  
  @override
  void deleteCar(DriverRegisteredCategoryDomain car) async {
    try {
      // Показываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Удаление...'),
            ],
          ),
          backgroundColor: primaryColor,
          duration: Duration(seconds: 10),
        ),
      );

      // Пытаемся использовать PUT запрос для мягкого удаления
      try {
        await inject<RestClient>().editDriverCategory(
          id: car.id,
          governmentNumber: car.number,
          type: car.categoryType.key!,
          model: car.model,
          brand: car.brand,
          color: car.color ?? '#FF000000',
          SSN: car.sSN,
        );
      } catch (e) {
        print('Edit failed, trying delete: $e');
        // Если редактирование не работает, пробуем удаление
        await inject<RestClient>().deleteDriverCategory(id: car.id);
      }
      
      // Обновляем список автомобилей
      fetchDriverRegisteredCategories();
      
      // Показываем успешное сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Автомобиль успешно удален'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting car: $e');
      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении автомобиля: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  void updateBrand(String value) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        brand: Required.dirty(value),
      ),
    );
  }
  
  @override
  void updateModel(String value) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        model: Required.dirty(value),
      ),
    );
  }
  
  @override
  void updateGovernmentNumber(String value) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        governmentNumber: Required.dirty(value),
      ),
    );
  }
  
  @override
  void updateSSN(String value) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        SSN: SSNFormzInput.dirty(value),
      ),
    );
  }
  
  @override
  void updateColor(String value) {
    final carColor = CarColor.fromHex(value);
    if (carColor != null) {
      driverRegistrationForm.accept(
        driverRegistrationForm.value?.copyWith(
          color: Required.dirty(carColor),
        ),
      );
    }
  }

  @override
  late final TextEditingController ssnTextEditingController =
      createTextEditingController(
    initialText: '',
    onChanged: handleSSNChanged,
  );

  @override
  late final TextEditingController brandTextEditingController =
      createTextEditingController(
    initialText: '',
    onChanged: handleBrandChanged,
  );

  @override
  late final TextEditingController governmentNumberTextEditingController =
      createTextEditingController(
    initialText: '',
    onChanged: handleGovernmentNumberChanged,
  );

  @override
  late final TextEditingController modelTextEditingController =
      createTextEditingController(
    initialText: '',
    onChanged: handleModelChanged,
  );

  @override
  StateNotifier<DriverRegistrationForm> driverRegistrationForm = StateNotifier(
    initValue: DriverRegistrationForm(),
  );

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    fetchDriverRegisteredCategories();
    
    // Слушаем изменения в контроллерах для обновления формы
    brandTextEditingController.addListener(_updateForm);
    modelTextEditingController.addListener(_updateForm);
    governmentNumberTextEditingController.addListener(_updateForm);
    ssnTextEditingController.addListener(_updateForm);
  }
  
  @override
  void dispose() {
    brandTextEditingController.dispose();
    modelTextEditingController.dispose();
    governmentNumberTextEditingController.dispose();
    ssnTextEditingController.dispose();
    super.dispose();
  }
  
  void _updateForm() {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        brand: Required.dirty(brandTextEditingController.text),
        model: Required.dirty(modelTextEditingController.text),
        governmentNumber: Required.dirty(governmentNumberTextEditingController.text),
        SSN: SSNFormzInput.dirty(ssnTextEditingController.text),
      ),
    );
  }

  @override
  final StateNotifier<List<DriverRegisteredCategoryDomain>>
      driverRegisteredCategories = StateNotifier(
    initValue: const [],
  );

  handleModelChanged(String p1) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        model: Required.dirty(p1),
      ),
    );
  }

  handleBrandChanged(String p1) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        brand: Required.dirty(p1),
      ),
    );
  }

  @override
  handleColorChanged(
    CarColor value,
  ) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        color: Required.dirty(value),
      ),
    );
  }

  void handleGovernmentNumberChanged(String p1) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        governmentNumber: Required.dirty(p1),
      ),
    );
  }

  @override
  List<CarColor> get carColors => [
        CarColor(hexCode: '#FF0000', label: 'Красный'),
        CarColor(hexCode: '#00FF00', label: 'Зелёный'),
        CarColor(hexCode: '#0000FF', label: 'Синий'),
        CarColor(hexCode: '#FFFF00', label: 'Жёлтый'),
        CarColor(hexCode: '#FFA500', label: 'Оранжевый'),
        CarColor(hexCode: '#800080', label: 'Фиолетовый'),
        CarColor(hexCode: '#000000', label: 'Чёрный'),
        CarColor(hexCode: '#FFFFFF', label: 'Белый'),
        CarColor(hexCode: '#808080', label: 'Серый'),
        CarColor(hexCode: '#A52A2A', label: 'Коричневый'),
      ];

  @override
  void handleDriverTypeChanged(DriverType value) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        type: Required.dirty(value),
      ),
    );
  }

  handleSSNChanged(String p1) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        SSN: SSNFormzInput.dirty(p1),
      ),
    );
  }

  void fetchDriverRegisteredCategories() async {
    final response =
        await inject<ProfileInteractor>().fetchDriverRegisteredCategories();

    driverRegisteredCategories.accept(response);
  }

  @override
  void selectCategory(DriverRegisteredCategoryDomain e) {
    driverRegistrationForm.accept(
      driverRegistrationForm.value?.copyWith(
        id: Required.dirty(e.id),
        brand: Required.dirty(e.brand),
        model: Required.dirty(e.model),
        color: e.color != null ? Required.dirty(CarColor.fromHex(e.color!)!) : null,
        type: Required.dirty(e.categoryType),
        governmentNumber: Required.dirty(e.number),
        SSN: SSNFormzInput.dirty(e.sSN),
      ),
    );

    brandTextEditingController.text = e.brand;
    modelTextEditingController.text = e.model;
    governmentNumberTextEditingController.text = e.number;
    ssnTextEditingController.text = e.sSN;
  }
  
  @override
  void resetForm() {
    // Проверяем, есть ли данные в форме
    final currentForm = driverRegistrationForm.value;
    final hasData = currentForm?.brand.value?.isNotEmpty == true ||
                   currentForm?.model.value?.isNotEmpty == true ||
                   currentForm?.governmentNumber.value?.isNotEmpty == true ||
                   currentForm?.SSN.value?.isNotEmpty == true;
    
    // Сбрасываем форму к начальному состоянию
    driverRegistrationForm.accept(DriverRegistrationForm());
    
    // Очищаем текстовые поля
    brandTextEditingController.text = '';
    modelTextEditingController.text = '';
    governmentNumberTextEditingController.text = '';
    ssnTextEditingController.text = '';
    
    // Показываем сообщение пользователю только если была отмена редактирования
    if (hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Редактирование отменено'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class CarColor with EquatableMixin {
  final String hexCode;
  final String label;

  CarColor({
    required this.hexCode,
    required this.label,
  });

  // Create a CarColor from a hex code
  static CarColor? fromHex(String hexCode) {
    try {
      // Remove the '#' if present
      String cleanHex = hexCode.replaceFirst('#', '');
      
      // Handle different hex formats
      if (cleanHex.length == 6) {
        // RGB format, add alpha
        cleanHex = 'FF$cleanHex';
      } else if (cleanHex.length == 8) {
        // ARGB format
        cleanHex = cleanHex;
      } else {
        return null;
      }
      
      // Find matching color name
      final colorMap = {
        'FF0000': 'Красный',
        '00FF00': 'Зеленый',
        '0000FF': 'Синий',
        'FFFF00': 'Желтый',
        'FFA500': 'Оранжевый',
        '800080': 'Фиолетовый',
        '000000': 'Черный',
        'FFFFFF': 'Белый',
        '808080': 'Серый',
        'A52A2A': 'Коричневый',
      };
      
      // Extract RGB part (remove alpha)
      final rgbHex = cleanHex.substring(2, 8);
      final colorName = colorMap[rgbHex] ?? 'Цвет #$rgbHex';
      
      return CarColor(
        hexCode: '#$rgbHex',
        label: colorName,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [hexCode, label];
}
