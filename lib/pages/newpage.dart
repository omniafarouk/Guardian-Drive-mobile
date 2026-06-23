import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardian_drive_mobile/services/route_service.dart'
    as routeservice;
import 'package:guardian_drive_mobile/utils/location_helper.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/future_table_row.dart';
import 'package:latlong2/latlong.dart';

class OngoingTrip extends StatefulWidget {
  const OngoingTrip({super.key});

  @override
  State<OngoingTrip> createState() => _OngoingTripState();
}

class _OngoingTripState extends State<OngoingTrip> {
  double? currentLat;
  double? currentLong;
  late double destLat;
  late double destLong;
  late double startLat;
  late double startLong;
  late Future<String> startLocationName;
  late Future<String> destLocationName;
  List<LatLng> route = [];
  // Future<List<LatLng>>? routeFuture;
  final MapController mapController = MapController();
  late StreamSubscription<Position> positionStream;
  double? remainingDistance;
  bool _initialized = false;
  bool _ready = false;
  // bool locationLoaded = false;
  // bool routeLoaded = false;

  TileLayer get openStreetMapTileLayer => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'dev.fleafelt.flutter_map.example',
  );

  int getClosestRouteIndex(LatLng current, List<LatLng> route) {
    final Distance distance = Distance();

    int closestIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < route.length; i++) {
      final d = distance.as(LengthUnit.Meter, current, route[i]);
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }
    return closestIdx;
  }

  bool isOffRoute(Position pos) {
    final closestPointIndex = getClosestRouteIndex(
      LatLng(pos.latitude, pos.longitude),
      route,
    );
    final distance = Distance().as(
      LengthUnit.Meter,
      LatLng(pos.latitude, pos.longitude),
      route[closestPointIndex],
    );
    return distance > 100; // meters
  }

  double getRemainingDistance(LatLng current, List<LatLng> route) {
    final Distance d = Distance(); // calculates the distances between 2 points
    int idx = getClosestRouteIndex(current, route);
    double totalDistance = 0;

    for (int i = idx; i < route.length - 1; i++) {
      totalDistance += d.as(LengthUnit.Meter, route[i], route[i + 1]);
    }
    print("REMAINING DISTANCE = $totalDistance");
    return totalDistance;
  }

  Future<void> startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Enable location service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
    print('START LOCATION UPDATES CALLED');
    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position? position) {
          if (position != null) {
            if (!mounted)
              return; //(built-in) boolean property in every Sate object in Flutter,  after dispose() -> mounted = false

            setState(() {
              currentLat = position.latitude;
              currentLong = position.longitude;
              if (route.isNotEmpty) {
                remainingDistance = getRemainingDistance(
                  LatLng(position.latitude, position.longitude),
                  route,
                );
              }

              if (route.isEmpty) {
                loadRoute(destLat, destLong).then((points) {
                  setState(() {
                    route = points;
                  });
                });
              }
            });
            // check if current location deviates from route
            if (route.isNotEmpty && isOffRoute(position)) {
              print('reloaded route');
              loadRoute(destLat, destLong).then((points) {
                setState(() {
                  route = points;
                });
              });
            }
            mapController.move(
              LatLng(currentLat!, currentLong!),
              mapController.camera.zoom,
            );
          }
        });
  }

  Future<List<LatLng>> loadRoute(double destLat, double destLong) async {
    final points = await routeservice.RouteService.getRoute(
      startLat: currentLat!,
      startLong: currentLong!,
      destLat: destLat,
      destLong: destLong,
    );
    return points;
  }

  @override
  void initState() {
    super.initState();
    startLocationUpdates();
  }

  @override
  void dispose() {
    super.dispose();
    positionStream.cancel(); // stops location updates when leaving the page
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    destLat = args['destLatitude'];
    destLong = args['destLongitude'];
    startLat = args['startLatitude'];
    startLong = args['startLongitude'];
    startLocationName = getLocationName(startLat, startLong);
    destLocationName = getLocationName(destLat, destLong);
    if (!_initialized) {
      _initialized = true;

      startLocationUpdates().then((_) {
        _ready = true;
        setState(() {});
      });
    }
    // routeFuture = loadRoute(destLat, destLong);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || currentLat == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: CustomAppBar(title: "Ongoing Trip"),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(currentLat!, currentLong!),
              initialZoom: 13,

              /*onMapReady: () {
              mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(30),
                ),
              );
            },*/
            ),
            children: [
              openStreetMapTileLayer,
              PolylineLayer(
                polylines: [
                  Polyline(points: route, strokeWidth: 6, color: Colors.blue),
                ],
              ),

              MarkerLayer(
                markers: [
                  // START MARKER
                  Marker(
                    point: LatLng(currentLat!, currentLong!),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  Marker(
                    point: LatLng(destLat, destLong),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 30,
            left: 135,
            child: Card(
              color: Color.fromARGB(255, 1, 21, 51),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remainingDistance != null
                              ? remainingDistance! > 1000
                                    ? '${(remainingDistance! / 10000).toStringAsFixed(2)} Km'
                                    : '${remainingDistance!.toStringAsFixed(2)} m'
                              : '0',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    ),
                    SizedBox(width: 10),
                    Container(color: Colors.grey, width: 3, height: 90),
                    SizedBox(width: 10),

                    Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(), // icon column (tight)
                        1: FixedColumnWidth(20),
                        2: IntrinsicColumnWidth(), // text column (tight)
                      },
                      children: [
                        buildRowFuture(
                          Icons.radio_button_on_sharp,
                          Colors.lightBlueAccent,
                          startLocationName,
                        ),
                        buildRowFuture(
                          Icons.radio_button_on_sharp,
                          Colors.greenAccent,
                          destLocationName,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
