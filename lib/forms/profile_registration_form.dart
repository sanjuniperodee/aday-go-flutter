import 'package:aktau_go/forms/inputs/phone_formz_input.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

class ProfileRegistrationForm with FormzMixin, EquatableMixin {
  final PhoneFormzInput phone;
  final String firstName;
  final String lastName;

  ProfileRegistrationForm({
    this.phone = const PhoneFormzInput.pure(),
    this.firstName = '',
    this.lastName = '',
  });

  @override
  List<FormzInput> get inputs => [
        phone,
      ];

  @override
  List<Object?> get props => [
        phone,
        firstName,
        lastName,
      ];

  ProfileRegistrationForm copyWith({
    PhoneFormzInput? phone,
    String? firstName,
    String? lastName,
  }) =>
      ProfileRegistrationForm(
        phone: phone ?? this.phone,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
      );
}
