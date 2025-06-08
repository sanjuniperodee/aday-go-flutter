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

  selectCategory(DriverRegisteredCategoryDomain e);
}

class DriverRegistrationWM
    extends WidgetModel<DriverRegistrationScreen, DriverRegistrationModel>
    implements IDriverRegistrationWM {
  DriverRegistrationWM(
    DriverRegistrationModel model,
  ) : super(model);

  @override
  Future<void> submitProfileRegistration() async {
    if (driverRegistrationForm.value?.id.value == null) {
      await inject<RestClient>().createDriverCategory(
        governmentNumber: driverRegistrationForm.value!.governmentNumber.value!,
        type: driverRegistrationForm.value!.type.value!.key!,
        model: driverRegistrationForm.value!.model.value!,
        brand: driverRegistrationForm.value!.brand.value!,
        color: driverRegistrationForm.value!.color.value!.hexCode,
        SSN: driverRegistrationForm.value!.SSN.value,
      );
    } else {
      await inject<RestClient>().editDriverCategory(
        id: driverRegistrationForm.value!.id.value!,
        governmentNumber: driverRegistrationForm.value!.governmentNumber.value!,
        type: driverRegistrationForm.value!.type.value!.key!,
        model: driverRegistrationForm.value!.model.value!,
        brand: driverRegistrationForm.value!.brand.value!,
        color: driverRegistrationForm.value!.color.value!.hexCode,
        SSN: driverRegistrationForm.value!.SSN.value,
      );
    }

    Routes.router.popUntil(
      (predicate) => predicate.isFirst,
    );
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
        CarColor(color: Colors.red, label: 'Красный'),
        CarColor(color: Colors.green, label: 'Зелёный'),
        CarColor(color: Colors.blue, label: 'Синий'),
        CarColor(color: Colors.yellow, label: 'Жёлтый'),
        CarColor(color: Colors.orange, label: 'Оранжевый'),
        CarColor(color: Colors.purple, label: 'Фиолетовый'),
        CarColor(color: Colors.black, label: 'Чёрный'),
        CarColor(color: Colors.white, label: 'Белый'),
        CarColor(color: Colors.grey, label: 'Серый'),
        CarColor(color: Colors.brown, label: 'Коричневый'),
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
  selectCategory(DriverRegisteredCategoryDomain e) {
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
}

class CarColor with EquatableMixin {
  final Color color;
  final String label;

  // Convert color to hex code
  String get hexCode =>
      '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  CarColor({
    required this.color,
    required this.label,
  });

  // Create a CarColor from a hex code
  static CarColor? fromHex(String hexCode) {
    final carColors = [
      CarColor(color: Colors.red, label: 'Красный'),
      CarColor(color: Colors.green, label: 'Зелёный'),
      CarColor(color: Colors.blue, label: 'Синий'),
      CarColor(color: Colors.yellow, label: 'Жёлтый'),
      CarColor(color: Colors.orange, label: 'Оранжевый'),
      CarColor(color: Colors.purple, label: 'Фиолетовый'),
      CarColor(color: Colors.black, label: 'Чёрный'),
      CarColor(color: Colors.white, label: 'Белый'),
      CarColor(color: Colors.grey, label: 'Серый'),
      CarColor(color: Colors.brown, label: 'Коричневый'),
    ];
    // Remove the '#' if present
    String cleanHex = hexCode.replaceFirst('#', '');
    for (var carColor in carColors) {
      if (carColor.color.value
              .toRadixString(16)
              .padLeft(8, '0')
              .toUpperCase() ==
          cleanHex) {
        return carColor;
      }
    }
    return null; // Return null if no match found
  }

  @override
  List<Object?> get props => [
        color,
        label,
      ];
}
