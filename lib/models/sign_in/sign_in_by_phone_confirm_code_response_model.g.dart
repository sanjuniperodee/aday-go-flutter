// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_by_phone_confirm_code_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInByPhoneConfirmCodeResponseModel
    _$SignInByPhoneConfirmCodeResponseModelFromJson(
            Map<String, dynamic> json) =>
        SignInByPhoneConfirmCodeResponseModel(
          token: json['token'] as String?,
          refreshToken: json['refreshToken'] as String?,
        );

Map<String, dynamic> _$SignInByPhoneConfirmCodeResponseModelToJson(
        SignInByPhoneConfirmCodeResponseModel instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
    };
