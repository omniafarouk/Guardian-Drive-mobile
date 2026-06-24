// models/condition_breach.dart
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart'; // where ConditionType/ConditionSeverity live

/// A single out-of-range reading, classified by type and severity.
class ConditionBreach {
  final ConditionType type;
  final ConditionSeverity severity;
  final double value;
  final double baselineBreached;

  ConditionBreach({
    required this.type,
    required this.severity,
    required this.value,
    required this.baselineBreached,
  });

  @override
  String toString() =>
      '${type.name} (${severity.name}): value=$value, limit=$baselineBreached';
  //String toString() => '${type.name} (${severity.name}): value=$value';
}
