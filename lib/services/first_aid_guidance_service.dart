import 'dart:convert';

import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';
import 'package:http/http.dart' as http;

import 'api_client_service.dart' as api_service;

class FirstAidGuidanceService {
  static const baseUrl = api_service.ApiClient.baseUrl;

  Future<List<FirstAidGuidance>> getGuidanceByVitals(
    VitalReadings readings,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/first-aid-guidance/vitals').replace(
        queryParameters: {
          'heartRate': readings.heartRate.toString(),
          'spo2': readings.spo2.toString(),
          'temp': readings.temp.toString(),
        },
      );

      print('GUIDANCE URL: $uri'); // is the URL correct?
      print('HR: ${readings.heartRate}'); // are the values valid?
      print('SPO2: ${readings.spo2}');
      print('TEMP: ${readings.temp}');

      final response = await http.get(
        uri,
        headers: await api_service.ApiClient.headers(),
      );

      print('GUIDANCE STATUS: ${response.statusCode}'); // add this
      print('GUIDANCE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);

        //return FirstAidGuidance.fromJson(jsonBody['data']['guidance']);

        final List<dynamic> guidanceJson = jsonBody['data']['guidance'];

        return guidanceJson.map((g) => FirstAidGuidance.fromJson(g)).toList();
      } else {
        throw Exception(
          'Failed to fetch first aid guidance(${response.statusCode},${response.body})',
        );
      }
    } catch (error) {
      throw Exception(
        "couldn't fetch first aid guidance for the driver readings",
      );
    }
  }
}
