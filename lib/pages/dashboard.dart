import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geocoding/geocoding.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/models/enums.dart';
import 'package:guardian_drive_mobile/services/band_ble_service.dart';
import 'package:guardian_drive_mobile/services/band_service.dart';
import 'package:guardian_drive_mobile/services/car_ble_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/custom_card.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';
import 'package:guardian_drive_mobile/widgets/sos_dialog_popup.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:guardian_drive_mobile/services/home_service.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/models/trip_location.dart';
//import 'package:geolocator/geolocator.dart';
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
  double bpm = 0.0;
  double temp = 0.0;
  double spO2 = 0.0;
  // int battery = 0;
  // bool isConnected = false;
  String username = "";
  String startLocName = "";
  String destLocName = "";
  Timer? timer;
  // Random random = Random();

  Trip? ongoingTrip;
  TripLocation? currentLocation;
  // Position? driverPosition;

  bool isLoading = true;
  List<Trip> plannedTrips = [];
  bool isPlannedLoading = true;

  VitalReadings? _latestReading;
  late StreamSubscription<VitalReadings> _sub;
  final Duration reloadBpmRange = Duration(seconds: 10);

  // ------💡 TESTINGGGGG -----
  final tripId = 26;

  StreamSubscription? bandBleSub;
  StreamSubscription? carBleSub;
  @override
  void initState() {
    super.initState();

    bandBleSub = BandBleService.instance.messagesController.stream.listen((
      data,
    ) {
      print("BAND BLE DATA FROM DASHBOARD: $data");

      // you can update UI here too using setState if needed
    });
    carBleSub = CarBleService.instance.messagesController.stream.listen((data) {
      print("CAR BLE DATA FROM DASHBOARD: $data");

      // you can update UI here too using setState if needed
    });
    initDashboard();
    startLiveReadings();
    // startTracking();
    // Subscribe to the same broadcast stream
    // _sub = BandBleService.instance.telemetryController.stream.listen((reading) {
    //   _latestReading = reading; // no setState — just store it quietly
    // });

    _sub = TripService().vitalsStream.listen((reading) {
      // setState(() => _latestReading = reading);
      _latestReading = reading; // no setState — just store it quietly
    });
  }

  @override
  void dispose() {
    _sub.cancel(); // always cancel on dispose
    timer?.cancel();
    carBleSub?.cancel();
    bandBleSub?.cancel();
    super.dispose();
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
    // await getBandData();
    await getusername();
    await loadTripLocation(token!);
    await loadPlannedTrips();
  }

  Future<void> loadTripLocation(String token) async {
    try {
      final trip = await HomeService.getOnGoingTrip(token);

      if (trip == null) {
        setState(() => isLoading = false);
        return;
      }
      setState(() {
        ongoingTrip = trip; // ✅ set trip immediately, regardless of location
        TripService().activateTrip(trip.tripId);
        isLoading = false;
      });

      // load location separately — failure won't affect trip display
      try {
        final location = await HomeService().getTripLocation(
          trip.tripId,
          token,
        );
        setState(() => currentLocation = location);
        await loadRoute();
      } catch (e) {
        // location not available yet — that's fine, trip still shows
        print("No location yet for trip: $e");
        setState(() => currentLocation = null);
      }

      print("TRIP ID: ${trip.tripId}");
    } catch (e) {
      print("Trip load error: $e");
      setState(() => isLoading = false);
    }
  }
  // Future<void> loadTripLocation(String token) async {
  //   try {
  //     final trip = await HomeService.getOnGoingTrip(token);

  //     if (trip == null) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //       return;
  //     }

  //     final location = await HomeService().getTripLocation(trip.tripId, token);

  //     setState(() {
  //       ongoingTrip = trip;
  //       currentLocation = location;
  //       isLoading = false;
  //     });
  //     await loadRoute();

  //     print("TRIP ID: ${trip.tripId}");
  //     print("LAT: ${location.latitude}");
  //     print("LNG: ${location.longitude}");
  //   } catch (e) {
  //     if (e.toString().contains("Failed to load location")) {
  //       setState(() {
  //         currentLocation = null;
  //         ongoingTrip = trip;
  //         isLoading = false;
  //       });

  //       return;
  //     }

  //     print("Trip load error: $e");

  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

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

  // Future<void> getBandData() async {
  //   final result = await WearableService.getWearableBand();

  //   if (result["status"] == "no_band") {
  //     setState(() {
  //       battery = 0;
  //       isConnected = false;
  //     });
  //     return;
  //   }

  //   if (result["status"] == "error") {
  //     setState(() {
  //       battery = 0;
  //       isConnected = false;
  //     });
  //     return;
  //   }

  //   final WearableBand band = result["data"];

  //   setState(() {
  //     battery = band.batteryLevel;
  //     isConnected = band.isConnected;
  //   });
  // }

  void startLiveReadings() {
    timer = Timer.periodic(reloadBpmRange, (_) {
      // refresh the live bpm every 10 seconds not on real readings , is this correct tho??
      if (!mounted) return;
      setState(() {
        bpm = _latestReading?.heartRate ?? bpm;
        spO2 = _latestReading?.spo2 ?? spO2;
        temp = _latestReading?.temp ?? temp;
      }); // just rebuild — _latestReading already has the latest
    });
  }

  /* void startTracking() {
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
*/
  getBandConnectionStatus() {
    switch (BandBleService.instance.status) {
      case BleDeviceStatus.disconnected:
        return "No Band";
      case BleDeviceStatus.connecting:
        return "Connecting..";
      case BleDeviceStatus.connected:
        return "Running precheck..";
      case BleDeviceStatus.precheckFailed:
        return "Precheck Failed, Please Contact Your fleet manager.";
      case BleDeviceStatus.ready:
        return "Connected";
    }
  }

  getCarConnectionStatus() {
    switch (BandBleService.instance.status) {
      case BleDeviceStatus.disconnected:
        return "No Car Connected.";
      case BleDeviceStatus.connecting:
        return "Connecting..";
      case BleDeviceStatus.connected:
        return "Running precheck..";
      case BleDeviceStatus.precheckFailed:
        return "Precheck Failed, Please Contact Your fleet manager.";
      case BleDeviceStatus.ready:
        return "Connected";
    }
  }

  Color getBatteryStatusColor(int batt) {
    if (BandBleService.instance.status != BleDeviceStatus.ready)
      return Colors.grey;
    if (batt < 20) {
      return Colors.redAccent;
    }
    return Colors.greenAccent;
  }

  Color getBPMStatusColor() {
    if (BandBleService.instance.status != BleDeviceStatus.ready)
      return Colors.grey;
    if (bpm >= 120) {
      return Colors.redAccent;
    } else if (bpm >= 90 && bpm < 120) {
      return Colors.amberAccent;
    } else
      return Colors.greenAccent;
  }

  Color getSpOStatusColor() {
    if (BandBleService.instance.status != BleDeviceStatus.ready)
      return Colors.grey;
    if (spO2 <= 100) {
      return Colors.redAccent;
    } else if (spO2 >= 95 && spO2 <= 97) {
      return Colors.amberAccent;
    } else
      return Colors.greenAccent;
  }

  Color getTempStatusColor() {
    if (BandBleService.instance.status != BleDeviceStatus.ready)
      return Colors.grey;
    if (temp >= 36.5 && temp <= 37.5) {
      return Colors.greenAccent;
    } else if (temp > 36.5 && temp < 36.5 || temp > 37.5 && temp < 38) {
      return Colors.amberAccent;
    } else {
      return Colors.redAccent;
    }
  }

  Color getBandStatusColor() {
    switch (BandBleService.instance.status) {
      case BleDeviceStatus.disconnected:
        return Colors.grey;
      case BleDeviceStatus.connecting:
        return Colors.white;
      case BleDeviceStatus.connected:
        return Colors.white;
      case BleDeviceStatus.precheckFailed:
        return Colors.redAccent;
      case BleDeviceStatus.ready:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = bpm / 150;
    // final bounds = route.isNotEmpty
    //     ? LatLngBounds.fromPoints(route)
    //     : LatLngBounds.fromPoints([
    //         LatLng(
    //           ongoingTrip?.startLatitude ?? 0,
    //           ongoingTrip?.startLongitude ?? 0,
    //         ),
    //         LatLng(
    //           ongoingTrip?.destLatitude ?? 0,
    //           ongoingTrip?.destLongitude ?? 0,
    //         ),
    //       ]);

    return Scaffold(
      appBar: CustomAppBar(title: "Overview"),
      drawer: const SideBarDrawer(),

      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: TripService.instance.tripIsActiveNotifier,
        builder: (context, tripIsActive, child) {
          return tripIsActive
              ? FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    traceLog('SOS TRIGGERED');
                    await showConfirmSOSDialog(context, _latestReading);
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

      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: GradientBackground(
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
                Text(
                  "Band Status",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: BandBleService.instance.statusNotifier,
                        builder: (context, status, child) {
                          final bandConnected =
                              status == BleDeviceStatus.connected ||
                              status == BleDeviceStatus.ready;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    getBandConnectionStatus(),
                                    style: TextStyle(
                                      color: getBandStatusColor(),
                                      // getStatusColor(bpm),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (!bandConnected)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        0,
                                        0,
                                      ),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.bluetooth),
                                        label: const Text('Connect to band'),

                                        onPressed: () {
                                          BandBleService.instance
                                              .scanAndConnect();
                                        },
                                      ),
                                    ),
                                ],
                              ),

                              SizedBox(height: 10),
                              ValueListenableBuilder<int>(
                                valueListenable:
                                    BandBleService.instance.battNotifier,
                                builder: (context, batt, _) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getBatteryStatusColor(batt),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "$batt%",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),

                      CircularPercentIndicator(
                        radius: 55,
                        lineWidth: 8,
                        percent: percent.clamp(0.0, 1.0),
                        animation: true,
                        progressColor: getBPMStatusColor(),
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
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          CustomCard(
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
                                    Icons.thermostat_outlined,
                                    color: Colors.orangeAccent,
                                    size: 40,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'Temperature',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        '$temp °C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'TEMP STATUS',
                                        style: TextStyle(
                                          color: getTempStatusColor(),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          CustomCard(
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
                                    Icons.bloodtype,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'SpO₂',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        '$spO2 %',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'Spo2 status',
                                        style: TextStyle(
                                          color: getSpOStatusColor(),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "Car Status",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: CarBleService.instance.statusNotifier,
                        builder: (context, status, child) {
                          final carConnected =
                              status == BleDeviceStatus.connected ||
                              status == BleDeviceStatus.ready;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    getCarConnectionStatus(),
                                    style: TextStyle(
                                      color: getBandStatusColor(),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (!carConnected)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        0,
                                        0,
                                      ),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.bluetooth),
                                        label: const Text('Connect to Car'),

                                        onPressed: () {
                                          CarBleService.instance
                                              .scanAndConnect();
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ongoing Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (ongoingTrip != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => {
                              Navigator.pushNamed(
                                context,
                                '/ongoing-trip',
                                arguments: {
                                  "destLatitude": ongoingTrip!.destLatitude,
                                  "destLongitude": ongoingTrip!.destLongitude,
                                  "startLatitude": ongoingTrip!.startLatitude,
                                  "startLongitude": ongoingTrip!.startLongitude,
                                },
                              ),
                            },
                            label: Text('Go to map'),
                            icon: Icon(Icons.arrow_forward_rounded),
                          ),
                        ],
                      ),
                  ],
                ),

                SizedBox(height: 10),

                Container(
                  height: 150,
                  width: double.infinity,
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ongoingTrip == null
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
                                if (route.isNotEmpty) {
                                  mapController.fitCamera(
                                    CameraFit.bounds(
                                      bounds: LatLngBounds.fromPoints(route),
                                      padding: const EdgeInsets.all(30),
                                    ),
                                  );
                                } else if (ongoingTrip != null) {
                                  final start = LatLng(
                                    ongoingTrip!.startLatitude,
                                    ongoingTrip!.startLongitude,
                                  );
                                  final dest = LatLng(
                                    ongoingTrip!.destLatitude,
                                    ongoingTrip!.destLongitude,
                                  );
                                  if (start.latitude != dest.latitude ||
                                      start.longitude != dest.longitude) {
                                    mapController.fitCamera(
                                      CameraFit.bounds(
                                        bounds: LatLngBounds.fromPoints([
                                          start,
                                          dest,
                                        ]),
                                        padding: const EdgeInsets.all(30),
                                      ),
                                    );
                                  }
                                }
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

                                  /*if (driverPosition != null)
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
                                    ),*/
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
                    fontSize: 18,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                                              child:
                                                  CircularProgressIndicator(),
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
                ElevatedButton(
                  onPressed: () async {
                    try {
                      traceLog("tripId", tripId);
                      final updatedTrip = await TripService().patchTrip(
                        tripId,
                        TripStatus.ONGOING,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trip started successfully'),
                        ),
                      );
                      traceLog("updated Trip", updatedTrip);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }

                    try {
                      DriverHealthThresholds thresholds =
                          DriverHealthThresholds(
                            avgHeartRate: 80,
                            minHeartRate: 60,
                            maxHeartRate: 100,
                            avgSpo2: 96,
                            minSpo2: 95,
                            maxSpo2: 100,
                            avgTemp: 36.5,
                            minTemp: 36.0,
                            maxTemp: 37.5,
                          );

                      // normally should before it call predrive check and update database trip status
                      await TripService().startTripTracking(
                        tripId: tripId,
                        thresholds: thresholds,
                        testMode: true,
                      );
                      print('Trip started — watch console for breach traces');
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Couldn\'t Start Trip:${e.toString().replaceAll('Exception: ', '')}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('TEST: Start Mock Trip'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await TripService().endTripTracking();
                  },
                  child: Text('TEST: End Trip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
