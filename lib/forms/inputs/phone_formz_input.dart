import 'package:formz/formz.dart';

enum PhoneFormzInputError { invalid, lengthLimit }

class PhoneFormzInput extends FormzInput<String, PhoneFormzInputError> {
  const PhoneFormzInput.pure([String value = '']) : super.pure(value);

  const PhoneFormzInput.dirty([String value = '']) : super.dirty(value);

  static final RegExp _phoneRegExp = RegExp(
    r'^\+\d{1}\(\d{3}\) \d{3}-\d{2}-\d{2}$',
  );

  @override
  PhoneFormzInputError? validator(String? value) {
    print(_phoneRegExp.hasMatch(value ?? ''));
    return _phoneRegExp.hasMatch(value ?? '')
        ? null
        : PhoneFormzInputError.invalid;
  }
}
