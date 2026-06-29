import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/sos_dialog_popup.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';

class SosFloatingButtonWidget extends StatelessWidget {
  final VitalReadings? latestReading;

  const SosFloatingButtonWidget({super.key, this.latestReading});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TripService.instance.tripIsActiveNotifier,
      builder: (context, tripIsActive, child) {
        return tripIsActive
            ? FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () async {
                  traceLog('SOS TRIGGERED');
                  await showConfirmSOSDialog(context, latestReading);
                },
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}
