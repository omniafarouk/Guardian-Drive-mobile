import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

void showHealthAlertDialog(String conditionName) {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  final appIsVisible = ModalRoute.of(context)?.isCurrent == true;

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _HealthAlertDialog(conditionName: conditionName),
  ).then((stopTrip) {
    if (stopTrip == true) {
      // TripService().endTrip(null);
      traceLog('STOP TRIP AND CALL EMERGENCY!!');
    }
  });
}

class _HealthAlertDialog extends StatefulWidget {
  final String conditionName;
  const _HealthAlertDialog({required this.conditionName});

  @override
  State<_HealthAlertDialog> createState() => _HealthAlertDialogState();
}

class _HealthAlertDialogState extends State<_HealthAlertDialog> {
  late Timer _soundTimer; // repeats the sound
  late Timer _countdownTimer; // counts down to auto-stop
  int _secondsLeft = 30; // timeout duration

  @override
  void initState() {
    super.initState();

    // 1. Start repeating sound
    _soundTimer = Timer.periodic(Duration(seconds: 2), (_) {
      _playAlertSound();
    });
    _playAlertSound(); // play immediately, don't wait first 2 seconds

    // 2. Start countdown
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_secondsLeft < 1) {
        _dismiss(stopTrip: true); // timeout → auto stop trip
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _playAlertSound() {
    // TODO: AudioPlayer().play(AssetSource('alert.mp3'));
  }

  void _dismiss({required bool stopTrip}) {
    _soundTimer.cancel();
    _countdownTimer.cancel();
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
      title: Text('⚠️ Health Alert'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.conditionName} detected.'),
          SizedBox(height: 12),
          Text(
            'Trip will stop in $_secondsLeft seconds...',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _dismiss(stopTrip: false),
          child: Text('Continue'),
        ),
        ElevatedButton(
          onPressed: () => _dismiss(stopTrip: true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Stop Trip'),
        ),
      ],
    );
  }
}
