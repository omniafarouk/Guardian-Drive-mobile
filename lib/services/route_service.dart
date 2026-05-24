import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  static Future<List<LatLng>> getRoute({
    required double startLat,
    required double startLong,
    required double destLat,
    required double destLong,
  }) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '$startLong,$startLat;'
        '$destLong,$destLat'
        '?overview=full&geometries=geojson';
    final route = await http.get(Uri.parse(url));
    print(route.body);

    if (route.statusCode != 200) {
      print("cannot get trip route");
      return [];
    }
    final routeData = jsonDecode(route.body);
    final coordinates = routeData['routes'][0]['geometry']['coordinates'];
    print(coordinates.runtimeType);
    return (coordinates as List)
        .map((point) => LatLng(point[1].toDouble(), point[0].toDouble()))
        .toList();
  }
}
