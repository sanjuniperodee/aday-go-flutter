// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_street_map_place_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenStreetMapPlaceModel _$OpenStreetMapPlaceModelFromJson(
        Map<String, dynamic> json) =>
    OpenStreetMapPlaceModel(
      place_id: (json['place_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      type: json['type'] as String?,
      addresstype: json['addresstype'] as String?,
      address: json['address'] == null
          ? null
          : OpenStreetMapPlaceAddressModel.fromJson(
              json['address'] as Map<String, dynamic>),
      lat: OpenStreetMapPlaceModel._stringToNum(json['lat']),
      lon: OpenStreetMapPlaceModel._stringToNum(json['lon']),
    );

Map<String, dynamic> _$OpenStreetMapPlaceModelToJson(
        OpenStreetMapPlaceModel instance) =>
    <String, dynamic>{
      'place_id': instance.place_id,
      'name': instance.name,
      'type': instance.type,
      'addresstype': instance.addresstype,
      'address': instance.address,
      'lat': instance.lat,
      'lon': instance.lon,
    };
