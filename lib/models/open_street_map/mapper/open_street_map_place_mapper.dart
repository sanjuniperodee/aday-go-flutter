import 'package:aktau_go/domains/open_street_map/open_street_map_place_domain.dart';
import 'package:aktau_go/models/open_street_map/open_street_map_place_model.dart';

OpenStreetMapPlaceDomain openStreetMapPlaceMapper(
  OpenStreetMapPlaceModel model,
) =>
    OpenStreetMapPlaceDomain(
      place_id: model.place_id,
      display_name: model.name,
      type: model.type,
      addresstype: model.addresstype,
      lat: model.lat,
      lon: model.lon,
    );

List<OpenStreetMapPlaceDomain> openStreetMapPlaceListMapper(
  List<OpenStreetMapPlaceModel> list,
) =>
    list.map((e) => openStreetMapPlaceMapper(e)).toList();
