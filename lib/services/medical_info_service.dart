import 'dart:convert';

import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

class MedicalInfoService {
  static const baseUrl = api_service.ApiClient.baseUrl;
  // singleton
  static final MedicalInfoService _instance = MedicalInfoService._internal();
  factory MedicalInfoService() => _instance;
  MedicalInfoService._internal();

  DriverHealthThresholds? _cached;

  // Called once after login — everywhere else just reads _cached
  Future<DriverHealthThresholds> getDriverThresholds() async {
    if (_cached != null) return _cached!; // already fetched, skip
    _cached = await _getDriverThresholdsAPI();
    return _cached!;
  }

  // Call this on logout so next login fetches fresh
  void clear() => _cached = null;

  Future<DriverHealthThresholds> _getDriverThresholdsAPI() async {
    final uri = Uri.parse('$baseUrl/api/medical-information/custom-thresholds');

    final response = await http.get(
      uri,
      headers: await api_service.ApiClient.headers(),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      traceLog('[Database] custom thresholds returned', jsonBody['data']);

      return DriverHealthThresholds.fromJson(jsonBody['data']);
    } else {
      throw Exception('Failed to load thresholds (${response.statusCode})');
    }
  }
}

// class MedicalInfoService {
//   static const baseUrl = api_service.ApiClient.baseUrl;

//   Future<DriverHealthThresholds> getDriverThresholds() async {
//     final uri = Uri.parse('$baseUrl/api/medical-information/custom-thresholds');

//     final response = await http.get(
//       uri,
//       headers: await api_service.ApiClient.headers(),
//     );

//     if (response.statusCode == 200) {
//       final jsonBody = json.decode(response.body);

//       traceLog('[Database] custom thresholds returned', jsonBody['data']);

//       return DriverHealthThresholds.fromJson(jsonBody['data']);
//     } else {
//       throw Exception('Failed to load thresholds (${response.statusCode})');
//     }
//   }
// }
