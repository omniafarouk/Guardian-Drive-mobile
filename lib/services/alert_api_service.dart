import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:http/http.dart' as http;

class AlertApiService {
  static const baseUrl = "http://192.168.1.10:3000/api/";

  static Future<List<Alert>> getAlerts(String token) async {
    var url = Uri.parse("${baseUrl}alerts");
    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
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

  // GET alert by id
  static Future<Alert?> getAlertById(int id, String token) async {
    var url = Uri.parse("${baseUrl}alerts/${id}");
    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final alert = body["data"];
        return Alert.fromJson(alert);
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      return null;
    }
  }
}
