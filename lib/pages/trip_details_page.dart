import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/services/medical_info_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/future_table_row.dart';
import 'package:intl/intl.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/models/car.dart';
import '../services/trip_service.dart';
import '../services/car_service.dart';
import '../widgets/map.dart' as MapDrawer;
import 'package:guardian_drive_mobile/utils/location_helper.dart';
import '../services/car_ble_service.dart';
import '../models/enums.dart';

import 'package:guardian_drive_mobile/services/band_ble_service.dart';
// import 'package:guardian_drive_mobile/services/band_ble_simulator_service.dart';


String _formatTripDate(DateTime date) {
  return DateFormat("MMM d, yyyy 'at' h:mm a").format(date);
}

Color getStatusColor(TripStatus status) {
  switch (status) {
    case TripStatus.PLANNED:
      return Colors.orange;
    case TripStatus.ONGOING:
      return Colors.green;
    case TripStatus.CANCELLED:
      return Colors.red;
    case TripStatus.COMPLETED:
      return Colors.blue;
  }
}

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  Trip? trip;
  Car? car;
  bool tripIsLoading = true;
  bool carIsLoading = true;
  bool buttonActionLoading = false;
  bool _predriveCheckLoading = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loaded) return;
    _loaded = true;

    final tripId = ModalRoute.of(context)!.settings.arguments as int;
    _fetchTrip(tripId);
  }

  void _fetchTrip(int tripId) async {
    setState(() {
      tripIsLoading = true;
    });
    try {
      final response = await TripService().getTripById(tripId);
      setState(() {
        trip = response;
      });
      if (trip!.engineId != null) {
        _fetchCar(trip!.engineId!);
      }
    } finally {
      setState(() {
        tripIsLoading = false;
      });
    }
  }

  void _fetchCar(String engineId) async {
    setState(() {
      carIsLoading = true;
    });
    try {
      final response = await CarService().getCarById(engineId);
      setState(() {
        car = response;
      });
    } finally {
      setState(() {
        carIsLoading = false;
      });
    }
  }

  void navigateToOngoingPage() {
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/ongoing-trip',
      arguments: {
        "destLatitude": trip!.destLatitude,
        "destLongitude": trip!.destLongitude,
        "startLatitude": trip!.startLatitude,
        "startLongitude": trip!.startLongitude,
      },
    );
  }

  Future<void> _startTrip() async {
    if (trip == null) return;
    setState(() {
      buttonActionLoading = true;
    });
    try {
      traceLog("tripId", trip!.tripId);

      // 1. fetch driver thresholds for trip predrivecheck and tracking
      DriverHealthThresholds thresholds = await MedicalInfoService()
          .getDriverThresholds();

      // FOR NOW : SHOULD BE REMOVED
      thresholds = DriverHealthThresholds(
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
      _showPredriveCheckDialog();
      // 2. Start (predrive health check)
      bool checkPassed = await TripService().startPreDriveCheck(
        thresholds: thresholds,
      );
      if (mounted) Navigator.pop(context);
      if (!checkPassed) {
        traceLog(' COULDN\'T START TRIP!!! ');
        _showDialog(
          "Predrive check failure",
          "Can't start trip, predrive health check failed.",
        );
        return;
      }

      // 3. start trip in database
      final updatedTrip = await TripService().patchTrip(
        trip!.tripId,
        TripStatus.ONGOING,
      );
      setState(() {
        trip = updatedTrip;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip started successfully')),
      );

      // 4. start Trip Tracking and update activetripId
      TripService().startTripTracking(
        tripId: trip!.tripId,
        thresholds: thresholds,
      );
      navigateToOngoingPage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        buttonActionLoading = false;
      });
    }
  }

  void _showPredriveCheckDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user can't dismiss it
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 1, 21, 51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Pre-drive Check In Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please wait a few seconds…',
              style: TextStyle(color: Color(0xFF979797), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(child: Text(title)),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 1, 21, 51),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (tripIsLoading || trip == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF060B21),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    bool canStartTrip =
        trip!.status == TripStatus.PLANNED &&
        DateTime.now().isAfter(trip!.plannedStartTime);
    return Scaffold(
      backgroundColor: Color(0xFF060B21),
      appBar: AppBar(
        iconTheme: IconThemeData(size: 30, color: Colors.white),
        backgroundColor: Colors.transparent,
        title: Text(
          'Trip Detail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Container(
              margin: EdgeInsets.fromLTRB(15, 25, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Trip #${trip!.tripId} - ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        trip!.status.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: getStatusColor(trip!.status),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40.0),
                      child: MapDrawer.Map(
                        trip!.startLatitude,
                        trip!.startLongitude,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(), // icon column (tight)
                        1: FixedColumnWidth(20),
                        2: IntrinsicColumnWidth(), // text column (tight)
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        _buildRow(
                          Icons.watch_later_outlined,
                          Colors.white,
                          //change to add actual startTime
                          _formatTripDate(trip!.plannedStartTime),
                        ),
                        buildRowFuture(
                          Icons.radio_button_on_sharp,
                          Colors.lightBlueAccent,
                          getLocationName(
                            trip!.startLatitude,
                            trip!.startLongitude,
                          ),
                        ),

                        buildRowFuture(
                          Icons.radio_button_on_sharp,
                          Colors.greenAccent,
                          getLocationName(
                            trip!.destLatitude,
                            trip!.destLongitude,
                          ),
                        ),
                        // _buildRow(
                        //   Icons.radio_button_on_sharp,
                        //   Colors.lightBlueAccent,
                        //   trip.startPoint,
                        // ),
                        // _buildRow(
                        //   Icons.radio_button_on_sharp,
                        //   Colors.greenAccent,
                        //   trip.destPoint,
                        // ),
                        if (trip!.endTime != null)
                          _buildRow(
                            Icons.check_circle_outlined,
                            Colors.white,
                            _formatTripDate(trip!.endTime!),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  _showVehicle(car, carIsLoading),
                  //   _VehicleCard(car: car!),
                  SizedBox(height: 15),
                  // start trip button
                  trip!.status == TripStatus.ONGOING
                      ? ElevatedButton(
                          onPressed: () {
                            navigateToOngoingPage();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2935E0),
                            minimumSize: const Size(150, 50),
                          ),
                          child: Text(
                            "Go To Maps",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        )
                      : canStartTrip
                      ? ElevatedButton(
                          onPressed: () {
                            // can't start more than one trip
                            if (TripService().activeTripId != null) {
                              _showDialog(
                                "Can't Start Trip",
                                "You already have an ongoing trip",
                              );
                              return;
                            }
                            final carReady =
                                CarBleService.instance.status ==
                                BleDeviceStatus.ready;
                            final bandReady =
                                BandBleService.instance.status ==
                                BleDeviceStatus.ready;
                            print("CAR STATUS $carReady");
                            print("BAND STATUS $bandReady");

                            if (!carReady && !bandReady) {
                              _showDialog(
                                "Connection Problem",
                                "Please connect both the band and vehicle first",
                              );
                              return; // important — stop here
                            }
                            if (!bandReady) {
                              _showDialog(
                                "Band Connection",
                                "Please connect the driver band first",
                              );
                              return;
                            }
                            if (!carReady) {
                              _showDialog(
                                "Car Connection",
                                "Please connect the vehicle first",
                              );
                              return;
                            }
                            buttonActionLoading ? null : _startTrip();
                            print('start trip checkings');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2935E0),
                            minimumSize: const Size(150, 50),
                          ),
                          child: Text(
                            "Start Trip",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(150, 50),
                            side: BorderSide(width: 2, color: Colors.white),
                          ),
                          child: Text(
                            'Start Trip',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _showVehicle(Car? car, bool carIsLoading) {
  //final Car car;
  // final bool carIsLoading;
  // const _showVehicle({required this.car, required this.carIsLoading});
  if (car == null) {
    return const SizedBox.shrink();
  }
  if (carIsLoading) {
    return const CircularProgressIndicator();
  } else {
    return _VehicleCard(car: car);
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.car});

  //final Trip trip;
  final Car car;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
      color: Color(0x26FFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'Vehicle Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(height: 5, thickness: 2, color: Color(0xFF363636)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Model:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF979797),
                    ),
                  ),
                  Text(
                    'Chevrolet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Plate:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF979797),
                    ),
                  ),
                  Text(
                    car.plateNo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Color:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF979797),
                    ),
                  ),
                  Text(
                    car.color,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TableRow _buildRow(IconData icon, Color iconColor, String data) {
  return TableRow(
    children: <Widget>[
      Icon(icon, size: 23, color: iconColor),
      SizedBox(width: 20),
      Text(
        data,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    ],
  );
}
