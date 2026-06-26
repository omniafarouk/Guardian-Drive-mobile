import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';
import 'package:guardian_drive_mobile/services/first_aid_guidance_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

Future<void> showFirstAidGuidanceDialog(
  VitalReadings? reading,
  BuildContext context,
) async {
  // fetch
  final guidance = await getGuidanceString(reading);

  if (!context.mounted) return;

  // show result dialog
  showDialog(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext context) => AlertDialog(
      backgroundColor: const Color(0xFF0D1B2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text(
          'Help is on the way!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please follow these instructions for your safety:',
            style: TextStyle(fontSize: 14, color: Colors.white70),
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
              guidance,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3A5C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'OK',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<String> getGuidanceString(VitalReadings? readings) async {
  if (readings == null) {
    return 'Rest and do not overexert yourself. Pull over if you feel unwell.';
  }

  try {
    final List<FirstAidGuidance> guidances = await FirstAidGuidanceService()
        .getGuidanceByVitals(readings);

    traceLog('guidance returned', guidances);

    if (guidances.isEmpty) {
      return 'No specific guidance available. Pull over and rest.';
    }

    const severityOrder = {
      ConditionSeverity.CRITICAL: 0,
      ConditionSeverity.MODERATE: 1,
      ConditionSeverity.MILD: 2,
      ConditionSeverity.NORMAL: 3,
    };

    guidances.sort((a, b) {
      final aRank = severityOrder[a.severity] ?? 99;
      final bRank = severityOrder[b.severity] ?? 99;
      return aRank.compareTo(bRank);
    });

    return guidances.first.severityAction;
  } catch (e) {
    traceLog('guidance error', e);
    return 'Unable to load guidance. Pull over safely and call emergency services.';
  }
}
// Future<String> getGuidanceString(VitalReadings? readings) async {
//   if (readings != null) {
//     List<FirstAidGuidance> guidances = await FirstAidGuidanceService()
//         .getGuidanceByVitals(readings);

//     traceLog("guidance returned", guidances);
//     return guidances[0].severityAction;
//   }
//   return "Rest And Don't Overexert yourself. Pull Over in Case You Feel UnWell.";
// }
