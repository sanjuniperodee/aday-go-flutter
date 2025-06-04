import 'package:aktau_go/forms/otp_confirm_form.dart';
import 'package:aktau_go/interactors/session_interactor.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:seafarer/seafarer.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../router/router.dart';
import '../widgets/primary_button.dart';
import './widgets/otp_code_field.dart';
import 'otp_wm.dart';

class OtpScreen extends ElementaryWidget<IOtpWM> {
  final String phoneNumber;
  final String? debugSmsCode;

  OtpScreen({
    Key? key,
    required this.phoneNumber,
    this.debugSmsCode,
  }) : super(
          (context) => defaultOtpWMFactory(context),
        );

  @override
  Widget build(IOtpWM wm) {
    return DoubleSourceBuilder(
        firstSource: wm.otpConfirmForm,
        secondSource: wm.resendSecondsLeft,
        builder: (
          context,
          OtpConfirmForm? otpConfirmForm,
          int? resendSecondsLeft,
        ) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Вход',
                style: text400Size16Black,
              ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  color: greyscale10,
                ),
              ),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Подтвердите номер',
                            style: TextStyle(
                              color: Color(0xFF261619),
                              fontSize: 24,
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w500,
                              height: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'На WhatsApp номер ${phoneNumber} был отправлен код',
                            style: text400Size12Greyscale50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OtpCodeTextField(
                          controller: wm.otpTextEditingController,
                        ),
                        // Показываем SMS код для отладки
                        if (debugSmsCode != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              '🔑 Код для тестирования: $debugSmsCode',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        PrimaryButton.primary(
                          onPressed: otpConfirmForm!.isValid
                              ? wm.submitOtpConfirm
                              : null,
                          text: 'Войти',
                          textStyle: text400Size16White,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Не получили код?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 12,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                                height: 0.11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '•',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF261619),
                                fontSize: 12,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                                height: 0.11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (resendSecondsLeft == 0)
                              Text(
                                'Отправить ещё раз',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF261619),
                                  fontSize: 12,
                                  fontFamily: 'Rubik',
                                  fontWeight: FontWeight.w500,
                                  height: 0.11,
                                ),
                              )
                            else
                              Text(
                                'через ${resendSecondsLeft}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF261619),
                                  fontSize: 12,
                                  fontFamily: 'Rubik',
                                  fontWeight: FontWeight.w500,
                                  height: 0.11,
                                ),
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }
}

class OtpScreenArgs extends BaseArguments {
  final String phoneNumber;
  final String? debugSmsCode;

  OtpScreenArgs({
    required this.phoneNumber,
    this.debugSmsCode,
  });
}
