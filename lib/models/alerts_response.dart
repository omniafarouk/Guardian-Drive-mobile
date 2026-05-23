import 'package:guardian_drive_mobile/models/alert.dart';

class AlertsResponse {
  List<Alert> alerts;
  int page;
  int totalPages;
  int total;
  int limit;
  AlertsResponse({
    required this.alerts,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.limit,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    return AlertsResponse(
      alerts: (json['alerts']  as List).map((e) => Alert.fromJson(e)).toList(),
      page: json['page'],
      totalPages: json['totalPages'],
      total: json['total'],
      limit: json['limit'],
    );
  }
}
