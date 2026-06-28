// pre_drive_result.dart

import 'package:guardian_drive_mobile/services/car_ble_service.dart';

import 'package:guardian_drive_mobile/services/band_ble_service.dart';
// import 'package:guardian_drive_mobile/services/band_ble_simulator_service.dart';

enum PreDriveStatus { passed, blocked, cancelled }

class PreDriveResult {
  final PreDriveStatus status;
  final String? blockedBy;

  bool get canDrive =>
      status == PreDriveStatus.passed &&
      CarBleService.instance.precheckPassed &&
      BandBleService.instance.precheckPassed;

  const PreDriveResult({required this.status, this.blockedBy});
}
