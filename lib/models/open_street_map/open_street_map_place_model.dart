import 'package:aktau_go/models/open_street_map/open_street_map_place_address_model.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:json_annotation/json_annotation.dart';

part 'open_street_map_place_model.g.dart';

@JsonSerializable()
class OpenStreetMapPlaceModel {
  final int? place_id;
  final String? name;
  final String? type;
  final String? addresstype;
  final OpenStreetMapPlaceAddressModel? address;
  @JsonKey(fromJson: _stringToNum)
  final double? lat;
  @JsonKey(fromJson: _stringToNum)
  final double? lon;

  const OpenStreetMapPlaceModel({
    this.place_id,
    this.name,
    this.type,
    this.addresstype,
    this.address,
    this.lat,
    this.lon,
  });

  factory OpenStreetMapPlaceModel.fromJson(Map<String, dynamic> json) =>
      _$OpenStreetMapPlaceModelFromJson(json);

  Map<String, dynamic> toJson() => _$OpenStreetMapPlaceModelToJson(this);

  static double _stringToNum(dynamic json) {
    if (json == null) return 0.0;
    
    if (json is num) {
      // Если это уже число, просто возвращаем его как double
      return json.toDouble();
    } else if (json is String) {
      // Если это строка, пытаемся преобразовать в double
      return double.tryParse(json) ?? 0.0;
    } else {
      // Если это что-то другое, возвращаем 0.0
      logger.w('Неизвестный тип для конвертации в число: ${json.runtimeType}');
      return 0.0;
    }
  }
}
