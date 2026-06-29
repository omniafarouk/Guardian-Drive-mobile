import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/services/car_ble_service.dart';
import 'package:guardian_drive_mobile/services/location_service.dart';
import 'package:guardian_drive_mobile/services/route_service.dart'
    as routeservice;
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/location_helper.dart';
import 'package:guardian_drive_mobile/utils/readings_status_colors.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/custom_card.dart';
import 'package:guardian_drive_mobile/widgets/future_table_row.dart';
import 'package:guardian_drive_mobile/widgets/sos_dialog_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// import 'package:guardian_drive_mobile/services/band_ble_service.dart';
import 'package:guardian_drive_mobile/services/band_ble_simulator_service.dart';

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
  bool _mapReady = false;
  DateTime? _lastReroute;
  int _lastClosestIdx = 0;

  LatLng? _lastSavedLocation;
  DateTime? _lastLocationWrite;
  // bool locationLoaded = false;
  // bool routeLoaded = false;

  TileLayer get openStreetMapTileLayer => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'dev.fleafelt.flutter_map.example',
  );

  void _maybeSaveLocation(LatLng newLocation) {
    final now = DateTime.now();
    if (_lastSavedLocation == null) {
      LocationService.createTripLocation(
        newLocation.latitude,
        newLocation.longitude,
      );
      return;
    }
    final movedMeters = Distance().as(
      LengthUnit.Meter,
      _lastSavedLocation!,
      newLocation,
    );
    final timeSinceLastWrite = now.difference(_lastLocationWrite!);
    if (movedMeters >= 100 || timeSinceLastWrite >= Duration(minutes: 1)) {
      LocationService.createTripLocation(
        newLocation.latitude,
        newLocation.longitude,
      );
    }
  }

  void endTrip() async {
    print("Ending trip..");
    await TripService().patchTrip(
      TripService().activeTripId!,
      TripStatus.COMPLETED,
    );
    TripService().endTripTracking();
    BandBleService.instance.stopBand();
    CarBleService.instance.stopCar();
  }

  int getClosestRouteIndex(LatLng current, List<LatLng> route) {
    final Distance distance = Distance();

    final int windowSize = 20;
    final int start = _lastClosestIdx;
    final int end = (start + windowSize).clamp(0, route.length - 1);

    int closestIdx = start;
    double minDist = double.infinity;

    for (int i = start; i <= end; i++) {
      final d = distance.as(LengthUnit.Meter, current, route[i]);
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }
    _lastClosestIdx = closestIdx;
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

  bool _shouldReroute() {
    if (_lastReroute == null) return true;
    return DateTime.now().difference(_lastReroute!) >
        const Duration(minutes: 1);
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
              _maybeSaveLocation(LatLng(position.latitude, position.longitude));
              if (route.isEmpty) {
                loadRoute(destLat, destLong).then((points) {
                  setState(() {
                    route = points;
                    _lastClosestIdx = 0;
                  });
                });
              }
            });
            // check if current location deviates from route
            if (route.isNotEmpty && isOffRoute(position) && _shouldReroute()) {
              _lastReroute = DateTime.now();
              print('reloaded route');
              loadRoute(destLat, destLong).then((points) {
                setState(() {
                  route = points;
                });
              });
            }
            if (_mapReady) {
              mapController.move(
                LatLng(currentLat!, currentLong!),
                mapController.camera.zoom,
              );
            }
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
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: TripService.instance.tripIsActiveNotifier,
        builder: (context, tripIsActive, child) {
          return tripIsActive
              ? FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    traceLog('SOS TRIGGERED');
                    // await showConfirmSOSDialog(context, _latestReading);
                  },
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const SizedBox.shrink(); // renders nothing when no trip
        },
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              onMapReady: () {
                setState(() => _mapReady = true); // ✅ map is ready now
              },

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
            left: 0,
            right: 0,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: Card(
                  color: Color.fromARGB(255, 1, 21, 51),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            remainingDistance == null
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    remainingDistance! > 1000
                                        ? '${(remainingDistance! / 10000).toStringAsFixed(2)} Km'
                                        : '${remainingDistance!.toStringAsFixed(2)} m',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
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
            ),
          ),
          // SLIDER
          DraggableScrollableSheet(
            initialChildSize: 0.18, // collapsed height
            minChildSize: 0.18,
            maxChildSize: 0.5, // how far it can expand
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 1, 21, 51),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // vitals row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: BandBleService.instance.tempNotifier,
                          builder: (context, temp, child) {
                            return CustomCard(
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.thermostat_outlined,
                                      color: Colors.orangeAccent,
                                      size: 38,
                                    ),
                                    Column(
                                      children: [
                                        const Text(
                                          'Temperature',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '$temp °C',
                                          style: TextStyle(
                                            color: getTempStatusColor(temp),
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: BandBleService.instance.bpmNotifier,
                          builder: (context, bpm, child) {
                            return CustomCard(
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.monitor_heart_rounded,
                                      color: Colors.redAccent,
                                      size: 38,
                                    ),
                                    SizedBox(width: 5),
                                    Column(
                                      children: [
                                        const Text(
                                          'BPM',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '$bpm',
                                          style: TextStyle(
                                            color: getBPMStatusColor(bpm),
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ValueListenableBuilder(
                      valueListenable: BandBleService.instance.spO2Notifier,
                      builder: (context, spO2, child) {
                        double percent = spO2 / 150;
                        return CircularPercentIndicator(
                          radius: 46,
                          lineWidth: 8,
                          percent: percent.clamp(0.0, 1.0),
                          animation: true,
                          progressColor: Colors.white,
                          backgroundColor: Colors.white24,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "SpO₂",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "$spO2",
                                style: TextStyle(
                                  color: getSpOStatusColor(spO2),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),
                    // stop trip button
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          // endTrip();
                          // Navigator.pop(context);
                          final shouldEndTrip = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('End Trip'),
                              content: const Text(
                                'Are you sure you want to end the trip?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false); // No
                                  },
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context, true); // Yes
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );

                          if (shouldEndTrip == true) {
                            endTrip();
                            Navigator.pop(context); // Close the current page
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'End Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
