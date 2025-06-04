import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import 'inputs/phone_formz_input.dart';

class PhoneLoginForm with FormzMixin, EquatableMixin {
  final PhoneFormzInput phone;

  PhoneLoginForm({
    this.phone = const PhoneFormzInput.pure(),
  });

  @override
  List<FormzInput> get inputs => [
        phone,
      ];

  @override
  List<Object?> get props => [
        phone,
      ];

  PhoneLoginForm copyWith({
    PhoneFormzInput? phone,
  }) =>
      PhoneLoginForm(
        phone: phone ?? this.phone,
      );
}
