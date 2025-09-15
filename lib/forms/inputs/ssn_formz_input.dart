import 'package:formz/formz.dart';

enum SSNFormzInputError { invalid, lengthLimit }

extension SSNFormzInputErrorExt on SSNFormzInputError {
  String? get value {
    switch (this) {
      case SSNFormzInputError.invalid:
        return 'Неверный формат SSN';
      case SSNFormzInputError.lengthLimit:
        return 'SSN должен содержать 12 цифр';
    }
  }
}

class SSNFormzInput extends FormzInput<String, SSNFormzInputError> {
  const SSNFormzInput.pure([String value = '']) : super.pure(value);

  const SSNFormzInput.dirty([String value = '']) : super.dirty(value);

  static final RegExp _phoneRegExp = RegExp(
    r'^\d{6}[1-6]\d{5}$',
  );

  @override
  SSNFormzInputError? validator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Пустое значение не является ошибкой
    }
    
    // Проверяем, что SSN содержит только цифры и имеет правильную длину
    if (value.length != 12) {
      return SSNFormzInputError.lengthLimit;
    }
    
    // Проверяем, что все символы - цифры
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return SSNFormzInputError.invalid;
    }
    
    // Проверяем, что 7-я цифра от 1 до 6
    if (int.parse(value[6]) < 1 || int.parse(value[6]) > 6) {
      return SSNFormzInputError.invalid;
    }
    
    return null;
  }
}
