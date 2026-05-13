import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:guardian_drive_mobile/utils/location_helper.dart';

String formatTripDate(DateTime date) {
  return DateFormat("MMM d 'at' h:mm").format(date);
}

class AlertListItem extends StatelessWidget {
  final Alert alert;
  const AlertListItem({super.key, required this.alert});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getLocationName(
        alert.triggeredLocation.latitude,
        alert.triggeredLocation.longitude,
      ),
      builder: (context, snapshot) {
        final locationName = snapshot.data ?? "Loading...";
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: Text(
                locationName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 10),
            Text(
              formatTripDate(alert.generatedAt),
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
                  '/alert-details',
                  arguments: alert.alertId,
                );
              },
              icon: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }
}
