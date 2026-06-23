// data/condition_patterns.dart
import 'package:guardian_drive_mobile/services/health_monitoring_services/vitals_matcher_models.dart';

const fatiguePattern = ConditionPattern(
  name: 'Fatigue',
  triggers: [
    VitalTrigger(
      kind: VitalKind.heartRate,
      thresholdDeviation: 5,
      isDecrease: true,
    ), // baseline -5
    VitalTrigger(
      kind: VitalKind.spo2,
      thresholdDeviation: 3,
      isDecrease: true,
    ), // 98 -> 95 entry
    VitalTrigger(
      kind: VitalKind.temp,
      thresholdDeviation: 0.4,
      isDecrease: true,
    ), // baseline -0.4
  ],
);

const alcoholPattern = ConditionPattern(
  name: 'Alcohol',
  triggers: [
    VitalTrigger(
      kind: VitalKind.heartRate,
      thresholdDeviation: 10,
      isDecrease: true,
    ), // baseline -10
    VitalTrigger(
      kind: VitalKind.spo2,
      thresholdDeviation: 6,
      isDecrease: true,
    ), // 98 -> 92 entry
    VitalTrigger(
      kind: VitalKind.temp,
      thresholdDeviation: 1.0,
      isDecrease: true,
    ), // baseline -1.0
  ],
);

const heartFailurePattern = ConditionPattern(
  name: 'Heart failure',
  triggers: [
    VitalTrigger(
      kind: VitalKind.heartRate,
      thresholdDeviation: 10,
      isDecrease: false,
    ), // baseline +10
    VitalTrigger(
      kind: VitalKind.spo2,
      thresholdDeviation: 5,
      isDecrease: true,
    ), // 98 -> 93 entry
    // Temp intentionally excluded — table says "not diagnostic, ignore"
  ],
);

const drowsinessPattern = ConditionPattern(
  name: 'Drowsiness',
  triggers: [
    VitalTrigger(
      kind: VitalKind.heartRate,
      thresholdDeviation: 10,
      isDecrease: true,
    ), // -5 to -15 approximate
    VitalTrigger(
      kind: VitalKind.spo2,
      thresholdDeviation: 4,
      isDecrease: true,
    ), // < 94 %
    VitalTrigger(kind: VitalKind.temp, thresholdDeviation: 1, isDecrease: true),
  ], // -1 to -2
);

const panicAttackPattern = ConditionPattern(
  name: 'panic',
  triggers: [
    VitalTrigger(
      kind: VitalKind.heartRate,
      thresholdDeviation: 40,
      isDecrease: false,
    ), // > 120 bpm approximate
    VitalTrigger(
      kind: VitalKind.spo2,
      thresholdDeviation: 2,
      isDecrease: true,
    ), // it should fall but not much
    // the temp is oscillating ---> would be checked in condition_coordinator
  ],
);

const List<ConditionPattern> HealthPatterns = [
  fatiguePattern,
  alcoholPattern,
  heartFailurePattern,
  drowsinessPattern,
  panicAttackPattern,
];
