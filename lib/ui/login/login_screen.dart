import 'package:aktau_go/forms/phone_login_form.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../widgets/rounded_text_field.dart';
import 'package:elementary/elementary.dart';

import 'login_wm.dart';

class LoginScreen extends ElementaryWidget<ILoginWM> {
  LoginScreen({
    Key? key,
  }) : super(
          (context) => defaultLoginWMFactory(context),
        );

  @override
  Widget build(ILoginWM wm) {
    return StateNotifierBuilder(
      listenableState: wm.phoneLoginForm,
      builder: (
        context,
        PhoneLoginForm? phoneLoginForm,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Вход',
                            style: text500Size24Greyscale90,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Введите свой WhatsApp номер',
                            style: text400Size12Greyscale50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RoundedTextField(
                          controller: wm.phoneTextEditingController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            wm.phoneFormatter,
                          ],
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton.primary(
                          onPressed: phoneLoginForm!.isValid
                              ? wm.submitPhoneLogin
                              : null,
                          text: 'Получить код WhatsApp',
                          textStyle: text400Size16White,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            launchUrlString('http://doner24aktau.kz/jjj.html');
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Политика конфиденциальности',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.lightBlue,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
