import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';
import 'package:guardian_drive_mobile/widgets/trip_list_item.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/models/car.dart';
import 'package:guardian_drive_mobile/widgets/filter_trip.dart';
import 'package:guardian_drive_mobile/utils/location_helper.dart';
import '../models/location.dart';
import 'package:number_paginator/number_paginator.dart';

class tripListPage extends StatefulWidget {
  const tripListPage({super.key});

  @override
  State<tripListPage> createState() => _tripListPageState();
}

class _tripListPageState extends State<tripListPage> {
  void runSearch(String id) {
    print('searching for $id');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myCar = Car(
      engineId: '123A',
      plateNo: '123 ABB',
      status: carStatus.ACTIVE,
      color: 'Red',
    );
    var location = Location(latitude: 30.06263, longitude: 31.24967);

    trips = [
      Trip(
        tripId: 1,
        startLatitude: 30.06263,
        startLongitude: 31.24967,
        destLatitude: 31.205753,
        destLongitude: 29.924526,
        startTime: DateTime.now(),
        status: tripStatus.PLANNED,
        car: myCar,
      ),
      Trip(
        tripId: 2,
        startLatitude: 30.06263,
        startLongitude: 31.24967,
        destLatitude: 31.205753,
        destLongitude: 29.924526,
        startTime: DateTime.now(),
        status: tripStatus.PLANNED,
        car: myCar,
      ),
      Trip(
        tripId: 3,
        startLatitude: 30.06263,
        startLongitude: 31.24967,
        destLatitude: 31.205753,
        destLongitude: 29.924526,
        startTime: DateTime.now(),
        status: tripStatus.ONGOING,
        car: myCar,
      ),
      Trip(
        tripId: 4,
        startLatitude: 30.06263,
        startLongitude: 31.24967,
        destLatitude: 31.205753,
        destLongitude: 29.924526,
        startTime: DateTime.now(),
        status: tripStatus.CANCELLED,
        car: myCar,
      ),
      Trip(
        tripId: 5,
        startLatitude: 30.06263,
        startLongitude: 31.24967,
        destLatitude: 31.205753,
        destLongitude: 29.924526,
        startTime: DateTime.now(),
        status: tripStatus.COMPLETED,
        car: myCar,
      ),
    ];
  }

  late Car myCar;
  late List<Trip> trips;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF060B21),
      appBar: CustomAppBar(title: 'Trips'),
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          final result = await showFilterBottomSheet(context);

          if (result != null) {
            print(result["dateRange"]);
            print(result["city"]);
            print(result["type"]);

            // later:
            // call backend with these filters
            //         {
            //       range: DateTimeRange,
            //   city: String,
            //   type: alertType,
            //   sort: "asc" | "desc"
            // }
          }
        },
        icon: Icon(Icons.tune, color: Colors.white, size: 35),
        style: IconButton.styleFrom(backgroundColor: Color(0xFF251C4E)),
      ),
      drawer: const SideBarDrawer(),
      body: GradientBackground(
        child: Container(
          margin: EdgeInsets.fromLTRB(15, 25, 15, 15),
          child: Column(
            children: <Widget>[
              // SizedBox(height: 5),
              Expanded(
                child: ListView.separated(
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return TripListItem(trip: trips[0]);
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 27),
                ),
              ),
              NumberPaginator(
                numberPages: 10,
                onPageChange: (int index) {
                  // handle page change...
                },
                child: const SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      PrevButton(),
                      Expanded(child: NumberContent()),
                      NextButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
