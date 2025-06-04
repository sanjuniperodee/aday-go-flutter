import 'package:formz/formz.dart';

enum RequiredError {
  empty,
}

extension RequiredErrorExt on RequiredError {
  static const keyMap = {
    RequiredError.empty: "empty",
  };

  static const valuesMap = {
    RequiredError.empty: "Обязательное поле",
  };

  String? get key => keyMap[this];

  String? get value => valuesMap[this];
}

class Required<T> extends FormzInput<T?, RequiredError> {
  const Required.pure([T? value]) : super.pure(value);

  const Required.dirty([T? value]) : super.dirty(value);

  @override
  RequiredError? validator(T? value) {
    if (value is String?) {
      return (value ?? '').isNotEmpty ? null : RequiredError.empty;
    } else if (value is num) {
      return value >= 0 ? null : RequiredError.empty;
    } else if (value is List) {
      return (value ?? []).isNotEmpty ? null : RequiredError.empty;
    }
    return value != null ? null : RequiredError.empty;
  }
}
