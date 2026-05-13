import 'dart:convert';
import 'package:guardian_drive_mobile/services/api_client_service.dart'
    as api_service;
import 'package:http/http.dart' as http;
import '../models/auth.dart';

class AuthService {
  // Replace with your actual backend IP
  // If testing on real device, use your PC's local IP e.g. 192.168.1.5
  // If testing on emulator, use 10.0.2.2 (emulator's alias for localhost)
  //static const String baseUrl = "http://10.0.2.2:3000";
  static const String baseUrl = api_service.ApiClient.baseUrl;

  Future<LoginResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: await api_service.ApiClient.headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      print("auth service error:" + error);
      // send this to login page to show it
      throw Exception(
        error['message'] ?? 'Login failed',
      ); // exception catched in login page to show the error to user
    }
  }

  static Future<String> forgetPass(String email) async {
    final url = Uri.parse("$baseUrl/api/password/forget-password");

    final res = await http.post(
      url,
      headers: await api_service.ApiClient.headers(),
      body: jsonEncode({"email": email}),
    );
    print(res.body);

    final data = jsonDecode(res.body);

    return data['message'];
  }

  static Future<Map<String, dynamic>> validateToken(String token) async {
    final url = Uri.parse("$baseUrl/api/password/validate-reset-token");

    final res = await http.post(
      url,
      headers: await api_service.ApiClient.headers(),
      body: jsonEncode({"token": token}),
    );

    print(res.body);

    if (res.statusCode == 200) {
      return {"valid": true, "message": "Token is valid"};
    } else {
      return {"valid": false, "message": "Invalid or expired token"};
    }
  }

  static Future<Map<String, dynamic>> resetPass({
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/api/password/reset-password");

    final res = await http.post(
      url,
      headers: await api_service.ApiClient.headers(),
      body: jsonEncode({"token": token, "newPassword": newPassword}),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    final data = jsonDecode(res.body);

    return {
      "success": res.statusCode == 200,
      "message": data["message"] ?? "Something went wrong",
    };
  }
}

/*static Future<bool> validateResetToken(String token) async {
    final url = Uri.parse("$baseUrl/api/password/validate-reset-token");

    final res = await http.post(
      url,
      headers: await api_service.ApiClient.headers(),
      body: jsonEncode({"token": token}),
    );

    print(res.body);

    if (res.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}*/
