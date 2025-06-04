import 'package:json_annotation/json_annotation.dart';

part 'open_street_map_place_address_model.g.dart';

@JsonSerializable()
class OpenStreetMapPlaceAddressModel {
  final String? house_number;
  final String? road;
  final String? city_district;
  final String? city;
  final String? postcode;
  final String? country;
  final String? country_code;

  const OpenStreetMapPlaceAddressModel({
    this.house_number,
    this.road,
    this.city_district,
    this.city,
    this.postcode,
    this.country,
    this.country_code,
  });

  factory OpenStreetMapPlaceAddressModel.fromJson(Map<String, dynamic> json) =>
      _$OpenStreetMapPlaceAddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$OpenStreetMapPlaceAddressModelToJson(this);
}
