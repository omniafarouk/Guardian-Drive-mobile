import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:intl/intl.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/models/car.dart';
import '../widgets/map.dart' as MapDrawer;
import 'package:guardian_drive_mobile/utils/location_helper.dart';

String formatTripDate(DateTime date) {
  return DateFormat("MMM d 'at' h:mm").format(date);
}

Color getStatusColor(tripStatus status) {
  switch (status) {
    case tripStatus.PLANNED:
      return Colors.orange;
    case tripStatus.ONGOING:
      return Colors.green;
    case tripStatus.CANCELLED:
      return Colors.red;
    case tripStatus.COMPLETED:
      return Colors.blue;
  }
}

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  @override
  void initState() {
    super.initState();
    myCar = Car(
      engineId: '123A',
      plateNo: '123 ABS',
      status: carStatus.ACTIVE,
      color: 'Red',
    );
    trip = Trip(
      tripId: 1,
      startLatitude: 30.06263,
      startLongitude: 31.24967,
      destLatitude: 31.205753,
      destLongitude: 29.924526,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      status: tripStatus.COMPLETED,
      car: myCar, 
      plannedStartTime: DateTime.now(),
    );
  }

  late Trip trip;
  late Car myCar;
  @override
  Widget build(BuildContext context) {
    bool canStartTrip =
        trip.status == tripStatus.PLANNED &&
        DateTime.now().isAfter(trip.startTime);
    //final int tripId = ModalRoute.of(context)!.settings.arguments as int;
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
      // drawer: const SideBarDrawer(),
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
                        'Trip #${trip.tripId} - ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        trip.status.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: getStatusColor(trip.status),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        40.0,
                      ),
                      child: MapDrawer.Map(
                        trip.startLatitude,
                        trip.startLongitude,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(), // icon column (tight)
                      1: FixedColumnWidth(20),
                      2: IntrinsicColumnWidth(), // text column (tight)
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildRow(
                        Icons.watch_later_outlined,
                        Colors.white,
                        formatTripDate(trip.startTime),
                      ),
                      _buildRowFuture(
                        Icons.radio_button_on_sharp,
                        Colors.lightBlueAccent,
                        getLocationName(trip.startLatitude, trip.startLongitude),
                      ),

                      _buildRowFuture(
                        Icons.radio_button_on_sharp,
                        Colors.greenAccent,
                        getLocationName(trip.destLatitude, trip.destLongitude),
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
                      if (trip.endTime != null)
                        _buildRow(
                          Icons.check_circle_outlined,
                          Colors.white,
                          formatTripDate(trip.endTime!),
                        ),
                    ],
                  ),
                  SizedBox(height: 15),

                  _VehicleCard(trip: trip),
                  SizedBox(height: 15),

                  canStartTrip
                      ? ElevatedButton(
                          onPressed: () {
                            print('start trip');
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.trip});

  final Trip trip;

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
                    trip.car.plateNo,
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
                    trip.car.color,
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
TableRow _buildRowFuture(
    IconData icon,
    Color iconColor,
    Future<String> futureData,
    ) {
  return TableRow(
    children: <Widget>[
      Icon(icon, size: 23, color: iconColor),
      SizedBox(width: 20),

      FutureBuilder<String>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              "Loading...",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            );
          }

          return Text(
            snapshot.data ?? "Unknown",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          );
        },
      ),
    ],
  );
}