class WearableBand {
  final int batteryLevel;
  final bool isConnected;
  WearableBand({required this.batteryLevel, required this.isConnected});
  factory WearableBand.fromJson(Map<String, dynamic> json) {
    return WearableBand(
      batteryLevel: json['batteryLevel'] ?? 0,
      isConnected: json['isConnected'] ?? false,
    );
  }
}
