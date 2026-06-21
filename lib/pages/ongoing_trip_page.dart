import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:guardian_drive_mobile/models/alert_request.dart';
import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/alert_api_service.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:flutter/material.dart';

class OngoingTripPage extends StatefulWidget {
  const OngoingTripPage({super.key});

  @override
  State<OngoingTripPage> createState() => _OnGoingTripState();
}

/*
-- TODO: THIS MUST BE CALLED IN THE DASHBOARD @ START TRIP BUTTON --
TripService().startTrip(tripId);

*/

class _OnGoingTripState extends State<OngoingTripPage> {
  VitalReadings? _latestReading;
  StreamSubscription<VitalReadings>? _sub;
  int tripId = 17; // MUST BE CHANGED
  int triggeredLocationId = 22; // MUST BE CHANGED

  // Note: using TripService must be the same instance so either create tripService and aggregate it through the pages
  // OR: (what is now implemented) -- make it a one single object once a tripService instance created and return it -- singleton pattern --

  @override
  void initState() {
    super.initState();
    // Subscribe to the same broadcast stream
    _sub = TripService().vitalsStream.listen((reading) {
      setState(() => _latestReading = reading);
    });
  }

  @override
  void dispose() {
    _sub?.cancel(); // always cancel on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OnGoing Trip", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 1, 21, 51),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 1, 21, 51),
              Color.fromARGB(255, 7, 17, 26),
            ],
          ),
        ),
        child: Column(
          children: [
            Text("ONGOING TRIP"),
            ElevatedButton(
              onPressed: _showConfirmSOSDialog, // button calls the method
              child: Text("Show Dialog"),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmSOSDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(child: const Text("Request Help ?")),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.green, // button background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'NO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red, // button background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'YES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade200,
              ),
            ),
            onPressed: () async {
              Navigator.pop(context); // close confirm dialog

              // 1. Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false, // user can't dismiss it
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Sending SOS Alert..."),
                    ],
                  ),
                ),
              );
              // 2. Wait for the API call
              await triggerSOS(context);
              // TODO : trigger SOS Alert + create a loading widget or something till alert is triggered
            },
          ),
        ],
      ),
    );
  }

  Future<void> triggerSOS(BuildContext context) async {
    try {
      if (_latestReading == null) {
        // Show snackbar or dialog — too early, no reading yet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Health data not yet available, please wait')),
        );
        return;
      }
      AlertRequest alertRequest = AlertRequest(
        type: alertType.SOS,
        tripId: tripId,
        triggeredLocationId: triggeredLocationId,
        heartRate: _latestReading!.heartRate,
        spo2: _latestReading!.spo2,
        temp: _latestReading!.temp,
      );

      final alert = await AlertApiService.triggerSOSAlert(alertRequest);

      // 3. Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // 4. Show first aid guidance with the returned data
      if (context.mounted) _showFirstAidGuidanceDialog(alert);
    } catch (e) {
      // Close loading dialog and show error
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Failed to send SOS"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  // ---------- TODO : its actually guidance that is to send not alert ------------
  void _showFirstAidGuidanceDialog(Alert? alert) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(child: Text('HELP IS ON THE WAY!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          // shrinks to content height, doesn't fill screen
          children: [
            Text(
              //'Emergency services have been notified '
              //'and are on their way to your location.'
              'Please follow the following instructions for your safety',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              // TODO : put first aid guidance instructions here
              'ETA: 10 minutes',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
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
}

/*  -- temporarily triggerSOS() if the above failed due to not pop-ing the diaload catalog correctly ---
// REMOVE LATER IF EVERYTHING WORKS FINE

Future<void> triggerSOS() async {
  // Use a GlobalKey to target the loading dialog specifically
  final loadingKey = GlobalKey<NavigatorState>();

  if (_latestReading == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Health data not yet available, please wait')),
    );
    return;
  }

  // Capture the navigator before any async gap
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Show loading dialog and keep its context
  BuildContext? loadingContext;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      loadingContext = ctx; // capture dialog's own context
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Sending SOS Alert..."),
          ],
        ),
      );
    },
  );

  try {
    AlertRequest alertRequest = AlertRequest(
      type: alertType.SOS,
      tripId: tripId,
      triggeredLocationId: triggeredLocationId,
      heartRate: _latestReading?.heartRate,
      spo2: _latestReading?.spo2,
      temp: _latestReading?.temp,
    );

    final alert = await AlertApiService.triggerSOSAlert(alertRequest);

    // Close loading dialog precisely
    if (loadingContext != null && loadingContext!.mounted) {
      navigator.pop();
    }

    // Show first aid dialog
    if (context.mounted) _showFirstAidGuidanceDialog(alert);

  } catch (e) {
    if (loadingContext != null && loadingContext!.mounted) {
      navigator.pop();
    }
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Failed to send SOS"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), // use ctx not context
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}

*/
