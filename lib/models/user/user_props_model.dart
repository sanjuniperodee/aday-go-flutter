import 'package:json_annotation/json_annotation.dart';

part 'user_props_model.g.dart';

@JsonSerializable()
class UserPropsModel {
  final String? phone;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? session;

  const UserPropsModel({
    this.phone,
    this.name,
    this.firstName,
    this.lastName,
    this.middleName,
    this.session,
  });

  factory UserPropsModel.fromJson(Map<String, dynamic> json) =>
      _$UserPropsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserPropsModelToJson(this);
}
