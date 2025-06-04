import 'package:elementary/elementary.dart';

import '../../interactors/authorization_interactor.dart';
import '../../models/sign_in/sign_in_by_phone_confirm_code_response_model.dart';
import '../../models/sign_in/sign_in_by_phone_response_model.dart';

class LoginModel extends ElementaryModel {
  final AuthorizationInteractor _authorizationInteractor;

  LoginModel(
    this._authorizationInteractor,
  ) : super();

  Future<SignInByPhoneResponseModel> signInByPhone({
    required String phone,
  }) =>
      _authorizationInteractor.signInByPhone(
        phone: phone,
      );

  Future<SignInByPhoneConfirmCodeResponseModel> signInByPhoneConfirmCode({
    required String phone,
    required String smsCode,
  }) =>
      _authorizationInteractor.signInByPhoneConfirmCode(
        phone: phone,
        smsCode: smsCode,
      );
}
