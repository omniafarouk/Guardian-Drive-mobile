// models/vital_trigger.dart
enum VitalKind { heartRate, spo2, temp }

/// One vital's trigger band for a named condition, expressed as a
/// deviation from baseline. [thresholdDeviation] is the band's entry
/// point — the value CLOSEST to baseline (e.g. 5 for "-5 to -10").
class VitalTrigger {
  final VitalKind kind;
  final double
  thresholdDeviation; // the set deviation to detect critical/severe
  final bool isDecrease; // true = "bad" direction is BELOW baseline

  const VitalTrigger({
    required this.kind,
    required this.thresholdDeviation,
    required this.isDecrease,
  });
}

// models/condition_pattern.dart
class ConditionPattern {
  final String name;
  final List<VitalTrigger>
  triggers; // only the vitals relevant to this condition

  const ConditionPattern({required this.name, required this.triggers});
}
