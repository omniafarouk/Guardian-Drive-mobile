import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleHelper {
  BleHelper._();

  static Future<String?> checkBle(FlutterReactiveBle ble) async {
    // 1. Request permissions FIRST
    final scanPermission = await Permission.bluetoothScan.request();
    final connectPermission = await Permission.bluetoothConnect.request();

    if (!scanPermission.isGranted || !connectPermission.isGranted) {
      if (scanPermission.isPermanentlyDenied ||
          connectPermission.isPermanentlyDenied) {
        await openAppSettings();
        return null;
      }
      return "Bluetooth permission is required.";
    }

    // 2. NOW check BLE status
    final bleStatus = await ble.statusStream.first;
    if (bleStatus != BleStatus.ready) {
      return "Bluetooth is turned off. Please enable Bluetooth.";
    }

    return null;
  }
}