import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/models/location.dart';
import 'package:guardian_drive_mobile/widgets/alert_list_item.dart';
import 'package:guardian_drive_mobile/widgets/filter_alert.dart';
import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';

class AlertListPage extends StatefulWidget {
  const AlertListPage({super.key});

  @override
  State<AlertListPage> createState() => _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
  void runSearch(String id) {
    print('searching for $id');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    location = Location(latitude: 30.06263, longitude: 31.24967);
    alerts = [
      Alert(
        alertId: 2,
        tripId: 1,
        status: alertStatus.ACTIVE,
        generatedAt: DateTime.now(),
        locations: [location],
        solvedAt: DateTime.now(),
        type: alertType.HEALTH_ABNORMAL,

        healthEvent: null,
        requestTime: null,
        completionTime: null,
      ),
      Alert(
        alertId: 2,
        tripId: 1,
        status: alertStatus.ACTIVE,
        generatedAt: DateTime.now(),
        locations: [location],
        solvedAt: DateTime.now(),
        type: alertType.HEALTH_ABNORMAL,

        healthEvent: null,
        requestTime: null,
        completionTime: null,
      ),
      Alert(
        alertId: 2,
        tripId: 1,
        status: alertStatus.ACTIVE,
        generatedAt: DateTime.now(),
        locations: [location],
        solvedAt: DateTime.now(),
        type: alertType.HEALTH_ABNORMAL,

        healthEvent: null,
        requestTime: null,
        completionTime: null,
      ),
      Alert(
        alertId: 2,
        tripId: 1,
        status: alertStatus.ACTIVE,
        generatedAt: DateTime.now(),
        locations: [location],
        solvedAt: DateTime.now(),
        type: alertType.HEALTH_ABNORMAL,

        healthEvent: null,
        requestTime: null,
        completionTime: null,
      ),
      Alert(
        alertId: 2,
        tripId: 1,
        status: alertStatus.ACTIVE,
        generatedAt: DateTime.now(),
        locations: [location],
        solvedAt: DateTime.now(),
        type: alertType.HEALTH_ABNORMAL,

        healthEvent: null,
        requestTime: null,
        completionTime: null,
      ),
      Alert(
        alertId: 2,
        tripId: 1,
        status: alertStatus.ACTIVE,
        generatedAt: DateTime.now(),
        locations: [location],
        solvedAt: DateTime.now(),
        type: alertType.HEALTH_ABNORMAL,

        healthEvent: null,
        requestTime: null,
        completionTime: null,
      ),
      Alert(
        alertId: 2,
        tripId: 1,
        status: alertStatus.ACTIVE,
        generatedAt: DateTime.now(),
        locations: [location],
        solvedAt: DateTime.now(),
        type: alertType.HEALTH_ABNORMAL,

        healthEvent: null,
        requestTime: null,
        completionTime: null,
      ),
    ];
  }

  late Location location;
  late List<Alert> alerts;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF060B21),
      drawer: SideBarDrawer(),
      appBar: CustomAppBar(title: 'Alerts'),
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
                  itemCount: 11,
                  itemBuilder: (context, index) {
                    return AlertListItem(alert: alerts[0]);
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

  // void _showButtomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Container(
  //           child: Column(mainAxisSize:MainAxisSize.min,children: [Text('nnnn')]));
  //     },
  //   );
  // }
}
