// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapbox_feature_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapboxGeoCodingResponse _$MapboxGeoCodingResponseFromJson(
        Map<String, dynamic> json) =>
    MapboxGeoCodingResponse(
      type: json['type'] as String?,
      query: (json['query'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map(
              (e) => MapboxSuggestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      attribution: json['attribution'] as String?,
    );

Map<String, dynamic> _$MapboxGeoCodingResponseToJson(
        MapboxGeoCodingResponse instance) =>
    <String, dynamic>{
      'type': instance.type,
      'query': instance.query,
      'suggestions': instance.suggestions,
      'attribution': instance.attribution,
    };

MapboxFeatureDetailResponse _$MapboxFeatureDetailResponseFromJson(
        Map<String, dynamic> json) =>
    MapboxFeatureDetailResponse(
      type: json['type'] as String?,
      query: (json['query'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => MapboxFeatureModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      attribution: json['attribution'] as String?,
    );

Map<String, dynamic> _$MapboxFeatureDetailResponseToJson(
        MapboxFeatureDetailResponse instance) =>
    <String, dynamic>{
      'type': instance.type,
      'query': instance.query,
      'features': instance.features,
      'attribution': instance.attribution,
    };

MapboxFeatureModel _$MapboxFeatureModelFromJson(Map<String, dynamic> json) =>
    MapboxFeatureModel(
      id: json['id'] as String?,
      type: json['type'] as String?,
      placeType: (json['placeType'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      relevance: (json['relevance'] as num?)?.toInt(),
      properties: json['properties'] == null
          ? null
          : PropertiesModel.fromJson(
              json['properties'] as Map<String, dynamic>),
      text: json['text'] as String?,
      placeName: json['placeName'] as String?,
      bbox: (json['bbox'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      center: (json['center'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      geometry: json['geometry'] == null
          ? null
          : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
      context: (json['context'] as List<dynamic>?)
          ?.map((e) => ContextModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MapboxFeatureModelToJson(MapboxFeatureModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'placeType': instance.placeType,
      'relevance': instance.relevance,
      'properties': instance.properties,
      'text': instance.text,
      'placeName': instance.placeName,
      'bbox': instance.bbox,
      'center': instance.center,
      'geometry': instance.geometry,
      'context': instance.context,
    };

Geometry _$GeometryFromJson(Map<String, dynamic> json) => Geometry(
      type: json['type'] as String?,
      coordinates: (json['coordinates'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$GeometryToJson(Geometry instance) => <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };

ContextModel _$ContextModelFromJson(Map<String, dynamic> json) => ContextModel(
      id: json['id'] as String?,
      shortCode: json['shortCode'] as String?,
      wikidata: json['wikidata'] as String?,
      mapboxId: json['mapboxId'] as String?,
      text: json['text'] as String?,
    );

Map<String, dynamic> _$ContextModelToJson(ContextModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shortCode': instance.shortCode,
      'wikidata': instance.wikidata,
      'mapboxId': instance.mapboxId,
      'text': instance.text,
    };

PropertiesModel _$PropertiesModelFromJson(Map<String, dynamic> json) =>
    PropertiesModel(
      shortCode: json['shortCode'] as String?,
      wikidata: json['wikidata'] as String?,
      mapboxId: json['mapbox_id'] as String?,
      full_address: json['full_address'] as String?,
      coordinates: json['coordinates'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PropertiesModelToJson(PropertiesModel instance) =>
    <String, dynamic>{
      'shortCode': instance.shortCode,
      'wikidata': instance.wikidata,
      'mapbox_id': instance.mapboxId,
      'full_address': instance.full_address,
      'coordinates': instance.coordinates,
    };

MapboxSuggestionModel _$MapboxSuggestionModelFromJson(
        Map<String, dynamic> json) =>
    MapboxSuggestionModel(
      name: json['name'] as String?,
      mapboxId: json['mapbox_id'] as String?,
      featureType: json['feature_type'] as String?,
      address: json['address'] as String?,
      fullAddress: json['full_address'] as String?,
      placeFormatted: json['place_formatted'] as String?,
      language: json['language'] as String?,
      maki: json['maki'] as String?,
      poiCategory: (json['poi_category'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      poiCategoryIds: (json['poi_category_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      namePreferred: json['namePreferred'] as String?,
    );

Map<String, dynamic> _$MapboxSuggestionModelToJson(
        MapboxSuggestionModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'mapbox_id': instance.mapboxId,
      'feature_type': instance.featureType,
      'address': instance.address,
      'full_address': instance.fullAddress,
      'place_formatted': instance.placeFormatted,
      'language': instance.language,
      'maki': instance.maki,
      'poi_category': instance.poiCategory,
      'poi_category_ids': instance.poiCategoryIds,
      'namePreferred': instance.namePreferred,
    };
