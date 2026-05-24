import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:guardian_drive_mobile/models/band.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:guardian_drive_mobile/services/home_service.dart';
import 'package:guardian_drive_mobile/services/wearableBand_service.dart';

import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/models/trip_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardian_drive_mobile/services/route_service.dart'
    as routeservice;
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final MapController mapController = MapController();
  double? lat;
  double? lng;
  List<LatLng> route = [];
  int bpm = 72;
  int battery = 0;
  bool isConnected = false;
  String username = "";
  String startLocName = "";
  String destLocName = "";
  Timer? timer;
  Random random = Random();

  Trip? ongoingTrip;
  TripLocation? currentLocation;
  Position? driverPosition;

  bool isLoading = true;
  List<Trip> plannedTrips = [];
  bool isPlannedLoading = true;

  @override
  void initState() {
    super.initState();
    initDashboard();
    startLiveBPM();
    startTracking();
  }

  Future<void> loadRoute() async {
    if (ongoingTrip == null) return null;
    final points = await routeservice.RouteService.getRoute(
      startLat: ongoingTrip!.startLatitude,
      startLong: ongoingTrip!.startLongitude,
      destLat: ongoingTrip!.destLatitude,
      destLong: ongoingTrip!.destLongitude,
    );
    setState(() {
      route = points;
    });
  }

  Future<String> getPlaceName(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);

      if (places.isEmpty) {
        return "Unknown location";
      }

      final p = places.first;

      return [p.locality, p.country].where((e) => e != null).join(", ");
    } catch (e) {
      return "Unknown location";
    }
  }

  String formatTripDate(DateTime date) {
    return DateFormat("dd MMM yyyy • hh:mm a").format(date.toLocal());
  }

  Future<void> initDashboard() async {
    final token = await StorageService.getToken();

    await HomeService.getDeviceId();
    await getBandData();
    await getusername();
    await loadTripLocation(token!);
    await loadPlannedTrips();
  }

  Future<void> loadTripLocation(String token) async {
    try {
      final trip = await HomeService.getOnGoingTrip(token);

      if (trip == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final location = await HomeService().getTripLocation(trip.tripId, token);

      setState(() {
        ongoingTrip = trip;
        currentLocation = location;
        isLoading = false;
      });
      await loadRoute();

      print("TRIP ID: ${trip.tripId}");
      print("LAT: ${location.latitude}");
      print("LNG: ${location.longitude}");
    } catch (e) {
      print("Trip load error: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getusername() async {
    final name = await HomeService.getUserName();
    setState(() {
      username = name;
    });
  }

  Future<void> loadPlannedTrips() async {
    try {
      final token = await StorageService.getToken();

      final trips = await HomeService.getPlannedTrips(token!);
      setState(() {
        plannedTrips = trips;
        isPlannedLoading = false;
      });
    } catch (e) {
      print("planned trips error: $e");

      setState(() {
        isPlannedLoading = false;
      });
    }
  }

  Future<void> getBandData() async {
    final result = await WearableService.getWearableBand();

    if (result["status"] == "no_band") {
      setState(() {
        battery = 0;
        isConnected = false;
      });
      return;
    }

    if (result["status"] == "error") {
      setState(() {
        battery = 0;
        isConnected = false;
      });
      return;
    }

    final WearableBand band = result["data"];

    setState(() {
      battery = band.batteryLevel;
      isConnected = band.isConnected;
    });
  }

  void startLiveBPM() {
    timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted) return;

      setState(() {
        bpm = 65 + random.nextInt(20);
      });
    });
  }

  void startTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        driverPosition = position;
      });
    });
  }

  String getStatus() {
    if (!isConnected) return "NO BAND";

    if (bpm >= 60 && bpm <= 100) {
      return "FIT TO DRIVE";
    } else {
      return "NOT SAFE";
    }
  }

  Color getStatusColor() {
    if (bpm >= 60 && bpm <= 100) {
      return Colors.greenAccent;
    } else {
      return Colors.redAccent;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percent = bpm / 150;
    final bounds = route.isNotEmpty
        ? LatLngBounds.fromPoints(route)
        : LatLngBounds.fromPoints([
            LatLng(
              ongoingTrip?.startLatitude ?? 0,
              ongoingTrip?.startLongitude ?? 0,
            ),
            LatLng(
              ongoingTrip?.destLatitude ?? 0,
              ongoingTrip?.destLongitude ?? 0,
            ),
          ]);

    return Scaffold(
      appBar: CustomAppBar(title: "Overview"),
      drawer: const SideBarDrawer(),

      body: GradientBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back, $username",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.08),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getStatus(),
                          style: TextStyle(
                            color: getStatusColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          isConnected ? "Band Connected" : "Disconnected",
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$battery%",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    CircularPercentIndicator(
                      radius: 55,
                      lineWidth: 8,
                      percent: percent.clamp(0.0, 1.0),
                      animation: true,
                      progressColor: getStatusColor(),
                      backgroundColor: Colors.white24,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$bpm",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("BPM", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              Text(
                "Ongoing Trip",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              Container(
                height: 150,
                width: double.infinity,
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : currentLocation == null
                    ? Center(
                        child: Text(
                          "No ongoing trip",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              ongoingTrip!.startLatitude,
                              ongoingTrip!.startLongitude,
                            ),
                            initialZoom: 13,

                            onMapReady: () {
                              mapController.fitCamera(
                                CameraFit.bounds(
                                  bounds: bounds,
                                  padding: const EdgeInsets.all(30),
                                ),
                              );
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                              subdomains: ['a', 'b', 'c', 'd'],
                            ),

                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: route,
                                  strokeWidth: 6,
                                  color: Colors.blue,
                                ),
                              ],
                            ),

                            MarkerLayer(
                              markers: [
                                // START MARKER
                                Marker(
                                  point: LatLng(
                                    ongoingTrip!.startLatitude,
                                    ongoingTrip!.startLongitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                ),

                                // DESTINATION MARKER
                                Marker(
                                  point: LatLng(
                                    ongoingTrip!.destLatitude,
                                    ongoingTrip!.destLongitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.flag,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),

                                if (driverPosition != null)
                                  Marker(
                                    point: LatLng(
                                      driverPosition!.latitude,
                                      driverPosition!.longitude,
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Colors.blue,
                                      size: 40,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),

              SizedBox(height: 20),

              Text(
                "Upcoming Trips",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              isPlannedLoading
                  ? Center(child: CircularProgressIndicator())
                  : plannedTrips.isEmpty
                  ? Text(
                      "No planned trips",
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: plannedTrips.map((trip) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder(
                                      future: Future.wait([
                                        getPlaceName(
                                          trip.startLatitude,
                                          trip.startLongitude,
                                        ),

                                        getPlaceName(
                                          trip.destLatitude,
                                          trip.destLongitude,
                                        ),
                                      ]),

                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Padding(
                                            padding: EdgeInsets.all(10),

                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final start = snapshot.data![0];

                                        final end = snapshot.data![1];

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,

                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  Text(
                                                    "From: $start",

                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),

                                                  SizedBox(height: 6),

                                                  Text(
                                                    "To: $end",

                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Text(
                                              formatTripDate(
                                                trip.plannedStartTime,
                                              ),

                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
