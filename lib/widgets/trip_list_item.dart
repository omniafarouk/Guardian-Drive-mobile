import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:intl/intl.dart';

import '../utils/location_helper.dart';

// 🔁 format date
String formatTripDate(DateTime date) {
  return DateFormat("MMM d 'at' h:mm").format(date);
}

class TripListItem extends StatelessWidget {
  final Trip trip;

  const TripListItem({super.key, required this.trip});

  // 🎯 location builder (safe FutureBuilder)
  Widget _buildLocation(Future<String> future, TextStyle textStyle) {
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            "Loading...",
            style: textStyle,
          );
        }

        if (snapshot.hasError) {
          return Text(
            "Unknown",
            style: textStyle,
          );
        }

        return Text(
          snapshot.data ?? "Unknown",
          style: textStyle,
        );
      },
    );
  }

  // 🎨 shared style
  TextStyle get _textStyle => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        // 📍 Labels
        // Expanded(
        //   flex: 1,
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.start,
        //     children: <Widget>[
        //       Text('From', style: _textStyle),
        //       Text('To', style: _textStyle),
        //     ],
        //   ),
        // ),

        // 🌍 Locations (lat/lng → name)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildLocation(
                getLocationName(trip.startLatitude, trip.startLongitude),TextStyle(fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],)
              ),
              _buildLocation(
                getLocationName(trip.destLatitude, trip.destLongitude),_textStyle
              ),
            ],
          ),
        ),

        // ⏱ Date
        Expanded(
          flex: 2,
          child: Text(
            formatTripDate(trip.startTime),
            style: _textStyle,
          ),
        ),

        // ➡ Navigation
        Expanded(
          flex: 1,
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/trip-details',
                arguments: trip.tripId,
              );
            },
            icon: const Icon(
              Icons.keyboard_arrow_right,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:guardian_drive_mobile/models/trip.dart';
// import 'package:intl/intl.dart';
//
// import '../utils/location_helper.dart';
//
// // 🔁 format date
// String formatTripDate(DateTime date) {
//   return DateFormat("MMM d 'at' h:mm").format(date);
// }
//
// class TripListItem extends StatelessWidget {
//   final Trip trip;
//
//   const TripListItem({super.key, required this.trip});
//
//   // 🎯 location builder (FutureBuilder stays the same)
//   Widget _buildLocation(Future<String> future) {
//     return FutureBuilder<String>(
//       future: future,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Text("Loading...", style: _textStyle);
//         }
//
//         if (snapshot.hasError) {
//           return Text("Unknown", style: _textStyle);
//         }
//
//         return Text(
//           snapshot.data ?? "Unknown",
//           style: _textStyle,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         );
//       },
//     );
//   }
//
//   TextStyle get _textStyle => const TextStyle(
//     fontSize: 15,
//     fontWeight: FontWeight.w500,
//     color: Colors.white,
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     return Table(
//       columnWidths: const {
//         0: FixedColumnWidth(60),   // From/To labels
//         1: FlexColumnWidth(),      // Location
//         2: FixedColumnWidth(110),  // Date
//         3: FixedColumnWidth(40),   // Icon
//       },
//       defaultVerticalAlignment: TableCellVerticalAlignment.middle,
//       children: [
//         // 📍 FIRST ROW (From)
//         TableRow(
//           children: [
//             Text('From', style: _textStyle),
//             _buildLocation(
//               getLocationName(trip.startLatitude, trip.startLongitude),
//             ),
//             Text(
//               formatTripDate(trip.startTime),
//               style: _textStyle,
//               textAlign: TextAlign.center,
//             ),
//             IconButton(
//               onPressed: () {
//                 Navigator.pushNamed(
//                   context,
//                   '/trip-details',
//                   arguments: trip.tripId,
//                 );
//               },
//               icon: const Icon(
//                 Icons.keyboard_arrow_right,
//                 color: Colors.white,
//                 size: 30,
//               ),
//             ),
//           ],
//         ),
//
//         // 📍 SECOND ROW (To)
//         TableRow(
//           children: [
//             Text('To', style: _textStyle),
//             _buildLocation(
//               getLocationName(trip.destLatitude, trip.destLongitude),
//             ),
//             const SizedBox(), // empty cell
//             const SizedBox(), // empty cell
//           ],
//         ),
//       ],
//     );
//   }
// }