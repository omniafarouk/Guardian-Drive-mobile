import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';
import 'package:guardian_drive_mobile/widgets/trip_list_item.dart';
import 'package:guardian_drive_mobile/models/trip.dart';
import 'package:guardian_drive_mobile/models/car.dart';
import 'package:guardian_drive_mobile/widgets/filter_trip.dart';

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
    trips = [
      Trip(
        tripId: 1,
        startPoint: 'Alex',
        destPoint: 'cairo',
        startTime: DateTime.now(),
        status: tripStatus.PLANNED,
        car: myCar,
      ),
      Trip(
        tripId: 2,
        startPoint: 'cairo',
        destPoint: 'cairo',
        startTime: DateTime.now(),
        status: tripStatus.PLANNED,
        car: myCar,
      ),
      Trip(
        tripId: 3,
        startPoint: 'Alex',
        destPoint: 'cairo',
        startTime: DateTime.now(),
        status: tripStatus.ONGOING,
        car: myCar,
      ),
      Trip(
        tripId: 4,
        startPoint: 'Alex',
        destPoint: 'cairo',
        startTime: DateTime.now(),
        status: tripStatus.CANCELLED,
        car: myCar,
      ),
      Trip(
        tripId: 5,
        startPoint: 'Alex',
        destPoint: 'cairo',
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
        style: IconButton.styleFrom(backgroundColor: Color(0xFF2935E0)),
      ),
      drawer: const SideBarDrawer(),
      body: GradientBackground(
        child: Container(
          margin: EdgeInsets.fromLTRB(15, 25, 15, 15),
          child: Column(
            children: <Widget>[
              // SearchBar(
              //   backgroundColor: WidgetStateProperty.all(const Color(0x12FFFFFF)),
              //   leading: Icon(Icons.search, color: Colors.grey, size: 30),
              //   hintText: 'Search by ID ...',
              //   trailing: [FilterMenu()],
              //   onSubmitted: (value) => runSearch(value),
              //   textStyle: WidgetStateProperty.all(
              //     const TextStyle(color: Colors.white),
              //   ),
              // ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return TripListItem(trip: trips[0]);
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 27),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
