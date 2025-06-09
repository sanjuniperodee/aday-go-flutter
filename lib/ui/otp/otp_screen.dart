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
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: Text(
                'Подтверждение',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Иконка с анимацией
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.sms,
                              size: 40,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 32),
                          
                          // Заголовок
                          Text(
                            'Введите код',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Подзаголовок с номером телефона
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(text: 'Код отправлен в WhatsApp на номер\n'),
                                TextSpan(
                                  text: phoneNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          
                          // Поле ввода кода
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: OtpCodeTextField(
                              controller: wm.otpTextEditingController,
                            ),
                          ),
                          
                          // Показываем SMS код для отладки
                          if (debugSmsCode != null) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bug_report,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Код для тестирования: $debugSmsCode',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          SizedBox(height: 32),
                          
                          // Кнопка входа
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: otpConfirmForm!.isValid
                                  ? wm.submitOtpConfirm
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                              child: Text(
                                'Войти',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Блок повторной отправки
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Не получили код?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (resendSecondsLeft == 0)
                                  InkWell(
                                    onTap: () {
                                      // TODO: Добавить функционал повторной отправки
                                    },
                                    child: Text(
                                      'Отправить ещё раз',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    'Повторная отправка через ${resendSecondsLeft}с',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
