// import 'dart:async';

// import 'package:guardian_drive_mobile/models/enums.dart';

// class CsvBandService {
//   static final instance = CsvBandService._();

//   CsvBandService._();

//   final telemetryController =
//       StreamController<VitalReadings>.broadcast();

//   final statusNotifier =
//       ValueNotifier(BleDeviceStatus.ready);

//   Future<void> scanAndConnect() async {
//     // immediately "connect"
//     await startSimulation();
//   }

//   Future<void> sendCommand(String cmd) async {}

//   void dispose() {}
// }