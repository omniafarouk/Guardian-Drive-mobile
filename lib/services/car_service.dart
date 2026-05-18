import 'dart:convert';
import 'dart:io';
import '../models/car.dart';
import '../models/trips_response.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

class CarService {
  final token='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyLCJyb2xlIjoiRFJJVkVSIiwiaWF0IjoxNzc4NjU1NDIyLCJleHAiOjE3Nzg3NDE4MjJ9.nkvii20cOneNM41A_JoW34oqDA2bx2cBO7_rv41UYXQ';
  static const baseUrl = api_service.ApiClient.baseUrl;

  //final String baseUrl = "http://10.0.2.2:3000";
  //final String baseUrl = "http://localhost:3000/api/trips";

  Future<Car> getCarById(String engineId)async{
    final uri = Uri.parse('$baseUrl/api/cars/$engineId');
    final response = await http.get(
      uri,
      headers: await api_service.ApiClient.headers(),

      // headers: {
      //   // add auth token from secure storage
      //   HttpHeaders.authorizationHeader:
      //   'Bearer $token',
      // },
    );
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      //final List tripsJson = data['trips'];  // 👈 FIX HERE

      // return tripsJson.map((e) => Trip.fromJson(e)).toList();
      return Car.fromJson(data['car']);
    } else {
      throw Exception('Failed to load car');
    }
  }
}
