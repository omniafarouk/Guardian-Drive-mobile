import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:intl/intl.dart';

String formatTripDate(DateTime date) {
  return DateFormat("MMM d 'at' h:mm").format(date);
}

class TripListItem extends StatelessWidget {
  final Trip trip;
  const TripListItem({super.key, required this.trip});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          children: <Widget>[
            Text(
              'From',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Text(
              'To',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Column(
          children: <Widget>[
            Text(
              trip.startPoint,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Text(
              trip.destPoint,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          formatTripDate(trip.startTime),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/trip_details',
              arguments: trip.tripId,
            );
          },
          icon: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30),
        ),
      ],
    );
  }
}
