class OpenStreetMapPlaceDomain {
  final int placeId;
  final String displayName;
  final String type;
  final String addressType;
  final double lat;
  final double lon;

  const OpenStreetMapPlaceDomain({
    int? place_id,
    String? display_name,
    String? type,
    String? addresstype,
    double? lat,
    double? lon,
  })  : placeId = place_id ?? 0,
        displayName = display_name ?? '',
        type = type ?? '',
        addressType = addresstype ?? '',
        lat = lat ?? 0,
        lon = lon ?? 0;
}
