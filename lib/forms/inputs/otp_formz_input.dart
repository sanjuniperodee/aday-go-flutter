import 'package:formz/formz.dart';

enum OtpFormzInputError { invalid, lengthLimit }

class OtpFormzInput extends FormzInput<String, OtpFormzInputError> {
  const OtpFormzInput.pure([String value = '']) : super.pure(value);

  const OtpFormzInput.dirty([String value = '']) : super.dirty(value);

  static final RegExp _otpRegExp = RegExp(
    r'^\d{4}$',
  );

  @override
  OtpFormzInputError? validator(String? value) {
    return _otpRegExp.hasMatch(value ?? '') ? null : OtpFormzInputError.invalid;
  }
}
