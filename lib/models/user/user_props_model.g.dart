// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_props_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPropsModel _$UserPropsModelFromJson(Map<String, dynamic> json) =>
    UserPropsModel(
      phone: json['phone'] as String?,
      name: json['name'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      middleName: json['middleName'] as String?,
      session: json['session'] as String?,
    );

Map<String, dynamic> _$UserPropsModelToJson(UserPropsModel instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'name': instance.name,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'middleName': instance.middleName,
      'session': instance.session,
    };
