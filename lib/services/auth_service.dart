import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://10.0.2.2:3000";

  static Future<String> forgetPass(String email) async {
    final url = Uri.parse("$baseUrl/api/password/forget-password");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
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
