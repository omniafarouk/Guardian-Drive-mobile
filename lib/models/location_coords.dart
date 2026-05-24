class LocationCoords {
  double latitude;
  double longitude;
  LocationCoords({required this.latitude, required this.longitude});
  factory LocationCoords.fromJson(Map<String, dynamic> json) {
    return LocationCoords(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}
