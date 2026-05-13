import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/pages/alert_list_page.dart';
import 'package:guardian_drive_mobile/pages/dashboard.dart';
import 'package:guardian_drive_mobile/pages/login_page.dart';
import 'package:guardian_drive_mobile/pages/profile_screen.dart';
import 'package:guardian_drive_mobile/pages/trip_details_page.dart';
import 'package:guardian_drive_mobile/pages/trip_list_page.dart';
import 'package:guardian_drive_mobile/pages/alert_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guardian Drive',
      initialRoute: '/trips', // the first screen that opens
      // can be initialRoute or home: const HomeScreen(), or as '/' in routes
      routes: {
        '/home': (context) => Dashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/trips': (context) => const tripListPage(),
        '/alerts': (context) => const AlertListPage(),
        //'/settings': (context) => const SettingsScreen(),
        '/login': (context) => LoginPage(),
        '/alert-details': (context) => AlertDetail(),
        '/trip-details': (context) => TripDetailsPage(),
      },
    );
  }
}
