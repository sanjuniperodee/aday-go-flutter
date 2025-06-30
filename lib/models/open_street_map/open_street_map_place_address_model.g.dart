// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_street_map_place_address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenStreetMapPlaceAddressModel _$OpenStreetMapPlaceAddressModelFromJson(
        Map<String, dynamic> json) =>
    OpenStreetMapPlaceAddressModel(
      house_number: json['house_number'] as String?,
      road: json['road'] as String?,
      city_district: json['city_district'] as String?,
      city: json['city'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
      country_code: json['country_code'] as String?,
    );

Map<String, dynamic> _$OpenStreetMapPlaceAddressModelToJson(
        OpenStreetMapPlaceAddressModel instance) =>
    <String, dynamic>{
      'house_number': instance.house_number,
      'road': instance.road,
      'city_district': instance.city_district,
      'city': instance.city,
      'postcode': instance.postcode,
      'country': instance.country,
      'country_code': instance.country_code,
    };
