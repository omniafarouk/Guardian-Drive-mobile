import 'package:guardian_drive_mobile/services/api_client_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';

class BandService {
  static Future<bool> patchBand(
    int deviceId, {
    bool? isConnected,
    int? batteryLevel,
  }) async {
    print('Patch Band Function Called to isConnected = $isConnected');
    final body = <String, dynamic>{};

    if (batteryLevel != null) {
      body['batteryLevel'] = batteryLevel;
    }
    if (isConnected != null) {
      body['isConnected'] = isConnected;
    }
    final endpoint = "/api/wearablebands/$deviceId";
    final res = await ApiClient.patch(endpoint, body);

    print("STATUS CODE: ${res.statusCode}");
    print("BODY: ${res.body}");
    return res.statusCode == 200;
  }

  static Future<void> sendVitals({
    required double heartRate,
    required double spo2,
    required double temp,
  }) async {
    int? driverId = await StorageService.getId();
    print('Send vitals called');
    print("driverID: $driverId");
    print("temp: $temp");
    print("spo2: $spo2");
    print("bpm: $heartRate");
    final body = <String, dynamic>{
      "driverId": driverId,
      "heartRate": heartRate,
      "spo2": spo2,
      "temp": temp,
    };
    final endpoint = "/api/post-OnGoingTrips-vitals";
    final res = await ApiClient.post(endpoint, body);
    print("STATUS CODE: ${res.statusCode}");
    print("BODY: ${res.body}");
  }
}
