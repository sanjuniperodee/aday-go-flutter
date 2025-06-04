import 'package:json_annotation/json_annotation.dart';

part 'sign_in_by_phone_response_model.g.dart';

@JsonSerializable()
class SignInByPhoneResponseModel {
  @JsonKey(name: 'smscode')
  final String? smsCode;

  const SignInByPhoneResponseModel({
    this.smsCode,
  });

  factory SignInByPhoneResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SignInByPhoneResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SignInByPhoneResponseModelToJson(this);
}
