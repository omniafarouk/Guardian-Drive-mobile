import 'dart:convert';
import 'dart:io';
import '../models/trip.dart';
import '../models/trips_response.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

class TripService {
  final token='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyLCJyb2xlIjoiRFJJVkVSIiwiaWF0IjoxNzc4NjU1NDIyLCJleHAiOjE3Nzg3NDE4MjJ9.nkvii20cOneNM41A_JoW34oqDA2bx2cBO7_rv41UYXQ';
  //final String baseUrl = "http://10.0.2.2:3000/api";
  static const baseUrl = api_service.ApiClient.baseUrl;
  //final String baseUrl = "http://localhost:3000/api/trips";
  Future<TripsResponse> getTrips({
    int page = 1,
    int limit = 1,
    String? engineId,
    int? driverId,
    String? status,
    DateTime? fromStartDate,
    DateTime? toStartDate,
    int? fleetManagerId,
    String orderBy = "desc",
  }) async {
    final Map<String, String> queryParams = {
      "page": page.toString(),
      "limit": limit.toString(),
      "orderBy": orderBy,
    };

    if (engineId != null) {
      queryParams["engineId"] = engineId;
    }

    if (driverId != null) {
      queryParams["driverId"] = driverId.toString();
    }

    if (status != null) {
      queryParams["status"] = status;
    }

    if (fleetManagerId != null) {
      queryParams["fleetManagerId"] = fleetManagerId.toString();
    }

    if (fromStartDate != null) {
      queryParams["fromStartDate"] = fromStartDate.toIso8601String();
    }

    if (toStartDate != null) {
      queryParams["toStartDate"] = toStartDate.toIso8601String();
    }
    final uri = Uri.parse('$baseUrl/api/trips').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await api_service.ApiClient.headers(),

      // headers: {
      //   // add auth token from secure storage
      //   HttpHeaders.authorizationHeader:
      //       'Bearer $token',
      // },
    );
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      //final List tripsJson = data['trips'];  // 👈 FIX HERE

      // return tripsJson.map((e) => Trip.fromJson(e)).toList();
      return TripsResponse.fromJson(data);
    } else {
      throw Exception('Failed to load trips');
    }
  }
  Future<Trip> getTripById(int tripId)async{
    final uri = Uri.parse('$baseUrl/api/trips/$tripId');
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
      return Trip.fromJson(data['trip']);
    } else {
      throw Exception('Failed to load trip');
    }
  }
  Future<Trip> patchTrip(int tripId,TripStatus status) async{
    final body = jsonEncode({
      'status': status.name,
    });
    final uri = Uri.parse('$baseUrl/api/trips/$tripId');
    final response=await http.patch(uri,
        headers: await api_service.ApiClient.headers(),

        //     headers: {
    //   // add auth token from secure storage
    //   HttpHeaders.authorizationHeader:
    //   'Bearer $token',
    //   HttpHeaders.contentTypeHeader: 'application/json',
    // },
    body:body);
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if(response.statusCode == 200){
      final data= json.decode(response.body);
      return Trip.fromJson(data['trip']);
    }else {
      throw Exception('Failed to update trip');
    }

  }
}
