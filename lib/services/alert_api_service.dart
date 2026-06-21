import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:guardian_drive_mobile/models/alert_request.dart';
import 'package:guardian_drive_mobile/services/device_auth_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

class AlertApiService {
  static const baseUrl = api_service.ApiClient.baseUrl;
  //static const String baseUrl = "http://10.0.2.2:3000";

  static Future<List<Alert>> getAlerts(String token) async {
    var url = Uri.parse("${baseUrl}/api/alerts");
    try {
      final res = await http.get(
        url,
        headers: await api_service.ApiClient.headers(),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(
          res.body,
        ); // converts raw JSON string to usable Dart object (just maps)
        final List alertsJson = body["data"]["alerts"];
        return alertsJson
            .map((e) => Alert.fromJson(e))
            .toList(); // each map is converted into a real Alert object, this returns iteratable not a list, so we convert it by .toList()
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  // GET alert by alertId
  static Future<Alert?> getAlertById(int id, String token) async {
    var url = Uri.parse("${baseUrl}/api/alerts/${id}");
    try {
      final res = await http.get(
        url,
        headers: await api_service.ApiClient.headers(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final alert = body["data"];
        return Alert.fromJson(alert);
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      print('getAlertById error: $e'); // add this
      return null;
    }
  }

  // check return type is correct and what i actually want
  static Future<Alert?> triggerSOSAlert(AlertRequest payload) async {
    // TODO: fix the payload type
    try {
      int? id = await StorageService.getId();
      final res = await http.post(
        Uri.parse("$baseUrl/api/alerts"),
        headers: await api_service.ApiClient.headers(),
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final alert = body["data"];
        return Alert.fromJson(alert);
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      throw Exception('Create System Alert (HEALTH_ABNORMAL) error: $e');
    }
  }

  /*
    type: z.literal(alertType.SOS, { message: "Alert type must be SOS for driver-triggered alerts" }),
    tripId: z.number().int().positive(),
    triggeredLocationId: z.number().int().positive(),
    stoppedLocationId: z.number().int().positive().optional(),
    heartRate: z.number().max(300),
    temp: z.number().min(30).max(45),
    spo2: z.number().min(50).max(100),
  */
}
