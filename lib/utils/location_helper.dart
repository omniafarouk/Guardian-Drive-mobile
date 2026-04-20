import 'package:geocoding/geocoding.dart';

Future<String> getLocationName(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return "${place.locality}, ${place.country}";
    }

    return "Unknown location";
  } catch (e) {
    return "Unknown location";
  }
}
