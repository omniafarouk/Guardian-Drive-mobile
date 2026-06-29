import 'dart:async';

import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/band_ble_service.dart';
import 'package:guardian_drive_mobile/services/band_service.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';

class TripMonitoringService {
  TripMonitoringService._();

  static final instance = TripMonitoringService._();

  StreamSubscription<VitalReadings>? _subscription;
  bool _isRunning = false;

  void startMonitoring() {
    if (_isRunning) return;

    _isRunning = true;

    _subscription = BandBleService.instance.telemetryController.stream.listen(
      (reading) async {
        await BandService.sendVitals(
          heartRate: reading.heartRate,
          spo2: reading.spo2,
          temp: reading.temp,
        );
      },
    );
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _isRunning = false;
  }
}