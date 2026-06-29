import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/enums.dart';
import 'package:guardian_drive_mobile/services/band_ble_service.dart';

Color getBPMStatusColor(double bpm) {
  if (BandBleService.instance.status != BleDeviceStatus.ready)
    return Colors.grey;
  if (bpm >= 120) {
    return Colors.redAccent;
  } else if (bpm >= 90 && bpm < 120) {
    return Colors.amberAccent;
  } else
    return Colors.greenAccent;
}

Color getSpOStatusColor(double spO2) {
  if (BandBleService.instance.status != BleDeviceStatus.ready)
    return Colors.grey;
  if (spO2 <= 100) {
    return Colors.redAccent;
  } else if (spO2 >= 95 && spO2 <= 97) {
    return Colors.amberAccent;
  } else
    return Colors.greenAccent;
}

Color getTempStatusColor(double temp) {
  if (BandBleService.instance.status != BleDeviceStatus.ready)
    return Colors.grey;
  if (temp >= 36.5 && temp <= 37.5) {
    return Colors.greenAccent;
  } else if (temp > 36.5 && temp < 36.5 || temp > 37.5 && temp < 38) {
    return Colors.amberAccent;
  } else {
    return Colors.redAccent;
  }
}
