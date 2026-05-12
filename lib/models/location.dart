class Location {
  int locationId;
  DateTime time;
  double latitude;
  double longitude;
  Location({
    required this.locationId,
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json){
    return Location(
      locationId: json['locationId'],
      time: DateTime.parse(json['time']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
