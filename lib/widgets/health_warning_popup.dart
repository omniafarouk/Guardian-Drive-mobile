import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/utils/alert_sound_activiator.dart';
import 'package:guardian_drive_mobile/widgets/first_aid_guidance_popup.dart';

void showHealthWarningDialog(String conditionName, VitalReadings reading) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) =>
        _HealthWarningDialog(conditionName: conditionName, reading: reading),
  );
}

class _HealthWarningDialog extends StatefulWidget {
  final String conditionName;
  final VitalReadings reading;
  const _HealthWarningDialog({
    required this.conditionName,
    required this.reading,
  });

  @override
  State<_HealthWarningDialog> createState() => _HealthWarningDialogState();
}

class _HealthWarningDialogState extends State<_HealthWarningDialog> {
  late Timer _soundTimer;

  @override
  void initState() {
    super.initState();
    // 1. Start repeating sound immediately every 2 seconds
    _soundTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _playAlertSound();
    });
    _playAlertSound();
  }

  void _playAlertSound() {
    AlertSoundActiviator.instance.playEmergencyAlert();
  }

  @override
  void dispose() {
    _soundTimer.cancel(); // Cleans up the background loop immediately
    AlertSoundActiviator.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text(
          '⚠️ Health Warning',
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: Text(
        'Health alert: ${widget.conditionName}',
        style: const TextStyle(color: Colors.white70, fontSize: 14),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 157, 207, 99),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: Color.fromARGB(255, 92, 92, 92),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final rootContext = navigatorKey.currentContext;
            if (rootContext == null) return;

            await showFirstAidGuidanceDialog(widget.reading, rootContext);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
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
    );
  }
}
