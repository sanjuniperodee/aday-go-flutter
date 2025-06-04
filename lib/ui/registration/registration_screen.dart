import 'package:aktau_go/forms/profile_registration_form.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/ui/widgets/rounded_text_field.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:seafarer/seafarer.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import './registration_wm.dart';

class RegistrationScreen extends ElementaryWidget<IRegistrationWM> {
  final String phoneNumber;

  RegistrationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(
          (context) => defaultRegistrationWMFactory(context),
        );

  @override
  Widget build(IRegistrationWM wm) {
    return StateNotifierBuilder(
        listenableState: wm.profileRegistrationForm,
        builder: (
          context,
          ProfileRegistrationForm? profileRegistrationForm,
        ) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Регистрация',
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
            body: ListView(
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
                            'Заполните анкету',
                            style: text500Size24Greyscale90,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Выберите, в какой категории вы будете работать',
                            style: text400Size12Greyscale50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        RoundedTextField(
                          backgroundColor: Colors.white,
                          hintText: 'Имя',
                          hintStyle: text400Size16Greyscale30,
                          controller: wm.firstNameTextEditingController,
                        ),
                        const SizedBox(height: 8),
                        RoundedTextField(
                          backgroundColor: Colors.white,
                          hintText: 'Фамилия',
                          hintStyle: text400Size16Greyscale30,
                          controller: wm.lastNameTextEditingController,
                        ),
                        const SizedBox(height: 8),
                        RoundedTextField(
                          backgroundColor: Colors.white,
                          hintText: 'Телефон',
                          hintStyle: text400Size16Greyscale30,
                          enabled: false,
                          controller: wm.phoneTextEditingController,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton.primary(
                            onPressed: profileRegistrationForm!.isValid
                                ? wm.submitProfileRegistration
                                : null,
                            text: 'Продолжить',
                            textStyle: text400Size16White,
                          ),
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

class RegistrationScreenArgs extends BaseArguments {
  final String phoneNumber;

  RegistrationScreenArgs({
    required this.phoneNumber,
  });
}
