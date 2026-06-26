import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

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

Future<Position> getCurrentPosition() async {
  // Check if location services are enabled
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled');
  }

  // Check and request permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permission permanently denied');
  }

  return await Geolocator.getCurrentPosition(
    locationSettings: _platformLocationSettings(),
  );
}

LocationSettings _platformLocationSettings() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      // minimum distance in meters before a new location update is sent
      // 0 = every update, good for active trip tracking
      distanceFilter: 0,
      // keeps GPS alive when app is backgrounded
      // driver might switch to WhatsApp or a call mid-trip
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: 'Guardian Drive',
        notificationText: 'Tracking your trip in the background',
        enableWakeLock: true, // prevents CPU from sleeping during trip
      ),
    );
  }
  // Could handle for IOS later <---------
  // fallback
  return LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
}
