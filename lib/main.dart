import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';

import 'package:guardian_drive_mobile/pages/alert_list_page.dart';
import 'package:guardian_drive_mobile/pages/dashboard.dart';
import 'package:guardian_drive_mobile/pages/login_page.dart';
import 'package:guardian_drive_mobile/pages/ongoing_trip_page.dart';
import 'package:guardian_drive_mobile/pages/profile_screen.dart';
import 'package:guardian_drive_mobile/pages/trip_details_page.dart';
import 'package:guardian_drive_mobile/pages/trip_list_page.dart';
import 'package:guardian_drive_mobile/pages/alert_detail_page.dart';
import 'package:guardian_drive_mobile/pages/reset_pass.dart';
import 'package:guardian_drive_mobile/services/auth_service.dart';
import 'package:guardian_drive_mobile/services/car_ble_service.dart';
import 'package:guardian_drive_mobile/utils/app_messanger.dart';
import 'dart:io';
// import 'package:guardian_drive_mobile/services/band_ble_service.dart';
import 'package:guardian_drive_mobile/services/band_ble_simulator_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  BandBleService.instance.messagesController.stream.listen((message) {
    print("BAND GLOBAL LISTENER GOT: $message");
    AppMessenger.showBandMessage(message);
  });
  CarBleService.instance.messagesController.stream.listen((message) {
    print("CAR GLOBAL LISTENER GOT: $message");
    AppMessenger.showBandMessage(message);
  });
  await SystemChrome.setPreferredOrientations([
    // Locks Application in portrait mode
    DeviceOrientation.portraitUp,
  ]);
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
  bool _bandAdjustDialogVisible = false;
  bool _crashDialogVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDeepLinks();
      BandBleService.instance.needsBandAdjustment.addListener(() {
        final needs = BandBleService.instance.needsBandAdjustment.value;
        final context = navigatorKey.currentContext;
        if (context == null) return;

        if (needs && !_bandAdjustDialogVisible) {
          _bandAdjustDialogVisible = true;
          showDialog(
            context: context,
            barrierDismissible:
                false, // tapping outside the dialog does nothing
            builder: (_) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Adjust Your Band'),
                ],
              ),
              content: Text(
                'Your band is not properly worn. Please adjust it to continue accurate health monitoring.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Got it'),
                ),
              ],
            ),
          ).then((_) => _bandAdjustDialogVisible = false);
        } else if (!needs && _bandAdjustDialogVisible) {
          _bandAdjustDialogVisible = false;
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
      CarBleService.instance.carCrashDetected.addListener(() {
        final crashed = CarBleService.instance.carCrashDetected.value;
        final context = navigatorKey.currentContext;
        if (context == null) return;

        if (crashed && !_crashDialogVisible) {
          _crashDialogVisible = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.car_crash, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Crash Detected'),
                ],
              ),
              content: Text(
                'A possible collision has been detected.'
                // 'If you do not respond, your fleet manager will be alerted '
                // 'with your current location and vitals.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('I\'m OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Trigger SOS'),
                ),
              ],
            ),
          ).then((_) => _crashDialogVisible = false);
        } else if (!crashed && _crashDialogVisible) {
          _crashDialogVisible = false;
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    });
  }

  Future<void> initDeepLinks() async {
    /// =========================mai
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
    BandBleService.instance.needsBandAdjustment.removeListener(() {});
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
