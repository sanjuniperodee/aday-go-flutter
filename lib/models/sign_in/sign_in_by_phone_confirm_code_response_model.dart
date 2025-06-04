import 'package:json_annotation/json_annotation.dart';

part 'sign_in_by_phone_confirm_code_response_model.g.dart';

@JsonSerializable()
class SignInByPhoneConfirmCodeResponseModel {
  final String? token;
  final String? refreshToken;

  const SignInByPhoneConfirmCodeResponseModel({
    this.token,
    this.refreshToken,
  });

  factory SignInByPhoneConfirmCodeResponseModel.fromJson(
          Map<String, dynamic> json) =>
      _$SignInByPhoneConfirmCodeResponseModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$SignInByPhoneConfirmCodeResponseModelToJson(this);
}
