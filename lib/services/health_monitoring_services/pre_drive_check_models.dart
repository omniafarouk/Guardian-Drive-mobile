// pre_drive_result.dart

enum PreDriveStatus { passed, blocked, cancelled }

class PreDriveResult {
  final PreDriveStatus status;
  final String? blockedBy;

  bool get canDrive => status == PreDriveStatus.passed;

  const PreDriveResult({required this.status, this.blockedBy});
}
