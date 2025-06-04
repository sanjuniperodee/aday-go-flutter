import 'package:injectable/injectable.dart';

import '../models/sign_in/sign_in_by_phone_confirm_code_response_model.dart';
import '../models/sign_in/sign_in_by_phone_response_model.dart';
import './common/rest_client.dart';
import './session_interactor.dart';

abstract class IAuthorizationInteractor {
  Future<SignInByPhoneResponseModel> signInByPhone({
    required String phone,
  });

  Future<SignInByPhoneConfirmCodeResponseModel> signInByPhoneConfirmCode({
    required String phone,
    required String smsCode,
  });

  Future<SignInByPhoneConfirmCodeResponseModel> signUpByPhone({
    required String phone,
    required String firstName,
    required String lastName,
  });
}

@singleton
class AuthorizationInteractor extends IAuthorizationInteractor {
  final RestClient _restClient;
  final SessionInteractor _sessionInteractor;

  AuthorizationInteractor(
    this._restClient,
    this._sessionInteractor,
  );

  @override
  Future<SignInByPhoneResponseModel> signInByPhone({
    required String phone,
  }) =>
      _restClient.signInByPhone(
        phone: phone,
      );

  @override
  Future<SignInByPhoneConfirmCodeResponseModel> signInByPhoneConfirmCode({
    required String phone,
    required String smsCode,
  }) async {
    final response = await _restClient.signInByPhoneConfirmCode(
      phone: phone,
      smsCode: smsCode,
    );

    if (response.token != null) {
      _sessionInteractor.setAccessToken(response.token!);
    }

    if (response.refreshToken != null) {
      _sessionInteractor.setRefreshToken(response.refreshToken!);
    }

    return response;
  }

  @override
  Future<SignInByPhoneConfirmCodeResponseModel> signUpByPhone({
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _restClient.signUpByPhone(
      phone: phone,
      firstName: firstName,
      lastName: lastName,
    );

    if (response.token != null) {
      _sessionInteractor.setAccessToken(response.token!);
    }

    if (response.refreshToken != null) {
      _sessionInteractor.setRefreshToken(response.refreshToken!);
    }

    return response;
  }
}
