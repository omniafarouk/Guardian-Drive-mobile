import 'dart:convert';
import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/api_client_service.dart'
    as api_service;
import 'package:guardian_drive_mobile/services/device_auth_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:guardian_drive_mobile/models/user.dart';

class UserService {
  //static const String baseUrl = "http://10.0.2.2:3000";
  static const String baseUrl = api_service.ApiClient.baseUrl;

  static Future<UserProfile> getUserById() async {
    try {
      int? id = await StorageService.getId();
      if (id == null) {
        print("user session not found , please login again");
        throw Exception('User session not found. Please login again.');
      }
      final response = await http.get(
        Uri.parse("$baseUrl/api/users/$id"),
        headers: await api_service.ApiClient.headers(),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception("Failed to load user: ${response.body}");
      }
    } catch (e) {
      print('getUserById error: $e');
      rethrow;
    }
  }

  static Future<dynamic> createHealthReadings(
    VitalReadings readings,
    int tripId,
  ) async {
    try {
      int? userId = await StorageService.getId();
      final response = await http.post(
        Uri.parse("$baseUrl/api/users/$userId/avg-health-readings"),
        headers: DeviceAuth.systemAuthHeader(),
        body: {
          'avgHeartRate': readings.heartRate,
          'avgSpo2': readings.spo2,
          'avgTemp': readings.temp,
          'tripId': tripId,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Avg Reading Creation Successfull , $data");
        // must return valid data , if changed to success code = 203 (no content)- send true for successful request
        return data;
      } else {
        throw Exception("Failed to create avg readings: ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to create avg readings: $e");
    }
  }
}
