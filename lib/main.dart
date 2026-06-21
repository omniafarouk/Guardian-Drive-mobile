import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

import 'package:guardian_drive_mobile/pages/alert_list_page.dart';
import 'package:guardian_drive_mobile/pages/dashboard.dart';
import 'package:guardian_drive_mobile/pages/login_page.dart';
import 'package:guardian_drive_mobile/pages/newpage.dart';
import 'package:guardian_drive_mobile/pages/profile_screen.dart';
import 'package:guardian_drive_mobile/pages/trip_details_page.dart';
import 'package:guardian_drive_mobile/pages/trip_list_page.dart';
import 'package:guardian_drive_mobile/pages/alert_detail_page.dart';
import 'package:guardian_drive_mobile/pages/reset_pass.dart';
import 'package:guardian_drive_mobile/services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks appLinks = AppLinks();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDeepLinks();
    });
  }

  Future<void> initDeepLinks() async {
    /// =========================
    /// HANDLE COLD START LINK
    /// =========================
    final uri = await appLinks.getInitialLink();
    if (uri != null) {
      await _handleUri(uri);
    }

    _sub = appLinks.uriLinkStream.listen((uri) async {
      if (uri != null) {
        await _handleUri(uri);
      }
    });
  }

  Future<void> _handleUri(Uri uri) async {
    if (uri.host != "reset-password") return;

    final token = uri.queryParameters['token'];

    final context = navigatorKey.currentContext;

    if (token == null || token.isEmpty) {
      _goToLogin();

      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid reset link")));
      }
      return;
    }

    final result = await AuthService.validateToken(token);

    final bool isValid = result['valid'] == true;

    if (isValid) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ResetPass(token: token)),
      );
    } else {
      _goToLogin();

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reset link expired. Please request a new one."),
          ),
        );
      }
    }
  }

  void _goToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Guardian Drive',
      initialRoute: '/login',
      routes: {
        '/home': (context) => Dashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/trips': (context) => const tripListPage(),
        '/alerts': (context) => const AlertListPage(),
        '/login': (context) => LoginPage(),
        '/alert-details': (context) => AlertDetail(),
        '/trip-details': (context) => TripDetailsPage(),
        '/ongoing-trip': (context) => OngoingTrip(),
      },
    );
  }
}
