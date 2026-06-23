
import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:guardian_drive_mobile/services/api_client_service.dart';

class BandService {
  Future<bool> patchBand(int deviceId, bool isConnected, int batteryLevel) async{
    final body = {
      'batteryLevel': batteryLevel,
      'isConnected': isConnected      
    };
    final endpoint = "/api/wearablebands/$deviceId";
    final res = await ApiClient.patch(endpoint, body);
    
    print("STATUS CODE: ${res.statusCode}");
    print("BODY: ${res.body}");
    if(res.statusCode == 200){
      return true; // means band updates successfully
    }else {
      print("${res.statusCode} failed to update band in database");
      return false;
    }

  }
}