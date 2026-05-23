import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:guardian_drive_mobile/models/band.dart';

import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:guardian_drive_mobile/services/api_client_service.dart'
    as api_service;

class WearableService {
  static const String baseUrl = api_service.ApiClient.baseUrl;

  static Future<WearableBand> getWearableBand() async {
    try {
      final token = await StorageService.getToken();

      final deviceId = await StorageService.getDeviceId();

      if (token == null || deviceId == null) {
        /* print("token", token);
        print("deviceId", deviceId);*/
        throw Exception("Missing token or device id");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/wearablebands/$deviceId'),

        headers: await api_service.ApiClient.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return WearableBand.fromJson(data['wearableBand']);
      } else {
        throw Exception("Failed to load wearable band");
      }
    } catch (error) {
      throw Exception("Wearable service error: $error");
    }
  }
}
