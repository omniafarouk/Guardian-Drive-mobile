import 'dart:convert';
import 'package:guardian_drive_mobile/services/api_client_service.dart'
    as api_service;
import 'package:http/http.dart' as http;
import 'package:guardian_drive_mobile/models/user.dart';

class UserService {
  //static const String baseUrl = "http://10.0.2.2:3000";
  static const String baseUrl = api_service.ApiClient.baseUrl;

  static Future<UserProfile> getUserById(String token, int id) async {
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
  }
}
