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
      title: const Text('Health Alert'),
      content: Text('Health alert: ${widget.conditionName}'),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 157, 207, 99),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'OK',
            style: TextStyle(color: Color.fromARGB(255, 92, 92, 92)),
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
          ),
          child: const Text(
            'First Aid Guidance',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
