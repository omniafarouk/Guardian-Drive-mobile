import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth.dart';

class AuthService {
  // Replace with your actual backend IP
  // If testing on real device, use your PC's local IP e.g. 192.168.1.5
  // If testing on emulator, use 10.0.2.2 (emulator's alias for localhost)
  static const String _baseUrl = 'http:localhost:3000';

  Future<LoginResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      // send this to login page to show it
      throw Exception(
        error['message'] ?? 'Login failed',
      ); // exception catched in login page to show the error to user
    }
  }
}
