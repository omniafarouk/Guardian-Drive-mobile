import 'dart:async';
import 'dart:math';

import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';

// Stream<VitalReadings> mockVitalsStream() {
//   final random = Random();

//   return Stream.periodic(Duration(seconds: 10), (_) {
//     return VitalReadings(
//       heartRate: 60 + random.nextDouble() * 40, // 60–100
//       spo2: 95 + random.nextDouble() * 5, // 95–100
//       temp: 36 + random.nextDouble() * 2, // 36–38
//       timestamp: DateTime.now(),
//     );
//   });
// }

Stream<VitalReadings> mockVitalsStream() {
  final random = Random();
  return Stream.periodic(Duration(seconds: 10), (_) {
    return VitalReadings(
      heartRate: 80 + random.nextDouble() * 40,
      spo2: 91 + random.nextDouble() * 5,
      temp: 33.5,
      timestamp: DateTime.now(),
    );
  });
}
