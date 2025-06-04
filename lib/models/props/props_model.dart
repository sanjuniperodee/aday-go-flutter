import 'package:json_annotation/json_annotation.dart';

part 'props_model.g.dart';

@JsonSerializable()
class PropsModel {
  final String? value;

  const PropsModel({
    this.value,
  });

  factory PropsModel.fromJson(Map<String, dynamic> json) =>
      _$PropsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropsModelToJson(this);
}
