enum incidentDescription {
  Alert_trigger,
  Parking_request,
  No_response,
  Vehicle_control,
  Service_request,
  Ambulance_Arrival
}
Map<incidentDescription, String> incidentMap = {
  incidentDescription.Alert_trigger: 'Alert Triggered',
  incidentDescription.Parking_request: 'Driver parking request',
  incidentDescription.No_response: 'No Driver response',
  incidentDescription.Vehicle_control: 'Initiate vehicle control',
  incidentDescription.Service_request: 'Emergency service request',
  incidentDescription.Ambulance_Arrival: 'Ambulance Arrival on Scene'
};

class Incident {
  Incident({
    required this.time,
    required this.descrip,
  });

  DateTime time;
  incidentDescription descrip;
}
