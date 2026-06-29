import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/alert_request.dart';
import 'package:guardian_drive_mobile/models/alert_summary.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/alert_service.dart';
import 'package:guardian_drive_mobile/services/car_ble_service.dart';
import 'package:guardian_drive_mobile/services/location_service.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/first_aid_guidance_popup.dart';

Future<void> showConfirmSOSDialog(
  BuildContext context,
  VitalReadings? latestReading,
) async {
  await showDialog(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF0D1B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text(
          "Request Help ?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () =>
              Navigator.of(dialogContext, rootNavigator: true).pop(),
          child: Text(
            'NO',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade200,
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () async {
            Navigator.of(dialogContext, rootNavigator: true).pop();

            bool loadingShowing = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              useRootNavigator: true,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF0D1B2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Sending SOS Alert...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ).then((_) => loadingShowing = false);

            void closeLoading() {
              if (loadingShowing && context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                loadingShowing = false;
              }
            }

            try {
              final success = await triggerSOS(context, latestReading);
              traceLog("success", success);
              closeLoading();

              if (success == false || success == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Triggering SOS Failed'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await TripService().endTripTracking();
              await CarBleService.instance.sendSevereCaseOccurred();
              if (!context.mounted) return;
              traceLog('Show First Aid Guidance before dialog');
              await showFirstAidGuidanceDialog(latestReading, context);
              traceLog('Show First Aid Guidance after dialog');
            } catch (e) {
              traceLog("error in sending SOS : ", e);
              closeLoading();
              if (context.mounted) {
                showDialog(
                  context: context,
                  useRootNavigator: true,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      "Failed to send SOS",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(ctx, rootNavigator: true).pop(),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
          },
          child: Text(
            'YES',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade200,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool?> triggerSOS(
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
    type: alertType.SOS,
    tripId: TripService().activeTripId!,
    triggeredLocationId: triggeredLocationId,
    heartRate: latestReading.heartRate,
    spo2: latestReading.spo2,
    temp: latestReading.temp,
  );
  traceLog(
    'in trigger SOS, sending SOS Alert request ',
    alertRequest.toString(),
  );

  final success = await AlertApiService.triggerSOSAlert(alertRequest);
  return success;
}
