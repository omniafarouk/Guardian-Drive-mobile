class UserProfile {
  final String email;
  final String phone;
  final String license;
  final String medications;
  final String medicalConditions;
  final int avgHeartRate;
  final double avgTemperature;
  final int avgSpo2;
  final int? wearableBand;
  //final String bloodType;

  UserProfile({
    required this.email,
    required this.phone,
    required this.license,
    required this.medications,
    required this.medicalConditions,
    required this.avgHeartRate,
    required this.avgTemperature,
    required this.avgSpo2,
    required this.wearableBand,
    //required this.bloodType,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] ?? {};
    final medicalInfo = driver['medicalInformation'] ?? {};

    return UserProfile(
      email: json['email'] ?? '',

      phone:
          (json['phone'] != null &&
              json['phone'] is List &&
              json['phone'].isNotEmpty)
          ? json['phone'][0]
          : '',

      license: driver['drivingLicense'] ?? '',

      medications: (medicalInfo['medications'] as List?)?.join(', ') ?? '',

      medicalConditions: (medicalInfo['conditions'] as List?)?.join(', ') ?? '',

      avgHeartRate: medicalInfo['avgHeartRate'] ?? 0,

      avgTemperature: (medicalInfo['avgTemp'] ?? 0).toDouble(),

      avgSpo2: medicalInfo['avgSpo2'] ?? 0,
      wearableBand: driver['wearableBand']?['deviceId'] ?? 0, //bloodType: '',
    );
  }

  void operator [](String other) {}
}
