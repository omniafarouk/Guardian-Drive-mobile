import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/data/vehicle_details.dart';
import 'package:guardian_drive_mobile/mappers/incident_mapper.dart';
import 'package:guardian_drive_mobile/models/health_event.dart';
import 'package:guardian_drive_mobile/services/alert_api_service.dart';
import 'package:guardian_drive_mobile/utils/location_helper.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';

import '../models/alert.dart';
import '../models/incident.dart';
import '../widgets/alert_card.dart';
import '../widgets/map.dart' as MapDrawer;

class AlertDetail extends StatefulWidget {
  final int alertId = 1;
  const AlertDetail({super.key});

  @override
  State<AlertDetail> createState() => _AlertDetailState();
}

class _AlertDetailState extends State<AlertDetail> {
  Future<Alert>? alertFuture; // late Future<Alert> alertFuture;
  String? address;
  List<Incident>? incidentTimeline;

  Color getAlertStatusColor(Alert alert) {
    switch (alert.status) {
      case alertStatus.RESOLVED:
        return Colors.teal;
      default:
        return Colors.red;
    }
  }

  Color getHeartStatusColor(Alert alert) {
    switch (alert.healthEvent?.heartStatus) {
      case HeartStatus.Critical:
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  Color getHTempStatusColor(Alert alert) {
    switch (alert.healthEvent?.tempStatus) {
      case BodyTempStatus.Critical:
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  Future<void> loadAddress(Alert alert) async {
    address = await getLocationName(
      alert.triggeredLocation.latitude,
      alert.triggeredLocation.longitude,
    );
  }

  @override
  void initState() {
    super.initState();
    // API ALERT request

    // alertFuture = AlertApiService.getAlertById(widget.alertId) as Future<Alert>?;
  }

  getResponseTime(Alert alert) {
    return alert.solvedAt!.difference(alert.generatedAt);
  }

  @override
  Widget build(BuildContext context) {
    final int alertId = ModalRoute.of(context)!.settings.arguments as int;
    alertFuture = AlertApiService.getAlertById(alertId, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsInJvbGUiOiJEUklWRVIiLCJpYXQiOjE3Nzg1NDU0NTcsImV4cCI6MTc3ODYzMTg1N30.z0OSCo5tW0zDBoh8DU7QiNe-_SaLONFbTIX1-Zr12X4") as Future<Alert>?;
    return FutureBuilder(
      future: alertFuture,
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());

        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        // ADD NULL CASE
        final alert = snapshot.data!;
        loadAddress(alert);
        incidentTimeline = buildIncidentTimeline(alert);
        return Scaffold(
          body:
          GradientBackground(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    children: [
                      // SPACING at the start of page
                      const SizedBox(height: 45),
                      // ALert Detail Button
                      Container(
                        alignment: Alignment.topLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/alerts');
                          },
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
                            TextSpan(text: 'Alert #${alert.alertId} - '),
                            // ignore: unnecessary_string_interpolations
                            TextSpan(
                              text: (alert.status == alertStatus.ACTIVE)
                                  ? 'Active'
                                  : 'Resolved',
                              style: TextStyle(color: getAlertStatusColor(alert)),
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
                            alert.stoppedLocation!.latitude,
                            alert.stoppedLocation!.longitude,
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
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        10,
                                        4,
                                        10,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            color: Colors.red[900],
                                            size: 15,
                                          ),
                                          Container(
                                            width: 2,
                                            height: incidentTimeline!.length >= 2
                                                ? incidentTimeline!.length * 12
                                                : 0,
                                            color: Colors.grey,
                                          ),
                                          Icon(
                                            Icons.circle,
                                            color: Colors.grey,
                                            size: alert.status == alertStatus.RESOLVED
                                                ? 15
                                                : 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...incidentTimeline!.map((e) {
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                      text:
                                                          incidentMap[e.descrip] ??
                                                          '',
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
                          Expanded(
                            child: Container(
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
                                      Expanded(
                                        child: Column(
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
                                              '${alert.healthEvent?.heartRate.toInt()} BPM',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 18,
                                              ),
                                            ),
                                            Text(
                                              '${alert.healthEvent?.heartStatus.name}',
                                              style: TextStyle(
                                                color: getHeartStatusColor(alert),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
                                          '${alert.healthEvent?.bodyTemp} °C',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          '${alert.healthEvent?.tempStatus.name}',
                                          style: TextStyle(
                                            color: getHTempStatusColor(alert),
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
                          Expanded(
                            child: Container(
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
                                      Text(
                                        'Model:',
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                      Text(vehicle.model),
                                      Text(
                                        'Plate:',
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                      Text(vehicle.plate),
                                      Text(
                                        'Color:',
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                      Text(vehicle.color),
                                    ],
                                  ),
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
                                    Text(alert.type.name),
                                    Text(
                                      'Response Time:',
                                      style: TextStyle(color: Colors.grey[800]),
                                    ),
                                    Text(
                                      alert.status == alertStatus.RESOLVED
                                          ? getResponseTime(alert).toString()
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
                  ),
                ),
              ),
            ),

        );
      },
    );
  }
}
