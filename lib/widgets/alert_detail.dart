/*import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:guardian_drive_mobile/data/vehicle_details.dart';
import 'package:guardian_drive_mobile/models/health_event.dart';

import '../models/alert.dart';
import '../models/incident.dart';
import '../models/location.dart' as Location;
import 'alert_card.dart';
import 'map.dart' as MapDrawer;

class AlertDetail extends StatefulWidget {
  const AlertDetail({super.key});

  @override
  State<AlertDetail> createState() => _AlertDetailState();
}

Alert alert1 = Alert(
  type: alertType.SOS,
  status: alertStatus.ACTIVE,
  locations: [Location.Location(latitude: 1.2878, longitude: 103.8566)],
);

class _AlertDetailState extends State<AlertDetail> {
  Color getAlertStatusColor() {
    switch (alert1.status) {
      case alertStatus.RESOLVED:
        return Colors.teal;
      default:
        return Colors.amber;
    }
  }

  Color getHeartStatusColor() {
    switch (alert1.healthEvent?.heartStatus) {
      case HeartStatus.Critical:
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  Color getHTempStatusColor() {
    switch (alert1.healthEvent?.tempStatus) {
      case BodyTempStatus.Critical:
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  String? address;
  Future<String?> getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      Placemark place = placemarks[0];

      return place.street;
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadAddress() async {
    address = await getAddress(
      alert1.locations.last.latitude,
      alert1.locations.last.longitude,
    );

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadAddress();

    alert1.updateAlert(
      Location.Location(latitude: 1.2880, longitude: 103.8570),
      Incident(
        time: DateTime.now(),
        descrip: incidentDescription.Parking_request,
      ),
    );
    alert1.updateAlert(
      Location.Location(latitude: 1.2890, longitude: 103.8580),
      Incident(time: DateTime.now(), descrip: incidentDescription.No_response),
    );
    alert1.updateAlert(
      Location.Location(latitude: 1.2900, longitude: 103.8600),
      Incident(
        time: DateTime.now(),
        descrip: incidentDescription.Vehicle_control,
      ),
    );
    alert1.updateAlert(
      Location.Location(latitude: 1.2910, longitude: 103.8610),
      Incident(
        time: DateTime.now(),
        descrip: incidentDescription.Service_request,
      ),
    );
    alert1.updateAlert(
      Location.Location(latitude: 1.2920, longitude: 103.8620),
      Incident(
        time: DateTime.now(),
        descrip: incidentDescription.Ambulance_Arrival,
      ),
    );
    print(alert1);
    print(alert1.healthEvent?.tempStatus);
    print(alert1.healthEvent?.heartStatus);

    getAddress(
      alert1.locations[alert1.locations.length - 1].latitude,
      alert1.locations[alert1.locations.length - 1].longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SPACING at the start of page
        const SizedBox(height: 45),
        // ALert Detail Button
        Container(
          alignment: Alignment.topLeft,
          child: TextButton.icon(
            onPressed: () {},
            label: const Text(
              'Alert Detail',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
        ),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 20,
            ),
            children: [
              TextSpan(text: 'Alert #${alert1.alertId} - '),
              // ignore: unnecessary_string_interpolations
              TextSpan(
                text: '${alert1.status.name}',
                style: TextStyle(color: getAlertStatusColor()),
              ),
            ],
          ),
        ),

        // DRAW MAP
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: MapDrawer.Map(
              alert1.locations.last.latitude,
              alert1.locations.last.longitude,
            ),
          ),
        ),

        // INCIDENT Timeline
        Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: CustomCard(
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // Title of Card
                  const Row(
                    children: [
                      Icon(
                        Icons.watch_later_outlined,
                        size: 26,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Incident Timeline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Timeline Shape
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 4, 10),
                        child: Column(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.red[900],
                              size: 15,
                            ),
                            Container(
                              width: 2,
                              height: alert1.incidentTimeline.length >= 2
                                  ? alert1.incidentTimeline.length * 12
                                  : 0,
                              color: Colors.grey,
                            ),
                            Icon(
                              Icons.circle,
                              color: Colors.grey,
                              size: alert1.status == alertStatus.RESOLVED
                                  ? 15
                                  : 0,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...alert1.incidentTimeline.map((e) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${e.time.hour}:${e.time.minute}:${e.time.second} ',
                                      ),
                                      const WidgetSpan(
                                        child: SizedBox(width: 10),
                                      ),
                                      TextSpan(
                                        text: incidentMap[e.descrip] ?? '',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            // HEART RATE
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 5, 10),
              child: CustomCard(
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        children: [
                          const Text(
                            'Heart Rate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${alert1.healthEvent?.heartRate.toInt()} BPM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${alert1.healthEvent?.heartStatus.name}',
                            style: TextStyle(
                              color: getHeartStatusColor(),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BODY TEMP
            Container(
              margin: const EdgeInsets.fromLTRB(10, 10, 5, 10),
              child: CustomCard(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thermostat_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      Column(
                        children: [
                          const Text(
                            'Body Temp:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${alert1.healthEvent?.bodyTemp} °C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${alert1.healthEvent?.tempStatus.name}',
                            style: TextStyle(
                              color: getHTempStatusColor(),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // VEHICLE DETAILS
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 5, 0),
              child: CustomCard(
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Details',
                        style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        margin: EdgeInsets.all(2),
                        width: 120,
                        height: 1,
                        color: Colors.black,
                      ),
                      Text('Model:', style: TextStyle(color: Colors.grey[800])),
                      Text(vehicle.model),
                      Text('Plate:', style: TextStyle(color: Colors.grey[800])),
                      Text(vehicle.plate),
                      Text('Color:', style: TextStyle(color: Colors.grey[800])),
                      Text(vehicle.color),
                    ],
                  ),
                ),
              ),
            ),
            // Incident Context
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 5, 0),
              child: CustomCard(
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incident Context',
                        style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        margin: EdgeInsets.all(2),
                        width: 120,
                        height: 1,
                        color: Colors.black,
                      ),
                      Text(
                        'Location:',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      Text(address ?? 'loading..'),
                      Text(
                        'Alert Type:',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      Text(alert1.type.name),
                      Text(
                        'Response Time:',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      Text(
                        alert1.status == alertStatus.RESOLVED
                            ? getResponseTime().toString()
                            : '',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  getResponseTime() {
    return alert1.solvedAt!.difference(alert1.generatedAt);
  }
}
*/
