import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';
import 'package:guardian_drive_mobile/models/alert_request.dart';
import 'package:guardian_drive_mobile/models/alert_summary.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/alert_service.dart';
import 'package:guardian_drive_mobile/services/car_ble_service.dart';
import 'package:guardian_drive_mobile/services/location_service.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/alert_sound_activiator.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/first_aid_guidance_popup.dart';

void showHealthAlertDialog(String conditionName, VitalReadings reading) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _HealthAlertDialog(conditionName: conditionName, reading: reading),
  ).then((stopTrip) async {
    if (stopTrip == true) {
      final rootContext = navigatorKey.currentContext;
      if (rootContext == null) return;
      bool loadingShowing = true;
      void closeLoading() {
        if (loadingShowing) {
          final ctx = navigatorKey.currentContext; // ✅ fresh context for pop
          if (ctx != null) {
            Navigator.of(ctx, rootNavigator: true).pop();
            loadingShowing = false;
          }
        }
      }

      try {
        if (!rootContext.mounted) return;
        showDialog(
          context: rootContext, // ✅ rootContext not stale context
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Sending Health Abnormal Alert..."),
              ],
            ),
          ),
        ).then((_) => loadingShowing = false);

        if (!rootContext.mounted) return;
        final bool? success = await triggerHealthAbnormalAlert(
          rootContext,
          reading,
        );

        closeLoading(); // ✅ close before showing next dialog

        if (success == null || success == false) {
          throw Exception("Couldn't trigger Health Abnormal Alert");
        }

        await CarBleService.instance.sendSevereCaseOccurred();
        traceLog("Informed car to auto disable itself");
        // End trips Calls Create Health Readings which need the trip to be completed/canceled first
        // therefore must update trip status first
        await TripService().endTripTracking();

        final freshContext = navigatorKey.currentContext;
        if (freshContext == null || !freshContext.mounted) return;
        showAlertSuccessfulPopUp(freshContext, reading);
      } catch (e) {
        traceLog("error in sending Health Abnormal Alert : ", e);
        final freshContext =
            navigatorKey.currentContext; // ✅ fresh context for error dialog too
        if (freshContext != null && freshContext.mounted) {
          showDialog(
            context: freshContext,
            useRootNavigator: true,
            builder: (ctx) => AlertDialog(
              title: const Text("Failed to send Health Abnormal Alert"),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } finally {
        closeLoading();
      }
    }
  });
}

class _HealthAlertDialog extends StatefulWidget {
  final String conditionName;
  final VitalReadings reading;
  const _HealthAlertDialog({
    required this.conditionName,
    required this.reading,
  });

  @override
  State<_HealthAlertDialog> createState() => _HealthAlertDialogState();
}

class _HealthAlertDialogState extends State<_HealthAlertDialog> {
  late Timer _soundTimer;
  late Timer _countdownTimer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _soundTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _playAlertSound();
    });
    _playAlertSound();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft < 1) {
        _dismiss(stopTrip: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _playAlertSound() {
    AlertSoundActiviator.instance.playEmergencyAlert();
  }

  void _dismiss({required bool stopTrip}) async {
    _soundTimer.cancel();
    _countdownTimer.cancel();
    AlertSoundActiviator.instance.stop();
    if (mounted) Navigator.pop(context, stopTrip);
  }

  @override
  void dispose() {
    _soundTimer.cancel();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1B2A), // ✅ matched dark theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text(
          '⚠️ Health Alert',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.conditionName} detected.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              'Trip will stop in $_secondsLeft seconds...',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _dismiss(stopTrip: false),
          child: const Text(
            'Continue',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          onPressed: () => _dismiss(stopTrip: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Stop Trip',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

void showAlertSuccessfulPopUp(BuildContext context, VitalReadings reading) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF0D1B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text(
          'Alert Triggered',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      content: const Text(
        'Emergency services have been notified.',
        style: TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () async {
            Navigator.pop(dialogContext);
            // ✅ Use navigatorKey — dialogContext is dead after pop
            final rootContext = navigatorKey.currentContext;
            if (rootContext == null) return;
            await showFirstAidGuidanceDialog(reading, rootContext);
          },
          child: const Text(
            'First Aid Guidance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool?> triggerHealthAbnormalAlert(
  BuildContext context,
  VitalReadings? latestReading,
) async {
  if (TripService().activeTripId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('There is No Trip Active Now'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  if (latestReading == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('There is no active vital readings yet'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  int triggeredLocationId = await LocationService().getCurrentLocationId();

  AlertRequest alertRequest = AlertRequest(
    type: alertType.HEALTH_ABNORMAL,
    tripId: TripService().activeTripId!,
    triggeredLocationId: triggeredLocationId,
    heartRate: latestReading.heartRate,
    spo2: latestReading.spo2,
    temp: latestReading.temp,
  );
  traceLog(
    'in trigger Health Abnormal Alert, sending Health Abnormal Alert Alert request ',
    alertRequest.toString(),
  );

  final success = await AlertApiService.createHealthAbnormalAlert(alertRequest);
  return success;
}
