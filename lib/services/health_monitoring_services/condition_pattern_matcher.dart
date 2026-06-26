// services/condition_pattern_matcher.dart
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/condition_patterns_data.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/condition_trigger_coordinator.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/driver_baseline_with_noise_model.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/vitals_matcher_models.dart';

class PatternMatch {
  final String conditionName;
  final AlertTier tier;
  final double minRatio; // weakest-link ratio across all relevant vitals
  PatternMatch({
    required this.conditionName,
    required this.tier,
    required this.minRatio,
  });
}

final warningNotificationAlertRatio = 0.9;

class ConditionPatternMatcher {
  final List<ConditionPattern> patterns = HealthPatterns;
  final DriverBaselineWithNoise baseline;

  ConditionPatternMatcher({required this.baseline});

  /// Checks the current reading against every known pattern, returns
  /// every pattern that reaches at least MILD, sorted strongest first.
  List<PatternMatch> matchAll(VitalReadings reading) {
    final matches = <PatternMatch>[];

    for (final pattern in patterns) {
      double minRatio = double.infinity;

      for (final trigger in pattern.triggers) {
        final actual = _valueFor(trigger.kind, reading);
        final base = _baselineFor(trigger.kind);
        final ratio = _deviationRatio(
          actual: actual,
          baseline: base,
          thresholdDeviation: trigger.thresholdDeviation,
          isDecrease: trigger.isDecrease,
        );
        if (ratio < minRatio) minRatio = ratio;
      }

      if (minRatio >= 1.0) {
        matches.add(
          PatternMatch(
            conditionName: pattern.name,
            tier: AlertTier.alertTrigger,
            minRatio: minRatio,
          ),
        );
      } else if (minRatio >= warningNotificationAlertRatio) {
        matches.add(
          PatternMatch(
            conditionName: pattern.name,
            tier: AlertTier.warning,
            minRatio: minRatio,
          ),
        );
      }
    }

    matches.sort(
      (a, b) => b.minRatio.compareTo(a.minRatio),
    ); // strongest match first
    return matches;
  }

  double _deviationRatio({
    required double actual,
    required double baseline,
    required double thresholdDeviation,
    required bool isDecrease,
  }) {
    final deviation = isDecrease ? (baseline - actual) : (actual - baseline);
    if (thresholdDeviation == 0) return 0;
    return deviation / thresholdDeviation;
  }

  double _valueFor(VitalKind kind, VitalReadings reading) {
    switch (kind) {
      case VitalKind.heartRate:
        return reading.heartRate;
      case VitalKind.spo2:
        return reading.spo2;
      case VitalKind.temp:
        return reading.temp;
    }
  }

  double _baselineFor(VitalKind kind) {
    switch (kind) {
      case VitalKind.heartRate:
        return baseline.hr;
      case VitalKind.spo2:
        return baseline.spo2;
      case VitalKind.temp:
        return baseline.temp;
    }
  }
}
