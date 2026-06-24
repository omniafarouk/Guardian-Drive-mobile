import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';

void showConfirmSOSDialog(BuildContext context) {
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
    if (TripService().activeTripId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('There is No Trip Active Now')));
      return;
    }
    // if (_latestReading == null) {
    //   // Show snackbar or dialog — too early, no reading yet
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Health data not yet available, please wait')),
    //   );
    //   return;
    // }
    // AlertRequest alertRequest = AlertRequest(
    //   type: alertType.SOS,
    //   tripId: TripService().activeTripId,
    //   triggeredLocationId: triggeredLocationId,
    //   heartRate: _latestReading!.heartRate,
    //   spo2: _latestReading!.spo2,
    //   temp: _latestReading!.temp,
    // );

    // final alert = await AlertApiService.triggerSOSAlert(alertRequest);

    // 3. Close loading dialog
    if (context.mounted) Navigator.pop(context);

    // 4. Show first aid guidance with the returned data
    // if (context.mounted) _showFirstAidGuidanceDialog(alert);
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
void _showFirstAidGuidanceDialog(Alert? alert, BuildContext context) {
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
