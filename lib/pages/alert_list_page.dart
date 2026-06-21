import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert_summary.dart';
import 'package:guardian_drive_mobile/services/alert_service.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/alert_list_item.dart';
import 'package:guardian_drive_mobile/widgets/filter_alert.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';
import 'package:number_paginator/number_paginator.dart';

class AlertListPage extends StatefulWidget {
  const AlertListPage({super.key});

  @override
  State<AlertListPage> createState() => _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
  alertType? selectedType;
  DateTimeRange? selectedRange;
  String selectedOrderBy = "desc";
  late LocationCoords location;
  late List<AlertSummary> alerts = [];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;

  void runSearch(String id) {
    print('searching for $id');
  }

  @override
  void initState() {
    super.initState();
    loadAlerts();
  }

  Future<void> loadAlerts({
    int page = 1,
    int limit = 15,
    String orderBy = "desc",
    alertType? type,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await AlertApiService.getAlerts(
        page: page,
        limit: limit,
        orderBy: orderBy,
        type: type,
        from: from,
        to: to,
      );
      print('Alerts loaded: ${response.alerts.length}'); // how many came back?
      setState(() {
        alerts = response.alerts;
        totalPages = response.totalPages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false; // ← also stop loading on error
      });
      print('loadAlerts error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF060B21),
      drawer: SideBarDrawer(),
      appBar: CustomAppBar(title: 'Alerts'),
      floatingActionButton: IconButton.filled(
        onPressed: () async {
          final result = await showFilterBottomSheet(
            context,
            initialRange: selectedRange,
            initialType: selectedType,
            initialSortOrder: selectedOrderBy,
          );

          if (result != null) {
            print(result["dateRange"]);
            print(result["city"]);
            print(result["type"]);
            final range = result["range"] as DateTimeRange?;
            final type = result["type"] as alertType?;
            final sort = result["sort"] as String;
            selectedRange = range;
            selectedType = type;
            selectedOrderBy = sort;
            loadAlerts(
              page: 1,
              orderBy: selectedOrderBy,
              from: selectedRange?.start,
              to: selectedRange?.end,
              type: selectedType,
            );
            setState(() {
              currentPage = 1;
            });
          }
        },
        icon: Icon(Icons.tune, color: Colors.white, size: 35),
        style: IconButton.styleFrom(backgroundColor: Color(0xFF251C4E)),
      ),
      body: GradientBackground(
        child: Container(
          margin: EdgeInsets.fromLTRB(15, 25, 15, 15),
          child: Column(
            children: <Widget>[
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : alerts.isEmpty
                    ? Center(
                        child: Text(
                          "No alerts detected!",
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          return AlertListItem(alert: alerts[index]);
                        },
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 27),
                      ),
              ),
              NumberPaginator(
                key: ValueKey(currentPage),
                numberPages: totalPages == 0 ? 1 : totalPages,
                initialPage: totalPages == 0 ? 0 : currentPage - 1,
                onPageChange: (int index) {
                  setState(() {
                    currentPage = index + 1;
                    print("current page: $currentPage");
                  });
                  print("user selected page $index");
                  loadAlerts(
                    page: index + 1,
                    orderBy: selectedOrderBy,
                    from: selectedRange?.start,
                    to: selectedRange?.end,
                    type: selectedType,
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
