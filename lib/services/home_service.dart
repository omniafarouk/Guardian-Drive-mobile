import 'dart:convert';

import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:guardian_drive_mobile/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:guardian_drive_mobile/services/auth_service.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/services/api_client_service.dart'
    as api_service;
import 'package:guardian_drive_mobile/models/trip_location.dart';

class HomeService {
  static const String baseUrl = api_service.ApiClient.baseUrl;

  static Future<String> getUserName() async {
    try {
      final username = await StorageService.getUsername();
      return username ?? "";
    } catch (error) {
      print("Error fetching user name : $error");
      return "";
    }
  }

  static Future<int> getDeviceId() async {
    print("getting device id..");
    try {
      final user = await UserService.getUserById();

      final deviceId = user.wearableBand ?? -1;

      await StorageService.saveDeviceId(deviceId);
      print("Got device id: $deviceId");
      return deviceId;
    } catch (error) {
      print("Error getting device id: $error");
      return -1;
    }
  }

  static Future<Trip?> getOnGoingTrip(String token) async {
    try {
      final trip = await http.get(
        Uri.parse("$baseUrl/api/trips?status=ONGOING&page=1&limit=1"),
        headers: await api_service.ApiClient.headers(),
      );
      print("STATUS: ${trip.statusCode}");
      print("BODY: ${trip.body}");

      if (trip.statusCode == 200) {
        final data = jsonDecode(trip.body);

        final trips = data["trips"];

        if (trips == null || trips.isEmpty) {
          return null;
        }
        return Trip.fromJson(trips[0]);
      }
    } catch (error) {
      print("error fetching location :$error");

      return null;
    }
  }

  static Future<List<Trip>> getPlannedTrips(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/trips?status=PLANNED&page=1&limit=10"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final trips = data["trips"] as List;

        return trips.map((e) => Trip.fromJson(e)).toList();
      }

      return [];
    } catch (error) {
      print("error fetching planned trips: $error");
      return [];
    }
  }

  Future<TripLocation> getTripLocation(int tripId, String token) async {
    final location = await http.get(
      Uri.parse("$baseUrl/api/trips/$tripId/gps"),
      headers: await api_service.ApiClient.headers(),
    );

    print("on going trip location::");
    print(location.body);

    if (location.statusCode == 200) {
      final data = jsonDecode(location.body);

      return TripLocation.fromJson(data);
    } else {
      throw Exception("Failed to load location");
    }
  }
}
