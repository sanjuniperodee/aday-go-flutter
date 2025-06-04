import 'package:elementary/elementary.dart';

import '../../interactors/authorization_interactor.dart';
import '../../models/sign_in/sign_in_by_phone_confirm_code_response_model.dart';

class OtpModel extends ElementaryModel {
  final AuthorizationInteractor _authorizationInteractor;

  OtpModel(
    this._authorizationInteractor,
  ) : super();

  Future<SignInByPhoneConfirmCodeResponseModel> signInByPhoneConfirmCode({
    required String phone,
    required String smsCode,
  }) =>
      _authorizationInteractor.signInByPhoneConfirmCode(
        phone: phone,
        smsCode: smsCode,
      );
}
