import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiClient {
  // static const String baseUrl = 'http://localhost:3000';
  static const String baseUrl="http://172.20.10.2:3000";
  
  // Builds headers with token automatically
  static Future<Map<String, String>> headers() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  
  // Use this for all GET requests
  static Future<http.Response> get(String endpoint) async {
    print(endpoint);
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await headers(),
    );
  }
  /*
  // Use this for all POST requests
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  // Use this for all PUT requests
  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  // Use this for all DELETE requests
  static Future<http.Response> delete(String endpoint) async {
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );
  }
  */
}
