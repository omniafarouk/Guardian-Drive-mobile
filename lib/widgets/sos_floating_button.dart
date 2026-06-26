import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/sos_dialog_popup.dart';

class SosFloatingButton extends StatelessWidget {
  const SosFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TripService.instance.tripIsActiveNotifier,
      builder: (context, tripIsActive, child) {
        return tripIsActive
            ? FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () {
                  traceLog('SOS TRIGGERED');
                  showConfirmSOSDialog(context);
                },
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const SizedBox.shrink(); // renders nothing when no trip
      },
    );
  }
}
