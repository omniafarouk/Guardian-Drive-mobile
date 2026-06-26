class TripLocation {
  final double latitude;
  final double longitude;
  final int locationId;

  TripLocation({
    required this.latitude,
    required this.longitude,
    required this.locationId,
  });

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationId: (json['locationId'] as num).toInt(),
    );
  }
}
