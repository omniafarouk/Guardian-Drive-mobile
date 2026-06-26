/*
type: z.literal(alertType.SOS, { message: "Alert type must be SOS for driver-triggered alerts" }),
tripId: z.number().int().positive(),
triggeredLocationId: z.number().int().positive(),
stoppedLocationId: z.number().int().positive().optional(),

// required for the health event creation
heartRate: z.number().max(300),
temp: z.number().min(30).max(45),
spo2: z.number().min(50).max(100),
*/

import 'package:guardian_drive_mobile/models/alert_summary.dart';

class AlertRequest {
  alertType type;
  int tripId;
  int triggeredLocationId;
  int? stoppedLocationId;
  double heartRate;
  double temp;
  double spo2;

  AlertRequest({
    required this.type,
    required this.tripId,
    required this.triggeredLocationId,
    required this.heartRate,
    required this.spo2,
    required this.temp,
    this.stoppedLocationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'tripId': tripId,
      'triggeredLocationId': triggeredLocationId,
      'heartRate': heartRate,
      'temp': temp,
      'spo2': spo2,
      if (stoppedLocationId != null)
        'stoppedLocationId': stoppedLocationId, // only included if not null
    };
  }

  @override
  String toString() {
    return 'type:$type ,tripId: $tripId ,'
        'triggeredLocationId: $triggeredLocationId, heartRate: $heartRate, spo2:$spo2, temp:$temp';
  }
}
