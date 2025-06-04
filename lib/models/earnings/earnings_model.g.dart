// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarningsModel _$EarningsModelFromJson(Map<String, dynamic> json) =>
    EarningsModel(
      today: json['today'] as num?,
      thisWeek: json['thisWeek'] as num?,
      thisMonth: json['thisMonth'] as num?,
    );

Map<String, dynamic> _$EarningsModelToJson(EarningsModel instance) =>
    <String, dynamic>{
      'today': instance.today,
      'thisWeek': instance.thisWeek,
      'thisMonth': instance.thisMonth,
    };
