import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import '../ui/driver_registration/driver_registration_wm.dart';
import './inputs/required_formz_input.dart';
import './inputs/ssn_formz_input.dart';

class DriverRegistrationForm with FormzMixin, EquatableMixin {
  final Required<String> id;
  final Required<String> governmentNumber;
  final Required<String> model;
  final Required<String> brand;
  final Required<CarColor> color;
  final Required<DriverType> type;
  final SSNFormzInput SSN;

  DriverRegistrationForm({
    this.id = const Required.pure(),
    this.governmentNumber = const Required.pure(),
    this.type = const Required.pure(),
    this.model = const Required.pure(),
    this.brand = const Required.pure(),
    this.color = const Required.pure(),
    this.SSN = const SSNFormzInput.pure(),
  });

  @override
  List<FormzInput> get inputs => [
        governmentNumber,
        type,
        model,
        brand,
        color,
        SSN,
      ];

  @override
  List<Object?> get props => [
        id,
        governmentNumber,
        type,
        model,
        brand,
        color,
        SSN,
      ];

  DriverRegistrationForm copyWith({
    Required<String>? id,
    Required<String>? governmentNumber,
    Required<DriverType>? type,
    Required<String>? model,
    Required<String>? brand,
    Required<CarColor>? color,
    SSNFormzInput? SSN,
  }) =>
      DriverRegistrationForm(
        id: id ?? this.id,
        governmentNumber: governmentNumber ?? this.governmentNumber,
        type: type ?? this.type,
        model: model ?? this.model,
        brand: brand ?? this.brand,
        color: color ?? this.color,
        SSN: SSN ?? this.SSN,
      );
}

enum DriverType {
  TAXI,
  DELIVERY,
  INTERCITY_TAXI,
  CARGO,
}

extension IdentityStatusTypeExt on DriverType {
  static const keyMap = {
    DriverType.TAXI: "TAXI",
    DriverType.DELIVERY: "DELIVERY",
    DriverType.INTERCITY_TAXI: "INTERCITY_TAXI",
    DriverType.CARGO: "CARGO",
  };

  static const valueMap = {
    DriverType.TAXI: "Такси",
    DriverType.DELIVERY: "Доставка",
    DriverType.INTERCITY_TAXI: "Межгород",
    DriverType.CARGO: "Груз",
  };

  static const assetMap = {
    DriverType.TAXI: "assets/icons/taxi.svg",
    DriverType.DELIVERY: "assets/icons/delivery.svg",
    DriverType.INTERCITY_TAXI: "assets/icons/intercity.svg",
    DriverType.CARGO: "assets/icons/truck.svg",
  };

  String? get value => valueMap[this];

  String? get key => keyMap[this];

  String? get asset => assetMap[this];
}
