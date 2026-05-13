import 'package:geocoding/geocoding.dart';

Future<String> getLocationName(double lat, double lng) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isEmpty) {
      return "Unknown";
    }

    final place = placemarks.first;

    final city = place.locality;
    final area = place.subAdministrativeArea;
    final country = place.country;

    // City, Country
    if ((city ?? "").isNotEmpty && (country ?? "").isNotEmpty) {
      return "$city, $country";
    }

    // Area, Country
    if ((area ?? "").isNotEmpty && (country ?? "").isNotEmpty) {
      return "$area, $country";
    }

    // Country only
    if ((country ?? "").isNotEmpty) {
      return country!;
    }
    return "Unknown location";
  } catch (e) {
    return "Unknown location";
  }
}
