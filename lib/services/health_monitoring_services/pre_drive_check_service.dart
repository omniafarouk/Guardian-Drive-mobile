import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/threshold_checker_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

// import 'package:guardian_drive_mobile/services/band_ble_service.dart';
import 'package:guardian_drive_mobile/services/band_ble_simulator_service.dart';

class PreDriveCheckService {
  final DriverHealthThresholds thresholds;
  final int requiredCleanReadings;

  static const int _maxAttempts = 3;
  static const Duration _attemptTimeout = Duration(minutes: 1);
  static const Duration _waitBetweenAttempts = Duration(seconds: 10);

  PreDriveCheckService({
    required this.thresholds,
    this.requiredCleanReadings = 3,
  });

  /// Returns true if passed, false if timed out
  Future<bool> run(Stream<VitalReadings> vitalsStream) async {
    final checker = ThresholdChecker(thresholds);
    final completer = Completer<bool>();
    int cleanStreak = 0;

    final sub = vitalsStream.listen((reading) {
      if (completer.isCompleted) return;

      traceLog("pre-drive checking ...", reading.toString());

      final breaches = checker.check(reading);
      final isBad = breaches.any(
        (b) =>
            b.severity == ConditionSeverity.CRITICAL ||
            b.severity == ConditionSeverity.MODERATE,
      );

      if (isBad) {
        cleanStreak = 0;
        traceLog(
          'PreDrive: bad reading, streak reset',
          breaches.map((b) => b.type.name).join(', '),
        );
      } else {
        cleanStreak++;
        traceLog(
          'PreDrive: clean reading',
          '$cleanStreak / $requiredCleanReadings',
        );

        if (cleanStreak >= requiredCleanReadings) {
          completer.complete(true);
        }
      }
    });

    final result = await completer.future.timeout(
      _attemptTimeout,
      onTimeout: () => false,
    );

    await sub.cancel();
    return result;
  }

  Future<bool> startPreDriveCheck(BuildContext context) async {
    final preDriveService = PreDriveCheckService(thresholds: thresholds);

    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      traceLog('PreDrive: attempt $attempt / $_maxAttempts', '');

      // ✅ Always use navigatorKey for showing dialogs in async context
      final showCtx = navigatorKey.currentContext;
      if (showCtx == null || !showCtx.mounted) return false;
      _showPredriveCheckDialog(showCtx, attempt);

      final passed = await preDriveService.run(
        BandBleService.instance.telemetryController.stream,
      );

      // ✅ Fresh context to close the checking dialog
      final closeCtx = navigatorKey.currentContext;
      if (closeCtx != null) {
        if (!showCtx.mounted) return false;
        Navigator.of(closeCtx, rootNavigator: true).pop();
      }

      if (passed) {
        traceLog('PreDrive: passed on attempt $attempt', '');
        return true;
      }

      traceLog('PreDrive: attempt $attempt timed out', '');

      if (attempt < _maxAttempts) {
        // ✅ Fresh context for waiting dialog
        final waitCtx = navigatorKey.currentContext;
        if (waitCtx != null) {
          if (!waitCtx.mounted) return false;
          await _showWaitingDialog(waitCtx, attempt);
        }

        await Future.delayed(_waitBetweenAttempts);
      }
    }

    traceLog('PreDrive: all $_maxAttempts attempts failed', '');
    return false;
  }

  void _showPredriveCheckDialog(BuildContext context, int attempt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 1, 21, 51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Pre-drive Check In Progress, Attempt $attempt',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait a few seconds…',
              style: TextStyle(color: Color(0xFF979797), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWaitingDialog(BuildContext context, int attempt) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text(
            'Check Incomplete',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        content: Text(
          'Attempt $attempt failed. Waiting ${_waitBetweenAttempts.inSeconds}s before attempt ${attempt + 1}...',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text(
              'OK',
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
}
