import 'package:json_annotation/json_annotation.dart';

part 'earnings_model.g.dart';

@JsonSerializable()
class EarningsModel {
  final num? today;
  final num? thisWeek;
  final num? thisMonth;

  const EarningsModel({
    this.today,
    this.thisWeek,
    this.thisMonth,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) =>
      _$EarningsModelFromJson(json);

  Map<String, dynamic> toJson() => _$EarningsModelToJson(this);
}
