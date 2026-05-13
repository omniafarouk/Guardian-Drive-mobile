import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class Trip {
  final String from;
  final String to;
  final String date;

  Trip({required this.from, required this.to, required this.date});
}

List<Trip> trips = [
  Trip(from: "Alexandria", to: "Cairo", date: "Mar 7 at 2:00"),
  Trip(from: "Giza", to: "Alex", date: "Mar 8 at 5:00"),
  Trip(from: "Cairo", to: "Mansoura", date: "Mar 9 at 1:00"),
];

class _DashboardState extends State<Dashboard> {
  double? lat;
  double? lng;

  int bpm = 72;
  int battery = 95;
  bool isConnected = true;

  Timer? timer;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    startLiveBPM();
    getLocation();
  }

  void startLiveBPM() {
    timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted) {
        return;
      } // saftey check to avoid setState after dispose to avoid error/crash and memory leaks
      setState(() {
        bpm = 65 + random.nextInt(20);
        if (battery > 0 && random.nextBool()) {
          battery--;
        }
      });
    });
  }

  Future<void> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print("Permission permanently denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) {
        return;
      } // saftey check to avoid setState after dispose when location is fetched after user leaves page
      //, otherwise it won't find the widget to update and will throw error/crash
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
      });
    } catch (e) {
      print("Location error: $e");
    }
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
  @override
  Widget build(BuildContext context) {
    double percent = bpm / 150;

    return Scaffold(
      appBar: CustomAppBar(title: "Overview"),
      drawer: const SideBarDrawer(),

      body: GradientBackground(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
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
                        animationDuration: 800,
                        circularStrokeCap: CircularStrokeCap.round,
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
                            Text(
                              "BPM",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
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
                  child: lat == null || lng == null
                      ? Center(child: CircularProgressIndicator())
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat!, lng!),
                              initialZoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                subdomains: ['a', 'b', 'c', 'd'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat!, lng!),
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
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

                Column(
                  children: trips.map((trip) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // From + To (left side)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "From: ${trip.from}",
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "To: ${trip.to}",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          // Date (right side, centered vertically)
                          Text(
                            trip.date,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
