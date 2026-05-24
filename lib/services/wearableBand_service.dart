import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:guardian_drive_mobile/models/band.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:guardian_drive_mobile/services/api_client_service.dart'
    as api_service;

class WearableService {
  static const String baseUrl = api_service.ApiClient.baseUrl;

  static Future<Map<String, dynamic>> getWearableBand() async {
    try {
      final token = await StorageService.getToken();
      final deviceId = await StorageService.getDeviceId();

      if (token == null || deviceId == null) {
        return {
          "status": "no_band",
          "message": "No wearable band assigned",
          "data": null,
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/wearablebands/$deviceId'),
        headers: await api_service.ApiClient.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "status": "success",
          "data": WearableBand.fromJson(data['wearableBand']),
        };
      } else if (response.statusCode == 404) {
        return {
          "status": "no_band",
          "message": "No wearable band found",
          "data": null,
        };
      } else {
        return {
          "status": "error",
          "message": "Failed to load wearable band",
          "data": null,
        };
      }
    } catch (error) {
      return {"message": "Wearable service error", "data": null};
    }
  }
}
