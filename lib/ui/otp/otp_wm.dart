import 'dart:async';

import 'package:aktau_go/forms/inputs/otp_formz_input.dart';
import 'package:aktau_go/forms/inputs/phone_formz_input.dart';
import 'package:aktau_go/forms/otp_confirm_form.dart';
import 'package:aktau_go/interactors/authorization_interactor.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:aktau_go/utils/text_editing_controller.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:seafarer/seafarer.dart';

import '../registration/registration_screen.dart';
import './otp_model.dart';
import './otp_screen.dart';

defaultOtpWMFactory(BuildContext context) => OtpWM(OtpModel(
      inject<AuthorizationInteractor>(),
    ));

abstract class IOtpWM implements IWidgetModel {
  StateNotifier<OtpConfirmForm> get otpConfirmForm;

  StateNotifier<int> get resendSecondsLeft;

  TextEditingController get otpTextEditingController;

  Future<void> submitOtpConfirm();
}

class OtpWM extends WidgetModel<OtpScreen, OtpModel> implements IOtpWM {
  OtpWM(
    OtpModel model,
  ) : super(model);

  Timer? resendTimer;

  @override
  late final StateNotifier<OtpConfirmForm> otpConfirmForm = StateNotifier(
    initValue: OtpConfirmForm(
      phone: PhoneFormzInput.pure(widget.phoneNumber),
    ),
  );

  @override
  final StateNotifier<int> resendSecondsLeft = StateNotifier(
    initValue: 60,
  );

  final MaskTextInputFormatter phoneFormatter = MaskTextInputFormatter(
    mask: '+#(###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
    initialText: '+7',
  );

  @override
  late final TextEditingController otpTextEditingController =
      createTextEditingController(
    initialText: '',
    onChanged: _otpTextChanged,
  );

  @override
  void initWidgetModel() {
    super.initWidgetModel();

    resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      int resendSecondsLeftValue = resendSecondsLeft.value!;
      if (resendSecondsLeftValue > 0) {
        resendSecondsLeft.accept(resendSecondsLeftValue - 1);
      } else {
        timer.cancel();
      }
    });
  }

  void _otpTextChanged(String otpText) {
    OtpFormzInput otp = OtpFormzInput.dirty(
      otpText,
    );

    otpConfirmForm.accept(otpConfirmForm.value!.copyWith(
      otp: otp,
    ));
  }

  @override
  Future<void> submitOtpConfirm() async {
    try {
      String phoneNumber =
          phoneFormatter.unmaskText(otpConfirmForm.value!.phone.value);
      String smsCode = otpConfirmForm.value!.otp.value;

      final response = await model.signInByPhoneConfirmCode(
        phone: phoneNumber,
        smsCode: smsCode,
      );

      /// [response.refreshToken]
      /// User already registered
      if (response.refreshToken != null) {
        Routes.router.navigate(
          Routes.mainScreen,
          navigationType: NavigationType.pushAndRemoveUntil,
          removeUntilPredicate: (route) => false,
        );
      }

      /// Navigate to registration
      else {
        Routes.router.navigate(
          Routes.registrationScreen,
          args: RegistrationScreenArgs(
            phoneNumber: otpConfirmForm.value!.phone.value,
          ),
        );
      }
    } on Exception catch (e) {
      logger.e(e);
    }
  }
}
