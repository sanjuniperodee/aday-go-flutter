import 'dart:math';

import 'package:intl/intl.dart';

class NumUtils {
  NumUtils._();

  static String? humanizeNumber(num? number,
      {bool withDoublePercision = false, bool isCurrency = false}) {
    final numFormat =
        NumberFormat(withDoublePercision ? '#,###.###' : '#,###', 'ru-RU');
    if (number == null) {
      return null;
    }
    if (number.isNaN) {
      return null;
    }
    if (number == false) {
      return null;
    }
    return '${numFormat.format(number)}${isCurrency ? ' ${numFormat.simpleCurrencySymbol('KZT')}' : ''}';
  }

  static String? getMonthlyCreditPayTwo(
      int carPrice, int initialPay, num creditTerm) {
    const creditPercent = 0.2;
    var creditAmount = 0;

    creditAmount = carPrice - initialPay;

    var firstStep =
        (creditPercent / 12) * pow(1 + creditPercent / 12, creditTerm);
    var secondStep = pow(1 + creditPercent / 12, creditTerm) - 1;

    var ratio = firstStep / secondStep;

    return humanizeNumber((ratio * creditAmount).round(), isCurrency: true);
  }

  static num? parseString(String? stringNumber) {
    final format = NumberFormat("#,###.#", 'ru-RU');
    if (stringNumber == null) {
      // ignore: avoid_returning_null
      return null;
    }
    try {
      return format.parse(stringNumber);
    } on Exception {
      // ignore: avoid_returning_null
      return null;
    }
  }
}
