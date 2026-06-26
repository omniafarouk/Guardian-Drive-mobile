// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:guardian_drive_mobile/models/alert.dart';
// import 'package:guardian_drive_mobile/models/alert_request.dart';
// import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
// import 'package:guardian_drive_mobile/services/trip_service.dart';
// import 'package:flutter/material.dart';
// import 'package:guardian_drive_mobile/widgets/sos_dialog_popup.dart';

// class OngoingTripPage extends StatefulWidget {
//   const OngoingTripPage({super.key});

//   @override
//   State<OngoingTripPage> createState() => _OnGoingTripState();
// }

// /*
// -- TODO: THIS MUST BE CALLED IN THE DASHBOARD @ START TRIP BUTTON --
// TripService().startTrip(tripId);

// */

// class _OnGoingTripState extends State<OngoingTripPage> {
//   VitalReadings? _latestReading;
//   StreamSubscription<VitalReadings>? _sub;
//   int tripId = 17; // MUST BE CHANGED
//   int triggeredLocationId = 22; // MUST BE CHANGED

//   // Note: using TripService must be the same instance so either create tripService and aggregate it through the pages
//   // OR: (what is now implemented) -- make it a one single object once a tripService instance created and return it -- singleton pattern --

//   @override
//   void initState() {
//     super.initState();
//     // Subscribe to the same broadcast stream
//     _sub = TripService().vitalsStream.listen((reading) {
//       setState(() => _latestReading = reading as VitalReadings);
//     });
//   }

//   @override
//   void dispose() {
//     _sub?.cancel(); // always cancel on dispose
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("OnGoing Trip", style: TextStyle(color: Colors.white)),
//         backgroundColor: Color.fromARGB(255, 1, 21, 51),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color.fromARGB(255, 1, 21, 51),
//               Color.fromARGB(255, 7, 17, 26),
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             Text("ONGOING TRIP"),
//             ElevatedButton(
//               onPressed: showConfirmSOSDialog(), // button calls the method
//               child: Text("Show Dialog"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
