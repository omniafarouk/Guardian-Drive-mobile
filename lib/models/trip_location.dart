class TripLocation {
  final double latitude;
  final double longitude;

  TripLocation({required this.latitude, required this.longitude});

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      latitude: json["latitude"].toDouble(),
      longitude: json["longitude"].toDouble(),
    );
  }
}
