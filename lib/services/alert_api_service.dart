import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
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
}
