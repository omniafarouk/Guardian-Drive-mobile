enum incidentDescription {
  Alert_trigger,
  Service_request,
  Ambulance_arrival,
  Alert_solved
}

Map<incidentDescription, String> incidentMap = {
  incidentDescription.Alert_trigger: 'Alert Triggered',
  incidentDescription.Service_request: 'Emergency service request',
  incidentDescription.Ambulance_arrival: 'Ambulance Arrival on Scene',
  incidentDescription.Alert_solved: 'Alert completely solved'
};

class Incident {
  Incident({
    required this.time,
    required this.descrip,
  });

  DateTime time;
  incidentDescription descrip;
}
