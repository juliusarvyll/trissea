class PlaceDetailsResponse {
  final String? status;
  final PlaceResult? result;

  PlaceDetailsResponse({
    this.status,
    this.result,
  });

  factory PlaceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsResponse(
      status: json['status'] as String?,
      result: json['result'] != null
          ? PlaceResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlaceResult {
  final PlaceDetailsGeometry? geometry;

  PlaceResult({
    this.geometry,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      geometry: json['geometry'] != null
          ? PlaceDetailsGeometry.fromJson(json['geometry'])
          : null,
    );
  }
}

class PlaceDetailsGeometry {
  final PlaceDetailsLocation? location;

  PlaceDetailsGeometry({
    this.location,
  });

  factory PlaceDetailsGeometry.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsGeometry(
      location: json['location'] != null
          ? PlaceDetailsLocation.fromJson(json['location'])
          : null,
    );
  }
}

class PlaceDetailsLocation {
  final double? lat;
  final double? lng;

  PlaceDetailsLocation({
    this.lat,
    this.lng,
  });

  factory PlaceDetailsLocation.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsLocation(
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
    );
  }
}
