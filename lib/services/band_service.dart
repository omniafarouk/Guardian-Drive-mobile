import 'package:guardian_drive_mobile/services/api_client_service.dart';

class BandService {
  static Future<bool> patchBand(int deviceId, {bool? isConnected, int? batteryLevel}) async {
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
}
