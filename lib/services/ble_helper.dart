import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleHelper {
  BleHelper._();

  static Future<String?> checkBle(FlutterReactiveBle ble) async {
    // 1. Request permissions FIRST
    final scanPermission = await Permission.bluetoothScan.request();
    final connectPermission = await Permission.bluetoothConnect.request();
    final locationPermission = await Permission.locationWhenInUse.request();

    if (!scanPermission.isGranted || !connectPermission.isGranted) {
      if (scanPermission.isPermanentlyDenied ||
          connectPermission.isPermanentlyDenied ||
          locationPermission.isPermanentlyDenied) {
        await openAppSettings();
      }
      return null;
    }

    // 2. NOW check BLE status — wait up to 3s for ready
    final bleStatus = await ble.statusStream
        .firstWhere(
          (s) => s != BleStatus.unknown,
          orElse: () => BleStatus.unknown,
        )
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () => BleStatus.unknown,
        );

    if (bleStatus != BleStatus.ready) {
      return "Bluetooth is turned off. Please enable Bluetooth.";
    }

    return null;
  }
}
