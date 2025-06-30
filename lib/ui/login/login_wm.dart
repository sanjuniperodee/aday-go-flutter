import 'package:aktau_go/forms/inputs/phone_formz_input.dart';
import 'package:aktau_go/interactors/authorization_interactor.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/ui/otp/otp_screen.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:aktau_go/utils/text_editing_controller.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:aktau_go/utils/network_utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../forms/phone_login_form.dart';
import 'login_model.dart';
import 'login_screen.dart';

defaultLoginWMFactory(BuildContext context) => LoginWM(LoginModel(
      inject<AuthorizationInteractor>(),
    ));

abstract class ILoginWM implements IWidgetModel {
  StateNotifier<PhoneLoginForm> get phoneLoginForm;

  TextEditingController get phoneTextEditingController;

  MaskTextInputFormatter get phoneFormatter;

  Future<void> submitPhoneLogin();
}

class LoginWM extends WidgetModel<LoginScreen, LoginModel> implements ILoginWM {
  LoginWM(
    LoginModel model,
  ) : super(model);

  @override
  final StateNotifier<PhoneLoginForm> phoneLoginForm = StateNotifier(
    initValue: PhoneLoginForm(),
  );

  @override
  final MaskTextInputFormatter phoneFormatter = MaskTextInputFormatter(
    mask: '+7(###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  late final TextEditingController phoneTextEditingController =
      createTextEditingController(
    initialText: '+7',
    onChanged: _phoneTextChanged,
  );

  void _phoneTextChanged(String phoneText) {
    PhoneFormzInput phone = PhoneFormzInput.dirty(phoneText);

    phoneLoginForm.accept(phoneLoginForm.value!.copyWith(
      phone: phone,
    ));
  }

  @override
  Future<void> submitPhoneLogin() async {
    String phoneNumber = phoneLoginForm.value!.phone.value;
    String cleanPhoneNumber = phoneFormatter.unmaskText(phoneNumber);
    
    // Формируем номер для Казахстана в формате 77088431748 (без плюса)
    if (cleanPhoneNumber.startsWith('7') && cleanPhoneNumber.length == 10) {
      // Если номер начинается с 7 и длина 10 символов, это уже правильный формат
      cleanPhoneNumber = '7' + cleanPhoneNumber;
    } else if (cleanPhoneNumber.length == 10 && !cleanPhoneNumber.startsWith('7')) {
      // Если длина 10 символов но не начинается с 7, добавляем 77
      cleanPhoneNumber = '77' + cleanPhoneNumber;
    } else if (cleanPhoneNumber.startsWith('+7')) {
      // Убираем плюс если есть
      cleanPhoneNumber = cleanPhoneNumber.substring(1);
    } else if (cleanPhoneNumber.startsWith('87') && cleanPhoneNumber.length == 11) {
      // Заменяем 8 на 7 для казахстанских номеров
      cleanPhoneNumber = '7' + cleanPhoneNumber.substring(1);
    }
    
    logger.i('Starting login process for phone: $cleanPhoneNumber');
    print('🔄 Starting SMS request for phone: $cleanPhoneNumber');
    
    final result = await NetworkUtils.executeWithErrorHandling(
      () => model.signInByPhone(phone: cleanPhoneNumber),
      customErrorMessage: 'Не удалось отправить SMS. Проверьте номер телефона и подключение к интернету.',
    );
    
    if (result != null) {
      logger.i('Login response received: ${result.toJson()}');
      print('✅ SMS request successful!');

      // Логируем SMS код из ответа для отладки
      if (result.smsCode != null) {
        logger.i('SMS Code received: ${result.smsCode}');
        print('🔑 SMS CODE FOR TESTING: ${result.smsCode}');
      } else {
        logger.w('No SMS code in response');
        print('⚠️ No SMS code received in response');
      }

      print('🚀 Navigating to OTP screen...');
      Routes.router.navigate(
        Routes.otpScreen,
        args: OtpScreenArgs(
          phoneNumber: phoneNumber,
          debugSmsCode: result.smsCode,
        ),
      );
      print('✅ Navigation completed');
    }
  }
}
