import 'package:aktau_go/forms/inputs/phone_formz_input.dart';
import 'package:aktau_go/interactors/authorization_interactor.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:aktau_go/utils/text_editing_controller.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:seafarer/seafarer.dart';

import '../../utils/utils.dart';
import '../../forms/profile_registration_form.dart';
import './registration_model.dart';
import './registration_screen.dart';

defaultRegistrationWMFactory(BuildContext context) =>
    RegistrationWM(RegistrationModel(
      inject<AuthorizationInteractor>(),
    ));

abstract class IRegistrationWM implements IWidgetModel {
  StateNotifier<ProfileRegistrationForm> get profileRegistrationForm;

  TextEditingController get firstNameTextEditingController;

  TextEditingController get lastNameTextEditingController;

  TextEditingController get phoneTextEditingController;

  Future<void> submitProfileRegistration();
}

class RegistrationWM extends WidgetModel<RegistrationScreen, RegistrationModel>
    implements IRegistrationWM {
  RegistrationWM(
    RegistrationModel model,
  ) : super(model);

  final MaskTextInputFormatter phoneFormatter = MaskTextInputFormatter(
    mask: '+#(###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
    initialText: '+7',
  );

  @override
  late final TextEditingController firstNameTextEditingController =
      createTextEditingController(
    initialText: '',
    onChanged: _firstNameTextChanged,
  );

  @override
  late final TextEditingController lastNameTextEditingController =
      createTextEditingController(
    initialText: '',
    onChanged: _lastNameTextChanged,
  );

  @override
  late final TextEditingController phoneTextEditingController =
      createTextEditingController(
    initialText: widget.phoneNumber,
    // onChanged: _phoneTextChanged,
  );

  void _firstNameTextChanged(String firstName) {
    profileRegistrationForm.accept(
      profileRegistrationForm.value!.copyWith(
        firstName: firstName,
      ),
    );
  }

  void _lastNameTextChanged(String lastName) {
    profileRegistrationForm.accept(
      profileRegistrationForm.value!.copyWith(
        lastName: lastName,
      ),
    );
  }

  @override
  late final StateNotifier<ProfileRegistrationForm> profileRegistrationForm =
      StateNotifier(
    initValue: ProfileRegistrationForm(
      phone: PhoneFormzInput.dirty(widget.phoneNumber),
    ),
  );

  @override
  Future<void> submitProfileRegistration() async {
    ProfileRegistrationForm profileRegistrationFormValue =
        profileRegistrationForm.value!;

    try {
      final response = await model.signUpByPhone(
        phone:
            phoneFormatter.unmaskText(profileRegistrationFormValue.phone.value),
        firstName: profileRegistrationFormValue.firstName,
        lastName: profileRegistrationFormValue.lastName,
      );

      Routes.router.navigate(
        Routes.mainScreen,
        navigationType: NavigationType.pushAndRemoveUntil,
        removeUntilPredicate: (route) => false,
      );
    } on Exception catch (e) {
      logger.e(e);
    }
  }
}
