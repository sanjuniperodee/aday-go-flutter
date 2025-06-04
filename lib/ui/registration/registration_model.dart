import 'package:elementary/elementary.dart';

import '../../interactors/authorization_interactor.dart';
import '../../models/sign_in/sign_in_by_phone_confirm_code_response_model.dart';

class RegistrationModel extends ElementaryModel {
  final AuthorizationInteractor _authorizationInteractor;

  RegistrationModel(
    this._authorizationInteractor,
  ) : super();

  Future<SignInByPhoneConfirmCodeResponseModel> signUpByPhone({
    required String phone,
    required String firstName,
    required String lastName,
  }) =>
      _authorizationInteractor.signUpByPhone(
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );
}
