import 'package:guardian_drive_mobile/models/alert_details.dart';
import 'package:guardian_drive_mobile/models/incident.dart';

List<Incident> buildIncidentTimeline(AlertDetails alert) {
  List<Incident> timeline = [];
  timeline.add(Incident(
      time: alert.alertSummary.generatedAt, descrip: incidentDescription.Alert_trigger));

  if (alert.requestTime != null) {
    timeline.add(Incident(
        time: alert.requestTime!,
        descrip: incidentDescription.Service_request));
  }

  if (alert.completionTime != null) {
    timeline.add(Incident(
        time: alert.completionTime!,
        descrip: incidentDescription.Ambulance_arrival));
  }

  if (alert.solvedAt != null) {
    timeline.add(Incident(
        time: alert.solvedAt!, descrip: incidentDescription.Alert_solved));
  }

  return timeline;
}
