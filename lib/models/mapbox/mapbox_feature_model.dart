import 'package:json_annotation/json_annotation.dart';

part 'mapbox_feature_model.g.dart';

@JsonSerializable()
class MapboxGeoCodingResponse {
  String? type;
  List<double>? query;
  List<MapboxSuggestionModel>? suggestions;
  String? attribution;

  MapboxGeoCodingResponse({
    this.type,
    this.query,
    this.suggestions,
    this.attribution,
  });

  factory MapboxGeoCodingResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$MapboxGeoCodingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MapboxGeoCodingResponseToJson(this);
}

@JsonSerializable()
class MapboxFeatureDetailResponse {
  String? type;
  List<double>? query;
  List<MapboxFeatureModel>? features;
  String? attribution;

  MapboxFeatureDetailResponse({
    this.type,
    this.query,
    this.features,
    this.attribution,
  });

  factory MapboxFeatureDetailResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$MapboxFeatureDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MapboxFeatureDetailResponseToJson(this);
}

@JsonSerializable()
class MapboxFeatureModel {
  final String? id;
  final String? type;
  final List<String>? placeType;
  final int? relevance;
  final PropertiesModel? properties;
  final String? text;
  final String? placeName;
  final List<double>? bbox;
  final List<double>? center;
  final Geometry? geometry;
  final List<ContextModel>? context;

  const MapboxFeatureModel({
    this.id,
    this.type,
    this.placeType,
    this.relevance,
    this.properties,
    this.text,
    this.placeName,
    this.bbox,
    this.center,
    this.geometry,
    this.context,
  });

  factory MapboxFeatureModel.fromJson(Map<String, dynamic> json) =>
      _$MapboxFeatureModelFromJson(json);

  Map<String, dynamic> toJson() => _$MapboxFeatureModelToJson(this);
}

@JsonSerializable()
class Geometry {
  String? type;
  List<double>? coordinates;

  Geometry({
    this.type,
    this.coordinates,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) =>
      _$GeometryFromJson(json);

  Map<String, dynamic> toJson() => _$GeometryToJson(this);
}

@JsonSerializable()
class ContextModel {
  String? id;
  String? shortCode;
  String? wikidata;
  String? mapboxId;
  String? text;

  ContextModel({
    this.id,
    this.shortCode,
    this.wikidata,
    this.mapboxId,
    this.text,
  });

  factory ContextModel.fromJson(Map<String, dynamic> json) =>
      _$ContextModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContextModelToJson(this);
}

@JsonSerializable()
class PropertiesModel {
  String? shortCode;
  String? wikidata;
  @JsonKey(name: 'mapbox_id')
  String? mapboxId;
  String? full_address;
  Map<String, dynamic>? coordinates;

  PropertiesModel({
    this.shortCode,
    this.wikidata,
    this.mapboxId,
    this.full_address,
    this.coordinates,
  });

  factory PropertiesModel.fromJson(Map<String, dynamic> json) =>
      _$PropertiesModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertiesModelToJson(this);
}

@JsonSerializable()
class MapboxSuggestionModel {
  final String? name;
  @JsonKey(name: 'mapbox_id')
  final String? mapboxId;
  @JsonKey(name: 'feature_type')
  final String? featureType;
  final String? address;
  @JsonKey(name: 'full_address')
  final String? fullAddress;
  @JsonKey(name: 'place_formatted')
  final String? placeFormatted;
  // final Context? context;
  final String? language;
  final String? maki;
  @JsonKey(name: 'poi_category')
  final List<String>? poiCategory;
  @JsonKey(name: 'poi_category_ids')
  final List<String>? poiCategoryIds;

  // final ExternalIds? externalIds;
  // final Metadata? metadata;
  final String? namePreferred;

  MapboxSuggestionModel({
    this.name,
    this.mapboxId,
    this.featureType,
    this.address,
    this.fullAddress,
    this.placeFormatted,
    // this.context,
    this.language,
    this.maki,
    this.poiCategory,
    this.poiCategoryIds,
    // this.externalIds,
    // this.metadata,
    this.namePreferred,
  });

  factory MapboxSuggestionModel.fromJson(Map<String, dynamic> json) =>
      _$MapboxSuggestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$MapboxSuggestionModelToJson(this);
}
