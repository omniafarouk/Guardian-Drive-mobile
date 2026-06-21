import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapWidget({super.key, required this.latitude, required this.longitude});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final LatLng alexandria = LatLng(31.2001, 29.9187);
  final LatLng cairo = LatLng(30.0444, 31.2357);
  List<Polyline> getRoute() {
    return [
      Polyline(
        points: [alexandria, cairo],
        strokeWidth: 4,
        color: Colors.blueAccent,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(30.5, 30.5), // center between cities
        initialZoom: 6,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c', 'd'],
        ),

        PolylineLayer(polylines: getRoute()),

        MarkerLayer(
          markers: [
            Marker(
              point: alexandria,
              width: 40,
              height: 40,
              child: Icon(Icons.location_pin, color: Colors.green, size: 40),
            ),
            Marker(
              point: cairo,
              width: 40,
              height: 40,
              child: Icon(Icons.location_pin, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}
