import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/alert_sound_activiator.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

void showHealthWarningDialog(String conditionName) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (_) => _HealthWarningDialog(conditionName: conditionName),
  );
}

class _HealthWarningDialog extends StatefulWidget {
  final String conditionName;
  const _HealthWarningDialog({required this.conditionName});

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
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
