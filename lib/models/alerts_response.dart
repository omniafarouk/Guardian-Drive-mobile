import 'package:guardian_drive_mobile/models/alert_summary.dart';

class AlertsResponse {
  List<AlertSummary> alerts;
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
      alerts: (json['alerts']  as List).map((e) => AlertSummary.fromJson(e)).toList(),
      page: json['page'],
      totalPages: json['totalPages'],
      total: json['total'],
      limit: json['limit'],
    );
  }
}
