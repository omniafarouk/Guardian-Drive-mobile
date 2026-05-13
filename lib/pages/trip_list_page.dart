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
import 'package:guardian_drive_mobile/services/trip_service.dart';

class tripListPage extends StatefulWidget {
  const tripListPage({super.key});

  @override
  State<tripListPage> createState() => _tripListPageState();
}

class _tripListPageState extends State<tripListPage> {
  int totalPages = 1;
  int currentPage = 1;
  String? selectedStatus;
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  String selectedOrderBy = "desc";
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  void getData({
    int page = 1,
    int limit = 10,
    String? status,
    DateTime? fromStartDate,
    DateTime? toStartDate,
    String orderBy = "asc",
  }) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await TripService().getTrips(
        page: page,
        limit: limit,
        status: status,
        fromStartDate: fromStartDate,
        toStartDate: toStartDate,
        orderBy: orderBy,
      );

      setState(() {
        trips = response.trips;
        totalPages = response.totalPages;
        currentPage = response.page;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  late Car myCar;
  List<Trip> trips = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF060B21),
      appBar: CustomAppBar(title: 'Trips'),
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          final result = await showFilterBottomSheet(context);

          if (result != null) {
            final range = result["range"] as DateTimeRange?;
            final status = result["status"] as TripStatus?;
            final sort = result["sort"] as String;

            //selectedStatus = statuses.isNotEmpty ? statuses.first.name : null;
            selectedStatus=status?.name;
            selectedFromDate = range?.start;
            selectedToDate = range?.end;
            selectedOrderBy = sort;

            getData(
              page: 1,
              orderBy: selectedOrderBy,
              fromStartDate: selectedFromDate,
              toStartDate: selectedToDate,
              status: selectedStatus,
            );
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: trips.length,
                        itemBuilder: (context, index) {
                          return TripListItem(trip: trips[index]);
                        },
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 27),
                      ),
              ),
              NumberPaginator(
                numberPages: totalPages == 0 ? 1 : totalPages,
                initialPage: totalPages == 0 ? 0 : currentPage - 1,
                onPageChange: (int index) {
                  getData(
                    page: index + 1,
                    status: selectedStatus,
                    fromStartDate: selectedFromDate,
                    toStartDate: selectedToDate,
                    orderBy: selectedOrderBy,
                  );
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
