import 'package:formz/formz.dart';

enum SSNFormzInputError { invalid, lengthLimit }

class SSNFormzInput extends FormzInput<String, SSNFormzInputError> {
  const SSNFormzInput.pure([String value = '']) : super.pure(value);

  const SSNFormzInput.dirty([String value = '']) : super.dirty(value);

  static final RegExp _phoneRegExp = RegExp(
    r'^\d{6}[1-6]\d{5}$',
  );

  @override
  SSNFormzInputError? validator(String? value) {
    print(_phoneRegExp.hasMatch(value ?? ''));
    return _phoneRegExp.hasMatch(value ?? '')
        ? null
        : SSNFormzInputError.invalid;
  }
}
