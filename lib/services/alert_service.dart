import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:guardian_drive_mobile/models/alerts_response.dart';
import 'api_client_service.dart';

class AlertApiService {
  static Future<AlertsResponse> getAlerts({
    int page = 1,
    int limit = 10,
    String orderBy = "desc",
    alertType? type,
    alertStatus? status,
    int? driverId,
    String? engineId,
    DateTime? from,
    DateTime? to,
  }) async {
    // var url = Uri.parse("${baseUrl}/api/alerts");
    try {
      final queryParams = <String, String>{
        "page": page.toString(),
        "limit": limit.toString(),
        "orderBy": orderBy,
      };
      if (type != null) queryParams['type'] = type.name;

      if (driverId != null) queryParams["driverId"] = driverId.toString();

      if (engineId != null) queryParams["engineId"] = engineId;

      if (from != null) queryParams["from"] = from.toUtc().toIso8601String();

      if (to != null) queryParams["to"] = to.toUtc().toIso8601String();

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = "/api/alerts?$queryString";
      print(queryParams);
      print(endpoint);
      final res = await ApiClient.get(endpoint);
      if (res.statusCode == 200) {
        final body = jsonDecode(
          res.body,
        ); // converts raw JSON string to usable Dart object (just maps)
        final Map<String, dynamic> data = body["data"];

        return AlertsResponse.fromJson(
          data,
        ); // each map is converted into a real Alert object, this returns iteratable not a list, so we convert it by .toList()
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Failed to load alerts");
    }
  }

  // GET alert by alertId
  static Future<Alert?> getAlertById(int id) async {
    try {
      final res = await ApiClient.get("/api/alerts/$id");
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
