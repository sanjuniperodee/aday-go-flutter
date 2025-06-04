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

  static _stringToNum(dynamic json) {
    logger.w('${json is String}');
    return double.tryParse(json as String) ?? 0;
  }
}
