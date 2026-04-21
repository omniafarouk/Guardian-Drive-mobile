import 'package:guardian_drive_mobile/models/incident.dart';

import '../models/alert.dart';

List<Incident> buildIncidentTimeline(Alert alert) {
  List<Incident> timeline = [];
  timeline.add(Incident(
      time: alert.generatedAt, descrip: incidentDescription.Alert_trigger));

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
