class MapTilerGeoCodingResponse {
  String? type;
  List<Features>? features;
  List<double>? query;
  String? attribution;

  MapTilerGeoCodingResponse(
      {this.type, this.features, this.query, this.attribution});

  MapTilerGeoCodingResponse.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(new Features.fromJson(v));
      });
    }
    query = json['query'].cast<double>();
    attribution = json['attribution'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.features != null) {
      data['features'] = this.features!.map((v) => v.toJson()).toList();
    }
    data['query'] = this.query;
    data['attribution'] = this.attribution;
    return data;
  }
}

class Features {
  String? type;
  Properties? properties;
  Geometry? geometry;
  List<double>? bbox;
  List<double>? center;
  String? placeName;
  List<String>? placeType;
  num? relevance;
  List<Context>? context;
  String? id;
  String? text;

  Features(
      {this.type,
      this.properties,
      this.geometry,
      this.bbox,
      this.center,
      this.placeName,
      this.placeType,
      this.relevance,
      this.context,
      this.id,
      this.text});

  Features.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    properties = json['properties'] != null
        ? new Properties.fromJson(json['properties'])
        : null;
    geometry = json['geometry'] != null
        ? new Geometry.fromJson(json['geometry'])
        : null;
    bbox = json['bbox'].cast<double>();
    center = json['center'].cast<double>();
    placeName = json['place_name'];
    placeType = json['place_type'].cast<String>();
    relevance = json['relevance'];
    if (json['context'] != null) {
      context = <Context>[];
      json['context'].forEach((v) {
        context!.add(new Context.fromJson(v));
      });
    }
    id = json['id'];
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.properties != null) {
      data['properties'] = this.properties!.toJson();
    }
    if (this.geometry != null) {
      data['geometry'] = this.geometry!.toJson();
    }
    data['bbox'] = this.bbox;
    data['center'] = this.center;
    data['place_name'] = this.placeName;
    data['place_type'] = this.placeType;
    data['relevance'] = this.relevance;
    if (this.context != null) {
      data['context'] = this.context!.map((v) => v.toJson()).toList();
    }
    data['id'] = this.id;
    data['text'] = this.text;
    return data;
  }
}

class Properties {
  String? ref;
  String? countryCode;
  String? kind;
  String? osmPlaceType;

  Properties({this.ref, this.countryCode, this.kind, this.osmPlaceType});

  Properties.fromJson(Map<String, dynamic> json) {
    ref = json['ref'];
    countryCode = json['country_code'];
    kind = json['kind'];
    osmPlaceType = json['osm:place_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ref'] = this.ref;
    data['country_code'] = this.countryCode;
    data['kind'] = this.kind;
    data['osm:place_type'] = this.osmPlaceType;
    return data;
  }
}

class Geometry {
  String? type;
  List<double>? coordinates;

  Geometry({this.type, this.coordinates});

  Geometry.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = json['coordinates'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    return data;
  }
}

class Context {
  String? ref;
  String? countryCode;
  String? id;
  String? text;
  String? kind;
  String? osmPlaceType;

  Context(
      {this.ref,
      this.countryCode,
      this.id,
      this.text,
      this.kind,
      this.osmPlaceType});

  Context.fromJson(Map<String, dynamic> json) {
    ref = json['ref'];
    countryCode = json['country_code'];
    id = json['id'];
    text = json['text'];
    kind = json['kind'];
    osmPlaceType = json['osm:place_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ref'] = this.ref;
    data['country_code'] = this.countryCode;
    data['id'] = this.id;
    data['text'] = this.text;
    data['kind'] = this.kind;
    data['osm:place_type'] = this.osmPlaceType;
    return data;
  }
}
