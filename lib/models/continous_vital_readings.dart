class VitalReadings {
  final double heartRate;
  final double spo2;
  final double temp;
  final DateTime timestamp;

  VitalReadings({
    required this.heartRate,
    required this.spo2,
    required this.temp,
    required this.timestamp,
  });
  // Convert object → Map for Hive storage
  Map<String, dynamic> toMap() => {
    'heartRate': heartRate,
    'spo2': spo2,
    'temp': temp,
    'timestamp': timestamp.toIso8601String(),
  };

  // Convert Map → object when reading back from Hive
  factory VitalReadings.fromMap(Map<String, dynamic> map) => VitalReadings(
    heartRate: map['heartRate'],
    spo2: map['spo2'],
    temp: map['temp'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
